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

    private let preferenceRepository: BICPreferenceRepository? = nil

    init(preferenceRepository: BICPreferenceRepository) {
        #if RELEASE
            log.d("init crash report")
            Fabric.with([Crashlytics.self])
            self.preferenceRepository = preferenceRepository
        #endif
    }
    
    func logDebug(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if !DEV
        self.logMessage(message, level: "DEBUG", functionName: function, fileName: file, lineNumber: line)
        #endif
    }
    
    func logInfo(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if !DEV
        self.logMessage(message, functionName: function, fileName: file, lineNumber: line)
        #endif
    }
    
    func logWarn(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if !DEV
        self.logMessage(message, level: "WARN", functionName: function, fileName: file, lineNumber: line)
        #endif
    }
    
    func logError(_ message: String, function: String = #function, file: String = #file, line: Int = #line) {
        #if !DEV
        self.logMessage(message, level: "ERROR", functionName: function, fileName: file, lineNumber: line)
        #endif
    }
    
    private func logMessage(_ message: String, level: String = "INFO", functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        #if RELEASE
        if let dataSendingAllow = preferenceRepository?.isCrashDataSendingAllowed, crashSendingAllow {
            var log = ""
            if let file = file, let function = function, let line = line, let level = level {
                log = "\(Date().format(format: "yyyy-MM-dd HH:mm:ss.SSS")) [\(level)] \(file):\(line) - \(function): "
            }
            log += message
            CLSLogv("%@", getVaList([log]))
        }
        #endif
    }
    
    func catchException(error: Error) -> String {
        #if RELEASE
        if let dataSendingAllow = preferenceRepository?.isCrashDataSendingAllowed, crashSendingAllow {
            Crashlytics.sharedInstance().recordError(error)
        }
        #endif
        return error.localizedDescription
    }
}
