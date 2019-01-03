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

import MapKit

extension MKCoordinateRegion {
    
    var northWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2,
                                      longitude: center.longitude - span.longitudeDelta / 2)
    }
    
    var northEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude + span.latitudeDelta / 2,
                                      longitude: center.longitude + span.longitudeDelta / 2)
    }
    
    var southWest: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2,
                                      longitude: center.longitude - span.longitudeDelta / 2)
    }
    
    var southEast: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: center.latitude - span.latitudeDelta / 2,
                                      longitude: center.longitude + span.longitudeDelta / 2)
    }
    
    func contains(location: CLLocationCoordinate2D) -> Bool {
        return (southWest.latitude <= location.latitude) && (location.latitude <= northEast.latitude)
            && (southWest.longitude <= location.longitude) && (location.longitude <= northEast.longitude)
    }
    
    func intersect(_ region: MKCoordinateRegion) -> Bool {
        
        /*let latNERegion = region.northEast.latitude
        let latSW = southWest.latitude
        let latSWRegion = region.southWest.latitude
        let latNE = northEast.latitude
        let longNERegion = region.northEast.longitude
        let longSW = southWest.longitude
        let longSWRegion = region.southWest.longitude
        let longNE = northEast.longitude*/
        
        let latIntersects = (region.northEast.latitude >= southWest.latitude) && (region.southWest.latitude <= northEast.latitude)
        let lngIntersects = (region.northEast.longitude >= southWest.longitude) && (region.southWest.longitude <= northEast.longitude)
        
        return latIntersects && lngIntersects
    }
}
