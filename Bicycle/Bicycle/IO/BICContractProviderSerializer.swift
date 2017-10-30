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

import ObjectMapper

class BICContractProviderSerializer: TransformType {
    
    public typealias Object = BICContract.Provider
    public typealias JSON = String
    
    public func transformFromJSON(_ value: Any?) -> Object? {
        if let tag = value as? JSON {
            return Object.from(tag: tag)
        }
        return nil
    }
    
    public func transformToJSON(_ value: Object?) -> JSON? {
        if let provider = value {
            return provider.tag
        }
        return nil
    }
    
}
