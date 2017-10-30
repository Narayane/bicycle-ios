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

class BICContractService {
    
    var allContracts: [BICContract]
    
    static let shared: BICContractService = {
        let instance = BICContractService()
        return instance
    }()
    
    init() {
        allContracts = []
    }
    
    // MARK: - Public Methods
    
    func getContract(for coordinate: CLLocationCoordinate2D) -> BICContract? {
        
        SBLog.v("(\(coordinate.latitude),\(coordinate.longitude))")
        let filteredList = allContracts.filter { (contract) -> Bool in
            return coordinate.isIncludedIn(region: contract.region!)
        }
        
        var contract: BICContract?
        if filteredList.count > 1 {
            var minDistance: CLLocationDistance?
            var distanceFromCenter: CLLocationDistance?
            for filtered in filteredList {
                distanceFromCenter = coordinate.distanceTo(filtered.center!)
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
    
    func loadContracts(from: String) {
        if let jsonFilePath = Bundle.main.path(forResource: from, ofType: "json") {
            SBLog.v("load contracts from file at \(jsonFilePath)")
            do {
                let jsonFileContent = try String(contentsOf: URL(fileURLWithPath: jsonFilePath), encoding: String.Encoding.utf8)
                do {
                    if let array = try JSONSerialization.jsonObject(with: jsonFileContent.data(using: String.Encoding.utf8)!, options: []) as? [[String : Any]] {
                        for element in array {
                            if let contract = BICContract(JSON: element) {
                                allContracts.append(contract)
                            }
                        }
                        SBLog.d("\(allContracts.count) contracts loaded")
                    }
                } catch {
                    SBLog.e(error.localizedDescription)
                }
            } catch {
                SBLog.e(error.localizedDescription)
            }
        }
    }
}
