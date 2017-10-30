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

class WSFacade {
    
    static func getStationsBy(contract: BICContract, success: @escaping (_ stations: [BICStation]) -> Void, error: @escaping () -> Void) {
        if contract.provider?.tag == BICContract.Provider.CityBikes.tag {
            CityBikesRestClient.shared.getStationsBy(url: contract.url!, handleSuccessWith: { (dtos) in
                success(dtos.map({ (dto) -> BICStation in
                    return BICStation(citybikes: dto)
                }))
            }, handleFailureWith: error)
        }
    }
}
