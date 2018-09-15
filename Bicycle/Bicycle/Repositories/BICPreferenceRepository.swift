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

import CoreLocation
import RxCocoa
import RxSwift

open class BICPreferenceRepository {
    
    private let disposeBag: DisposeBag
    private let bicycleDataSource: BicycleDataSource
    private let defaults: UserDefaults
    
    init(bicycleDataSource: BicycleDataSource, userDefaults: UserDefaults) {
        disposeBag = DisposeBag()
        self.bicycleDataSource = bicycleDataSource
        self.defaults = userDefaults
    }
    
    open var requestDataSendingPermissions: Bool {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_REQUEST_DATA_SENDING_PERMISSIONS) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_REQUEST_DATA_SENDING_PERMISSIONS)
        }
    }
    
    open var isCrashDataSendingAllowed: Bool {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_CRASH_DATA_SENDING_PERMISSION) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_CRASH_DATA_SENDING_PERMISSION)
        }
    }
    
    open var isUseDataSendingAllowed: Bool {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_USE_DATA_SENDING_PERMISSION) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_USE_DATA_SENDING_PERMISSION)
        }
    }
    
    open var appCheckDelay: Int {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_APP_CHECK_DELAY) as? Int ?? 7
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_APP_CHECK_DELAY)
        }
    }
    
    open var contractsCheckDelay: Int {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_CONTRACTS_CHECK_DELAY) as? Int ?? 30
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_CONTRACTS_CHECK_DELAY)
        }
    }
    
    open var contractsLastCheckDate: Date? {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_CONTRACTS_LAST_CHECK_DATE) as? Date
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_CONTRACTS_LAST_CHECK_DATE)
        }
    }
    
    open var contractsVersion: Int {
        get {
            return defaults.object(forKey: BICConstants.PREFERENCE_CONTRACTS_VERSION) as? Int ?? 0
        }
        set {
            defaults.set(newValue, forKey: BICConstants.PREFERENCE_CONTRACTS_VERSION)
        }
    }
    
    //MARK: Public methods
    open func loadConfig() -> Completable {
        return Completable.create { observer in
            self.bicycleDataSource.getConfig()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (response) in
                    self.setConfig(with: response)
                    observer(.completed)
                }, onError: { (error) in
                    observer(.error(error))
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    //MARK: Private methods
    private func setConfig(with response: BICConfigResponseDto) {
        if let delay = response.appCheckDelay {
            log.v("app check delay: \(delay)")
            appCheckDelay = delay
        }
        if let delay = response.contactsCheckDelay {
            log.v("contracts check delay: \(delay)")
            contractsCheckDelay = delay
        }
    }
}
