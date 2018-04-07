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

class BICSearchViewModel {
    
    let isSearchButtonEnabled: Variable<Bool> = Variable<Bool>(false)
    var departure: BICPlace? {
        didSet {
            self.isSearchButtonEnabled.value = self.departure != nil && self.arrival != nil
        }
    }
    var arrival: BICPlace? {
        didSet {
            self.isSearchButtonEnabled.value = self.departure != nil && self.arrival != nil
        }
    }
    var bikesCount: Int = 1
    var freeSlotsCount: Int = 1
    var isComplete: Bool {
        get {
            return self.departure?.contract != nil && self.arrival?.contract != nil
                && (self.departure!.contract!.center == self.arrival!.contract!.center)
        }
    }
    
}
