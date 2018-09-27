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
import RxCocoa
import RxSwift
import MapKit

// MARK: Events
class EventDataSendingPermissionsLoaded: SBEvent {
    var allowCrashDataSending: Bool
    var allowUseDataSending: Bool
    init(allowCrashDataSending: Bool, allowUseDataSending: Bool) {
        self.allowCrashDataSending = allowCrashDataSending
        self.allowUseDataSending = allowUseDataSending
    }
}
class EventDataSendingPermissionsSet : SBEvent {}

// MARK: -
open class BICOnboardingViewModel: SBViewModel {

    private let preferenceRepository: BICPreferenceRepository
    private let analytics: SBAnalytics
    
    // MARK: Constructors
    init(preferenceRepository: BICPreferenceRepository, analytics: SBAnalytics) {
        self.preferenceRepository = preferenceRepository
        self.analytics = analytics
    }
    
    // MARK: Public methods
    open func loadDataSendingPermissions() {
        events.value = EventDataSendingPermissionsLoaded(allowCrashDataSending: preferenceRepository.isCrashDataSendingAllowed,
                                                         allowUseDataSending: preferenceRepository.isUseDataSendingAllowed)
    }
    
    open func saveDataSendingPermissions(allowCrashDataSending: Bool, allowUseDataSending: Bool) {
        
        preferenceRepository.isCrashDataSendingAllowed = allowCrashDataSending
        preferenceRepository.isUseDataSendingAllowed = allowUseDataSending
        preferenceRepository.requestDataSendingPermissions = false
        
        var parameters = [String : Any]()
        parameters["value"] = allowCrashDataSending ? 1 : 0
        parameters["is_initial"] = 1
        analytics.sendEvent(name: "permission_crash_data_sending_set", parameters: parameters)
        
        parameters = [String : Any]()
        parameters["value"] = allowUseDataSending ? 1 : 0
        parameters["is_initial"] = 1
        analytics.sendEvent(name: "permission_use_data_sending_set", parameters: parameters)
        
        events.value = EventDataSendingPermissionsSet()
    }
}
