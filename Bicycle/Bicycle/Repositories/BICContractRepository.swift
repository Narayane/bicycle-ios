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
    private let cityBikesDataSource: CityBikesDataSource
    private let localDataSource: BICLocalDataSource
    private let preferenceRepository: BICPreferenceRepository
    
    private var cacheStations: Dictionary<String, [BICStation]> = Dictionary()
    
    init(appDelegate: AppDelegate, bicycleDataSource: BicycleDataSource, cityBikesDataSource: CityBikesDataSource, localDataSource: BICLocalDataSource, preferenceRepository: BICPreferenceRepository) {
        disposeBag = DisposeBag()
        self.appDelegate = appDelegate
        self.bicycleDataSource = bicycleDataSource
        self.cityBikesDataSource = cityBikesDataSource
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
                        return contracts.count
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
        return Single.just(contracts.count)
    }
    
    func loadAllContracts() -> Single<[BICContract]> {
        log.d("get contracts from local")
        let contracts: [BICContract] = self.localDataSource.findAllContracts()
        return Single.just(contracts)
    }
    
    func loadStationsBy(contract: BICContract) -> Single<[BICStation]> {
        guard let name = contract.name else {
            return Single.error(NSError(domain: "", code: 10000, userInfo: nil))
        }
        if cacheStations.keys.contains(where: { $0 == name } ) {
            return Observable.from(optional: cacheStations[name])
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .asSingle()
        } else {
            return reloadStationsBy(contract: contract)
        }
    }
    
    func reloadStationsBy(contract: BICContract) -> Single<[BICStation]> {
        guard let name = contract.name, let url = contract.url else {
            return Single.error(NSError(domain: "", code: 10000, userInfo: nil))
        }
        return cityBikesDataSource.getStationsBy(url: url).do(onSuccess: { (stations) in
            self.cacheStations[name] = stations
        }, onError: { (error) in
            //log.e("fail to reload contract stations", crashReport.catchException(throwable))
        })
    }
    
    func getContract(for coordinate: CLLocationCoordinate2D) -> BICContract? {
        
        log.v("(\(coordinate.latitude), \(coordinate.longitude))")
        let filteredList = self.localDataSource.findAllContracts().filter { (contract) -> Bool in
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
