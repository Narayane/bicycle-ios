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
    
    func loadStationsFor(contract: BICContract, success: @escaping (_ stations: [BICStation]) -> Void, error: @escaping () -> Void) {
        if cacheStations.keys.contains(where: { $0 == contract.name! } ) {
            let stations = cacheStations[contract.name!]!
            SBLog.d("find \(stations.count) stations for contract: \(contract.name!)")
            success(stations)
        } else {
            WSFacade.getStationsBy(contract: contract, success: { (stations) in
                self.cacheStations.updateValue(stations, forKey: contract.name!)
                SBLog.d("load \(stations.count) stations for contract: \(contract.name!)")
                success(stations)
            }) {
                error()
            }
        }
    }
    
    func getCloseStations() {
        
    }
}
