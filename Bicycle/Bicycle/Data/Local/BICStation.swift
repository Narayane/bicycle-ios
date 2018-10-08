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

class BICStation {
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var freeCount: Int?
    var bikesCount: Int?
    
    var coordinate: CLLocationCoordinate2D? {
        get {
            if let latitude = latitude, let longitude = longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return nil
        }
    }
    
    var displayName: String {
        get {
            guard let name = name else { return "-" }
            return filter(name)
        }
    }
    
    private func filter(_ value: String) -> String {
        let regex = try! NSRegularExpression(pattern: "[\\d\\s]*([a-zA-Z](.*)$)", options: [])
        let matches = regex.matches(in: value, options: [], range: NSRange(location: 0, length: value.utf16.count)) as [NSTextCheckingResult]
        return (value as NSString).substring(with: matches[0].range(at: 1))
    }
    
    /*init(jcdecaux dto: JCDStationDto) {
        name = dto.name
        latitude = dto.latitude
        longitude = dto.longitude
        freeCount = dto.availableBikeStandsCount
        bikesCount = dto.availableBikesCount
    }*/
    
    init(citybikes dto: CTBStationDto) {
        name = dto.name
        if let lat = dto.latitude {
            latitude = lat
        }
        if let lng = dto.longitude {
            longitude = lng
        }
        freeCount = dto.freeCount
        bikesCount = dto.bikesCount
    }
}
