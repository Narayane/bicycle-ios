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

import ObjectMapper

class CTBStationDto: Mappable {
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var freeCount: Int?
    var bikesCount: Int?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
        freeCount <- map["empty_slots"]
        bikesCount <- map["free_bikes"]
    }
}
