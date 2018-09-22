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

import Foundation

class BICConstants {
    
    static let PREFERENCE_APP_CHECK_DELAY: String = "PREFERENCE_APP_CHECK_DELAY"
    static let PREFERENCE_APP_LAST_CHECK_DATE: String = "PREFERENCE_APP_LAST_CHECK_DATE"
    static let PREFERENCE_CONTRACTS_CHECK_DELAY: String = "PREFERENCE_CONTRACTS_CHECK_DELAY"
    static let PREFERENCE_CONTRACTS_LAST_CHECK_DATE: String = "PREFERENCE_CONTRACTS_LAST_CHECK_DATE"
    static let PREFERENCE_CONTRACTS_VERSION: String = "PREFERENCE_CONTRACTS_VERSION"
    static let PREFERENCE_REQUEST_DATA_SENDING_PERMISSIONS: String = "PREFERENCE_REQUEST_DATA_SENDING_PERMISSIONS"
    static let PREFERENCE_CRASH_DATA_SENDING_PERMISSION: String = "PREFERENCE_CRASH_DATA_SENDING_PERMISSION"
    static let PREFERENCE_USE_DATA_SENDING_PERMISSION: String = "PREFERENCE_USE_DATA_SENDING_PERMISSION"
    
    static let CLUSTERING_ZOOM_LEVEL_START: Int = 15
    static let CLUSTERING_ZOOM_LEVEL_STOP: Int = 11
    static let TIME_BEFORE_REFRESH_DATA_IN_SECONDS: Double = 120
    static let RIDE_MIN_DISTANCE_IN_METERS: Double = 250
    static let STATION_SEARCH_MAX_RADIUS_IN_METERS: Double = 500
}
