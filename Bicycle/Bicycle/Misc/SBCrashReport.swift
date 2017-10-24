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

import Fabric
import Crashlytics

class SBCrashReport {
    
    class func start() {
        if (Bundle.main.object(forInfoDictionaryKey: "SBCrashReportEnabled") as! String).boolValue() {
            Fabric.with([Crashlytics.self, Answers.self])
            SBLog.i("start crash report")
        }
    }
    
    class func log(_ message: String?, level: String?, function: String?, file: String?, line: String?) {
        if (Bundle.main.object(forInfoDictionaryKey: "SBCrashReportEnabled") as! String).boolValue() {
            if let message = message {
                var log = ""
                if let file = file, let function = function, let line = line, let level = level {
                    log = "\(level) | [\(file):\(line)] - \(function) > "
                }
                log += message
                CLSLogv("%@", getVaList([log]))
            }
        }
    }
    
    class func logCustomEvent(_ name: String) {
        if (Bundle.main.object(forInfoDictionaryKey: "SBCrashReportEnabled") as! String).boolValue() {
            Answers.logCustomEvent(withName: name, customAttributes: [:])
        }
    }
    
}
