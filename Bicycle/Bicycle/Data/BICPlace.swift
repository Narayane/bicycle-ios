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

class BICPlace {
    
    var name: String?
    var latitude: Double?
    var longitude: Double?
    var contract: BICContract?
    
    var coordinate: CLLocationCoordinate2D? {
        get {
            if let latitude = latitude, let longitude = longitude {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            return nil
        }
    }
    
    init(from placemark: CLPlacemark) {
        var text = placemark.name
        text = text?.concat(with: placemark.postalCode, separator: ", ")
        text = text?.concat(with: placemark.locality, separator: " ")
        text = text?.concat(with: placemark.country, separator: ", ")
        SBLog.d("create place: \(String(describing: text))")
        name = text
        latitude = placemark.location?.coordinate.latitude
        longitude = placemark.location?.coordinate.longitude
    }
}
