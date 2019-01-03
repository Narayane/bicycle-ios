//
//  Copyright © 2018 Bicycle (Sébastien BALARD)
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
import CoreData
import MapKit

public class BICContract: NSManagedObject {
    
    static func ==(lhs: BICContract, rhs: BICContract) -> Bool {
        return lhs.center == rhs.center
    }
    
    convenience init(dto: BICContractDto, in context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "BICContract", in: context)!
        self.init(entity: entity, insertInto: context)
        
        self.name = dto.name
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.radius = Int64(dto.radius)
        self.url = dto.url
        self.stationCount = Int64(dto.stationCount)
        self.countryCode = dto.countryCode
    }
    
    var center: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
    }
    
    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegion(center: center, latitudinalMeters: Double(radius * 2), longitudinalMeters: Double(radius * 2))
        }
    }
    
    var countryName: String? {
        get {
            let locale = (Locale.current as NSLocale)
            return locale.displayName(forKey: .countryCode, value: countryCode!)
        }
    }
}
