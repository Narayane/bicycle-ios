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

import Foundation
import RxCocoa
import RxSwift

class BICStationService {
    
    private var cacheStations: Dictionary<String, [BICStation]>
    
    static let shared: BICStationService = {
        let instance = BICStationService()
        return instance
    }()
    
    init() {
        cacheStations = Dictionary()
    }
    
    // MARK: - Public Methods
    
    func refreshStationsFor(contract: BICContract) -> Single<[BICStation]> {
        return WSFacade.getStationsBy(contract: contract)
            .do(onSuccess: { (stations) in
                self.cacheStations[contract.name] = stations
            }, onError: { (error) in
                log.e("fail to get contract stations: \(error.localizedDescription)")
            })
    }
    
    func loadStationsFor(contract: BICContract, success: @escaping (_ stations: [BICStation]) -> Void, error: @escaping () -> Void) {
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
    }
    
    func getCloseStations() {
        
    }
}
