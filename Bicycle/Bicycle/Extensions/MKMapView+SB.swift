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
            // calculating Longitude span corresponding to normal (non-rotated) width
            let spanStraight = width * region.span.longitudeDelta / (width * cos(rotationAngleRad) + (height - statusBarHeightOffset) * sin(rotationAngleRad))
            return Int(log2(360 * ((width / 128) / spanStraight)))
        }
    }
}
