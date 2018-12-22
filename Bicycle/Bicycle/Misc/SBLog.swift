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

import SwiftyBeaver
import Crashlytics

class SBLog {
    
    private static var logger = SwiftyBeaver.self
    private static var crashReport: SBCrashReport?
    
    class func setMinimumLevel(_ level: String) -> Void {
        
        var logLevel: SwiftyBeaver.Level
        
        switch level {
        case "all", "verbose":
            logLevel = .verbose
            break
        case "debug":
            logLevel = .debug
            break
        case "error":
            logLevel = .error
            break
        case "warning":
            logLevel = .warning
            break
        default:
            logLevel = .info
            break
        }
        
        let console = ConsoleDestination()
        console.minLevel = logLevel
        console.format = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c [$T] $N.$F:$l - $M"
        logger.addDestination(console)
        logger.info("log level: \(level)")
    }
    
    class func setCrashReport(_ crashReport: SBCrashReport?) {
        self.crashReport = crashReport
    }
    
    class func v(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        logger.verbose(message, fileName, functionName, line: lineNumber)
    }
    
    class func v(_ request: URLRequest?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        if let request = request {
            let message = extractData(from: request)
            v(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    class func d(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        logger.debug(message, fileName, functionName, line: lineNumber)
        crashReport?.logDebug(message)
    }
    
    class func d(_ request: URLRequest?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        if let request = request {
            let message = extractData(from: request)
            d(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    class func i(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        logger.info(message, fileName, functionName, line: lineNumber)
        crashReport?.logInfo(message)
    }
    
    class func w(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        logger.warning(message, fileName, functionName, line: lineNumber)
        crashReport?.logWarn(message)
    }
    
    class func e(_ message: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        logger.error(message)
        crashReport?.logError(message)
    }
    
    class func e(_ request: URLRequest?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        if let request = request {
            let message = extractData(from: request)
            e(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    private class func extractData(from request: URLRequest) -> String {
        var message = "URL: \(request.url!) - \(request.httpMethod!) - Headers: \(request.allHTTPHeaderFields!)"
        if let body = request.httpBody {
            message += " - Parameters: \(String(data: body, encoding: String.Encoding.utf8)!)"
        }
        return message
    }
}
