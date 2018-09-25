//
//  Copyright © 2017 Bicycle (Sébastien BALARD)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreLocation
import RxCocoa
import RxSwift

class BICContractRepository {
    
    private let disposeBag: DisposeBag
    private let appDelegate: AppDelegate
    private let bicycleDataSource: BicycleDataSource
    private let localDataSource: BICLocalDataSource
    private let preferenceRepository: BICPreferenceRepository
    
    lazy var allContracts = [BICContract]()
    private var cacheStations: Dictionary<String, [BICStation]> = Dictionary()
    
    init(appDelegate: AppDelegate, bicycleDataSource: BicycleDataSource, localDataSource: BICLocalDataSource, preferenceRepository: BICPreferenceRepository) {
        disposeBag = DisposeBag()
        self.appDelegate = appDelegate
        self.bicycleDataSource = bicycleDataSource
        self.localDataSource = localDataSource
        self.preferenceRepository = preferenceRepository
    }
    
    // MARK: - Public Methods
    
    func updateContracts() -> Single<Int> {
        return Single.create { observer in
            if (self.appDelegate.hasConnectivity) {
                self.bicycleDataSource.getContracts()
                    .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .do(onSuccess: { (response) in
                        if let contractDataVersion = response.version, contractDataVersion > self.preferenceRepository.contractsVersion {
                            let deletedCount = self.localDataSource.deleteAllContracts()
                            log.d("\(deletedCount) contracts deleted")
                        }
                    })
                    .map({ (response) -> Int in
                        if let contractDataVersion = response.version, let dtos = response.values, contractDataVersion > self.preferenceRepository.contractsVersion {
                            let insertedCount = self.localDataSource.insertAllContracts(dtos: dtos)
                            log.d("\(insertedCount) contracts inserted")
                            self.preferenceRepository.contractsVersion = contractDataVersion
                        } else {
                            log.d("contracts are up-to-date")
                        }
                        let contracts = self.localDataSource.findAllContracts()
                        log.d("\(contracts.count) contracts loaded")
                        self.allContracts.append(contentsOf: contracts)
                        return self.allContracts.count
                    })
                    .subscribe(onSuccess: { (count) in
                        self.preferenceRepository.contractsLastCheckDate = Date()
                        observer(.success(count))
                    }, onError: { (error) in
                        observer(.error(error))
                    }).disposed(by: self.disposeBag)
            } else {
                log.d("get contracts from assets")
                var contracts: [BICContractDto] = []
                if let jsonFilePath = Bundle.main.path(forResource: "Contracts", ofType: "json") {
                    log.v("load contracts from file at \(jsonFilePath)")
                    do {
                        let jsonFileContent = try String(contentsOf: URL(fileURLWithPath: jsonFilePath), encoding: String.Encoding.utf8)
                        do {
                            if let object = try JSONSerialization.jsonObject(with: jsonFileContent.data(using: String.Encoding.utf8)!, options: []) as? [String : Any] {
                                for element in object["values"] as! [[String : Any]] {
                                    if let contract = BICContractDto(JSON: element) {
                                        contracts.append(contract)
                                    }
                                }
                                log.d("\(contracts.count) contracts loaded")
                                observer(.success(contracts.count))
                            }
                        } catch {
                            observer(.error(error))
                        }
                    } catch {
                        observer(.error(error))
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    func getContractCount() -> Single<Int> {
        let contracts: [BICContract] = self.localDataSource.findAllContracts()
        log.d("\(contracts.count) contracts loaded")
        allContracts.append(contentsOf: contracts)
        return Single.just(contracts.count)
    }
    
    func getStationsFor(contract: BICContract) -> Single<[BICStation]> {
        if let contractName = contract.name, let stations = cacheStations[contractName] {
            log.d("get \(stations.count) stations for contract: \(contractName)")
            return Observable.from(optional: stations).asSingle()
        } else {
            return refreshStationsFor(contract: contract)
        }
    }
    
    func refreshStationsFor(contract: BICContract) -> Single<[BICStation]> {
        return Single.just([]) // FIXME: implement
        /*return WSFacade.getStationsBy(contract: contract)
            .do(onSuccess: { (stations) in
                log.d("refresh \(stations.count) stations for contract: \(contract.name)")
                self.cacheStations[contract.name] = stations
            }, onError: { (error) in
                log.e("fail to get contract stations: \(error.localizedDescription)")
            })*/
    }
    
    /*func loadStationsFor(contract: BICContract, success: @escaping (_ stations: [BICStation]) -> Void, error: @escaping () -> Void) {
        if cacheStations.keys.contains(where: { $0 == contract.name } ) {
            let stations = cacheStations[contract.name]!
            log.d("find \(stations.count) stations for contract: \(contract.name)")
            success(stations)
        } else {
            WSFacade.getStationsBy(contract: contract, success: { (stations) in
                self.cacheStations.updateValue(stations, forKey: contract.name)
                log.d("load \(stations.count) stations for contract: \(contract.name)")
                success(stations)
            }) {
                error()
            }
        }
    }*/
    
    func getContract(for coordinate: CLLocationCoordinate2D) -> BICContract? {
        
        log.v("(\(coordinate.latitude),\(coordinate.longitude))")
        let filteredList = allContracts.filter { (contract) -> Bool in
            return coordinate.isIncludedIn(region: contract.region)
        }
        
        var contract: BICContract?
        if filteredList.count > 1 {
            var minDistance: CLLocationDistance?
            var distanceFromCenter: CLLocationDistance?
            for filtered in filteredList {
                distanceFromCenter = coordinate.distanceTo(filtered.center)
                //FIXME: is it useful?
                if minDistance == nil {
                    minDistance = distanceFromCenter
                    contract = filtered
                } else if let distance = minDistance, distance > distanceFromCenter! {
                    minDistance = distanceFromCenter
                    contract = filtered
                }
            }
        } else {
            contract = filteredList.first
        }
        return contract
    }
}
