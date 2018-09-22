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

import ObjectMapper

open class BICConfigResponseDto: Mappable {
    
    var appCheckDelay: Int?
    var iosConfig: BICConfigIOSDto?
    var contactsCheckDelay: Int?
    
    required public init?(map: Map) {}
    
    public func mapping(map: Map) {
        appCheckDelay <- map["apps.check_delay"]
        iosConfig <- map["apps.ios"]
        contactsCheckDelay <- map["contracts.check_delay"]
    }
}

open class BICConfigIOSDto: Mappable {
    
    var appVersion: String?
    var forceUpdate: Bool?
    
    required public init?(map: Map) {}
    
    public func mapping(map: Map) {
        appVersion <- map["version"]
        forceUpdate <- map["force_update"]
    }
}
