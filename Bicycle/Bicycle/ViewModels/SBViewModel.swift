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

// MARK: States
open class SBState {}
open class SBEvent {}
// MARK: Events
open class EventError: SBEvent {
    var error: Error
    init(_ error: Error) {
        self.error = error
    }
}

// MARK: -
open class SBViewModel {
    
    private let disposeBag = DisposeBag()
    
    private var _states: Variable<SBState> = Variable<SBState>(SBState())
    var states: Variable<SBState> {
        get {
            return _states
        }
    }
    
    var currentState: SBState {
        get {
            return self.states.value
        }
    }
    
    private var _events = Variable<SBEvent>(SBEvent())
    var events: Variable<SBEvent> {
        get {
            return _events
        }
    }
    
    var currentEvent: SBEvent {
        get {
            return self.events.value
        }
    }
    
    func launch(_ rx: () -> Disposable) {
        rx().disposed(by: self.disposeBag)
    }
}
