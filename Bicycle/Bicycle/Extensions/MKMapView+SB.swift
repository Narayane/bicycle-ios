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

let MERCATOR_OFFSET = 268435456.0
let MERCATOR_RADIUS = 85445659.44705395
let DEGREES = 180.0

extension MKMapView {
    
    var zoomLevel: Int {
        get {
            
            var rotationAngle = camera.heading
            if rotationAngle > 270 {
                rotationAngle = 360 - rotationAngle
            } else if rotationAngle > 90 {
                rotationAngle = fabs(rotationAngle - 180)
            }
            
            // rotation angle in radians
            let rotationAngleRad = .pi * rotationAngle / 180
            let width = Double(frame.size.width)
            let height = Double(frame.size.height)
            
            // the offset (status bar height) which is taken by MapKit into consideration to calculate visible area height
            let statusBarHeightOffset : Double = 20
            
            // calculating longitude span corresponding to normal (non-rotated) width
            let spanStraight = width * region.span.longitudeDelta / (width * cos(rotationAngleRad) + (height - statusBarHeightOffset) * sin(rotationAngleRad))
            
            return Int(log2(360 * ((width / 128) / spanStraight)))
        }
    }
    
    func getRegion(center: CLLocationCoordinate2D, zoomLevel: Double)  -> MKCoordinateRegion? {
        let span = createCoordinateSpan(center: center, zoomLevel: zoomLevel)
        let region = MKCoordinateRegion(center: center, span: span)
        guard region.center.longitude > -180.00000000 else { return nil }
        return region
    }
    
    private func createCoordinateSpan(center: CLLocationCoordinate2D, zoomLevel: Double) -> MKCoordinateSpan {
        
        // convert center coordiate to pixel space
        let centerPixelX = longitudeToPixelSpaceX(longitude: center.longitude)
        let centerPixelY = latitudeToPixelSpaceY(latitude: center.latitude)
        
        // determine the scale value from the zoom level
        let zoomExponent: Double = 20.0 - zoomLevel
        let zoomScale: Double = pow(2.0, zoomExponent)
        
        // scale the map’s size in pixel space
        let mapSizeInPixels = bounds.size
        let scaledMapWidth = Double(mapSizeInPixels.width) * zoomScale
        let scaledMapHeight = Double(mapSizeInPixels.height) * zoomScale
        
        // figure out the position of the top-left pixel
        let topLeftPixelX = centerPixelX - (scaledMapWidth / 2.0)
        let topLeftPixelY = centerPixelY - (scaledMapHeight / 2.0)
        
        // find delta between left and right longitudes
        let minLng = pixelSpaceXToLongitude(pixelX: topLeftPixelX)
        let maxLng = pixelSpaceXToLongitude(pixelX: topLeftPixelX + scaledMapWidth)
        let longitudeDelta = maxLng - minLng
        
        let minLat = pixelSpaceYToLatitude(pixelY: topLeftPixelY)
        let maxLat = pixelSpaceYToLatitude(pixelY: topLeftPixelY + scaledMapHeight)
        let latitudeDelta = -1.0 * (maxLat - minLat)
        
        return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
    
    private func longitudeToPixelSpaceX(longitude: Double) -> Double {
        return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * .pi / DEGREES)
    }
    
    private func latitudeToPixelSpaceY(latitude: Double) -> Double {
        let d = (1 + sin(latitude * .pi / DEGREES)) / (1 - sin(latitude * .pi / DEGREES))
        return round(MERCATOR_OFFSET - MERCATOR_RADIUS * UIKit.log(d) / 2.0)
    }
    
    private func pixelSpaceXToLongitude(pixelX: Double) -> Double {
        return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * DEGREES / .pi
    }
    
    private func pixelSpaceYToLatitude(pixelY: Double) -> Double {
        return (.pi / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * DEGREES / .pi
    }
}
