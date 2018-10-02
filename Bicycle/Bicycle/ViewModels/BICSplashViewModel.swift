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

// MARK: States
class StateSplashConfig: SBState {}
class StateSplashContracts: SBState {}

// MARK: Events
class EventSplashForceUpdate: SBEvent {}
class EventSplashConfigLoaded: SBEvent {}
class EventSplashLoadConfigFailed: EventFailure {}
class EventSplashCheckContracts: SBEvent {}
class EventSplashAvailableContracts: SBEvent {
    var count: Int
    init(count: Int) {
        self.count = count
    }
}
class EventSplashRequestDataPermissions: SBEvent {
    var needed: Bool
    init(needed: Bool) {
        self.needed = needed
    }
}

// MARK: -
class BICSplashViewModel: SBViewModel {
    
    private let contractRepository: BICContractRepository
    private let preferenceRepository: BICPreferenceRepository
    
    // MARK: Constructors
    init(contractRepository: BICContractRepository, preferenceRepository: BICPreferenceRepository) {
        self.contractRepository = contractRepository
        self.preferenceRepository = preferenceRepository
    }

    // MARK: Public methods
    func loadConfig() {
        states.value = StateSplashConfig()
        launch {
            preferenceRepository.loadConfig().subscribe(onSuccess: { (iosConfig) in
                if self.checkForceUpdate(iosConfig: iosConfig) {
                    self.events.value = EventSplashForceUpdate()
                } else {
                    self.events.value = EventSplashConfigLoaded()
                }
            }, onError: { (error) in
                self.events.value = EventSplashLoadConfigFailed(error)
            })
        }
    }
    
    func loadAllContracts() {
        states.value = StateSplashContracts()
    
        var timeToCheck = true
        let now = Date()
        
        if let lastCheckDate = preferenceRepository.contractsLastCheckDate {
            log.v("contracts last check: \(lastCheckDate.format(format: "dd/MM/yyyy"))")
            timeToCheck = lastCheckDate.daysBetween(now) > preferenceRepository.contractsCheckDelay
        }
    
        if (timeToCheck) {
            log.d("try to load all contracts")
            events.value = EventSplashCheckContracts()
            launch {
                self.contractRepository.updateContracts()
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { (count) in
                        self.events.value = EventSplashAvailableContracts(count: count)
                    }, onError: { (error) in
                        self.events.value = EventFailure(error)
                    })
            }
        } else {
            log.d("contracts are up-to-date")
            preferenceRepository.contractsLastCheckDate = now
            launch {
                self.contractRepository.getContractCount()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { (count) in
                        self.events.value = EventSplashAvailableContracts(count: count)
                    }, onError: { (error) in
                        self.events.value = EventFailure(error)
                    })
            }
        }
    }
    
    func requestDataSendingPermissions() {
        events.value = EventSplashRequestDataPermissions(needed: preferenceRepository.requestDataSendingPermissions)
    }
    
    // MARK: Private methods
    private func checkForceUpdate(iosConfig: BICConfigIOSDto) -> Bool {
        
        var timeToCheck = true
        if let lastCheckDate = preferenceRepository.appLastCheckDate {
            log.v("app last check: \(lastCheckDate.format(format: "dd/MM/yyyy"))")
            timeToCheck = lastCheckDate.daysBetween(Date()) > preferenceRepository.appCheckDelay
        }
        
        if timeToCheck {
            log.d("check app version")
            
            let lastVersion: String = iosConfig.appVersion!
            log.i("lastest version: \(lastVersion)")
            let currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
            log.i("current version: \(currentVersion)")
            
            if lastVersion.compare(currentVersion, options: String.CompareOptions.numeric) == ComparisonResult.orderedDescending {
                return iosConfig.forceUpdate!
            } else {
                log.d("no need to force update")
                preferenceRepository.appLastCheckDate = Date()
            }
        } else {
            log.v("no need to check again")
        }
        return false
    }
}
