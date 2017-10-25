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

class OBKContract: Mappable {
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    var url: String?
    
    var center: CLLocationCoordinate2D? {
        get {
            if let latitude = latitude, let longitude = longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return nil
        }
    }
    
    var region: MKCoordinateRegion? {
        get {
            if let center = center, let radius = radius {
                return MKCoordinateRegionMakeWithDistance(center, radius * 2, radius * 2)
            }
            return nil
        }
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        name <- map["name"]
        latitude <- map["lat"]
        longitude <- map["lng"]
        radius <- map["radius"]
        url <- map["url"]
    }
}
