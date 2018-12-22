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

import Reachability

class SBConnectivity {
    
    var reachability: Reachability?
    
    private var _hasConnection: Bool = true
    var hasConnection: Bool? {
        return _hasConnection
    }
    
    init(reachability: Reachability?) {
        self.reachability = reachability
    }
    
    func watchConnection() {
        reachability?.whenReachable = { reachability in
            log.i("has connectivity: true")
            self._hasConnection = true
            /*if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }*/
        }
        reachability?.whenUnreachable = { _ in
            log.i("has connectivity: false")
            self._hasConnection = false
        }
        
        do {
            log.d("watch connectivity")
            try reachability?.startNotifier()
        } catch {
            log.e("unable to watch connectivity")
        }
    }
    
    func unwatchConnection() {
        log.d("unwatch connectivity")
        reachability?.stopNotifier()
    }
}
