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

class BICContractService {
    
    lazy var allContracts: [BICContract] = loadContracts(from: "Contracts")
    private var cacheStations: Dictionary<String, [BICStation]> = Dictionary()
    
    // MARK: - Public Methods
    
    func getStationsFor(contract: BICContract) -> Single<[BICStation]> {
        if let stations = cacheStations[contract.name] {
            log.d("get \(stations.count) stations for contract: \(contract.name)")
            return Observable.from(optional: stations).asSingle()
        } else {
            return refreshStationsFor(contract: contract)
        }
    }
    
    func refreshStationsFor(contract: BICContract) -> Single<[BICStation]> {
        return WSFacade.getStationsBy(contract: contract)
            .do(onSuccess: { (stations) in
                log.d("refresh \(stations.count) stations for contract: \(contract.name)")
                self.cacheStations[contract.name] = stations
            }, onError: { (error) in
                log.e("fail to get contract stations: \(error.localizedDescription)")
            })
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
    
    private func loadContracts(from: String) -> [BICContract] {
        var contracts: [BICContract] = []
        if let jsonFilePath = Bundle.main.path(forResource: from, ofType: "json") {
            log.v("load contracts from file at \(jsonFilePath)")
            do {
                let jsonFileContent = try String(contentsOf: URL(fileURLWithPath: jsonFilePath), encoding: String.Encoding.utf8)
                do {
                    if let array = try JSONSerialization.jsonObject(with: jsonFileContent.data(using: String.Encoding.utf8)!, options: []) as? [[String : Any]] {
                        for element in array {
                            if let contract = BICContract(JSON: element) {
                                contracts.append(contract)
                            }
                        }
                        log.d("\(contracts.count) contracts loaded")
                    }
                } catch {
                    log.e(error.localizedDescription)
                }
            } catch {
                log.e(error.localizedDescription)
            }
        }
        return contracts
    }
}
