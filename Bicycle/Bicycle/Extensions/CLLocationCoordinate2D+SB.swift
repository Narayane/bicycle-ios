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
import MapKit

extension CLLocationCoordinate2D {
    
    func isIncludedIn(region: MKCoordinateRegion) -> Bool {
        
        var included = false
        
        //OLSLog.v("NW(\(region.northWest.latitude),\(region.northWest.longitude)), SE(\(region.southEast.latitude),\(region.southEast.longitude))")
        
        included = latitude <= region.northWest.latitude && latitude >= region.southEast.latitude
            && longitude >= region.northWest.longitude && longitude <= region.southEast.longitude
        
        return included
    }
    
    func distanceTo(_ to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func equals(to coordinate: CLLocationCoordinate2D?) -> Bool {
        if let coordinate = coordinate {
            return (fabs(self.latitude - coordinate.latitude) < .ulpOfOne) && (fabs(self.longitude - coordinate.longitude) < .ulpOfOne)
        }
        return false
    }
}
