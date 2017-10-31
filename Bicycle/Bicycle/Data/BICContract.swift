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

class BICContract: Mappable {
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var provider: Provider?
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
        provider <- (map["provider"], BICContractProviderSerializer())
        radius <- map["radius"]
        url <- map["url"]
    }
    
    public struct Provider {
        
        static let Unknown = Provider(0, tag: "Unknown")
        //static let JCDecaux = Provider(1, tag: "JCDecaux")
        static let CityBikes = Provider(1, tag: "CityBikes")
        
        public let value: Int
        public let tag: String
        
        init(_ value: Int, tag: String) {
            self.value = value
            self.tag = tag
        }
        
        static func from(tag: String) -> Provider {
            switch (tag) {
            /*case JCDecaux.tag:
                return JCDecaux*/
            case CityBikes.tag:
                return CityBikes
            default:
                return Unknown
            }
        }
    }
}
