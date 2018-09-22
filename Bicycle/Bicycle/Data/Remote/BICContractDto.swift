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
import ObjectMapper
import MapKit

class BICContractDto: Mappable, Equatable {
    
    static func ==(lhs: BICContractDto, rhs: BICContractDto) -> Bool {
        return lhs.center == rhs.center
    }
    
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var url: String
    var stationCount: Int
    var countryCode: String
    
    var center: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegionMakeWithDistance(center, radius * 2, radius * 2)
        }
    }
    
    required init?(map: Map) {
        name = ""
        latitude = 0
        longitude = 0
        radius = 0
        url = ""
        stationCount = 0
        countryCode = ""
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
        radius <- map["radius"]
        url <- map["url"]
        stationCount <- map["station_count"]
        countryCode <- map["country"]
    }
}
