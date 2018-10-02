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
import CoreLocation
import RxCocoa
import RxSwift
import RxCoreLocation

class BICMapViewModel: SBViewModel {
    
    var isLocationAuthorizationDenied: Variable<Bool> = Variable<Bool>(true)
    var userLocation: Variable<CLLocation?> = Variable<CLLocation?>(nil)
    
    private let locationManager: CLLocationManager
    
    init(locationManager: CLLocationManager) {
        
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 50
        
        super.init()
        watchUserLocation()
    }
    
    // MARK: Public methods
    func determineUserLocation() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: Private methods
    fileprivate func watchUserLocation() {
        launch {
            self.locationManager.rx
                .didChangeAuthorization
                .debug("didChangeAuthorization")
                .subscribe({ (event) in
                    if let status = event.element?.status {
                        switch status {
                        case .notDetermined:
                            log.d("notDetermined")
                            self.isLocationAuthorizationDenied.value = true
                        case .restricted:
                            log.d("restricted")
                            self.isLocationAuthorizationDenied.value = true
                        case .denied:
                            log.d("denied")
                            self.isLocationAuthorizationDenied.value = true
                        case .authorizedAlways:
                            log.d("authorizedAlways")
                            self.isLocationAuthorizationDenied.value = false
                            self.locationManager.startUpdatingLocation()
                        case .authorizedWhenInUse:
                            log.d("authorizedWhenInUse")
                            self.isLocationAuthorizationDenied.value = false
                            self.locationManager.startUpdatingLocation()
                        }
                    }
                })
        }
        
        launch {
            locationManager.rx
                .didUpdateLocations
                .debug("didUpdateLocations")
                .subscribe({ (event) in
                    guard let newLocation = event.element?.locations.first else { return }
                    log.d("update user location to (\(newLocation.coordinate.latitude),\(newLocation.coordinate.longitude))")
                    self.userLocation.value = newLocation
                })
        }
        
        launch {
            locationManager.rx
                .didError
                .debug("didError")
                .subscribe({ (event) in
                    guard let error = event.element?.error else { return }
                    log.e("fail to use location manager: \(error.localizedDescription)")
                })
        }
    }
}
