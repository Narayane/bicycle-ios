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
import Dip
import CoreLocation

extension DependencyContainer {
    
    func configure() {
        registerCommonModule()
        registerOnboardingModule()
        registerHomeModule()
    }
    
    private func registerCommonModule() {
        
        self.register(.singleton) { UIApplication.shared.delegate as! AppDelegate }
        
        // singleton
        self.register(.singleton) { UserDefaults.standard }
        self.register(.singleton) { CLLocationManager() }
        
        // data source
        self.register(.singleton) { BICLocalDataSource() }
        self.register(.singleton) { BicycleDataSource() }
        self.register(.singleton) { CityBikesDataSource() }
        
        // repository
        self.register(.singleton) { try BICContractRepository(appDelegate: self.resolve(), bicycleDataSource: self.resolve(), cityBikesDataSource: self.resolve(), localDataSource: self.resolve(), preferenceRepository: self.resolve()) }
        self.register(.singleton) { try BICPreferenceRepository(bicycleDataSource: self.resolve(), userDefaults: self.resolve()) }
        
        // tools
        self.register(.singleton) { try SBAnalytics(preferenceRepository: self.resolve()) }
    }
    
    private func registerOnboardingModule() {
        
        // view model
        self.register(.unique) { try BICSplashViewModel(contractRepository: self.resolve(), preferenceRepository: self.resolve()) }
        self.register(.unique) { try BICOnboardingViewModel(preferenceRepository: self.resolve(), analytics: self.resolve()) }
        
        // view
        self.register(storyboardType: BICSplashViewController.self, tag: "Splash")
            .resolvingProperties { container, vc in
                vc.viewModel = try container.resolve() as BICSplashViewModel
        }
        self.register(storyboardType: BICDataPermissionsViewController.self, tag: "DataPermissions")
            .resolvingProperties { container, vc in
                vc.viewModel = try container.resolve() as BICOnboardingViewModel
        }
    }
    
    private func registerHomeModule() {
        
        // view model
        self.register(.shared) { try BICMapViewModel(locationManager: self.resolve()) }
        self.register(.unique) { try BICHomeViewModel(contractRepository: self.resolve()) }
        
        // view
        self.register(storyboardType: BICHomeViewController.self, tag: "Home")
            .resolvingProperties { container, vc in
                vc.viewModelMap = try container.resolve() as BICMapViewModel
                vc.viewModelHome = try container.resolve() as BICHomeViewModel
        }
    }
}
