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

import XCGLogger
import Crashlytics

class SBLog {
    
    private static var LOGGER: XCGLogger = XCGLogger.default
    
    private static func initLogger(useColors colors: Bool) -> Void {
        
        if colors {
            if let consoleDestination: ConsoleDestination = LOGGER.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
                let xcodeColorsLogFormatter: XcodeColorsLogFormatter = XcodeColorsLogFormatter()
                xcodeColorsLogFormatter.colorize(level: .verbose, with: .lightGrey)
                xcodeColorsLogFormatter.colorize(level: .debug, with: .darkGrey)
                xcodeColorsLogFormatter.colorize(level: .info, with: .blue)
                xcodeColorsLogFormatter.colorize(level: .warning, with: .orange)
                xcodeColorsLogFormatter.colorize(level: .error, with: .red)
                xcodeColorsLogFormatter.colorize(level: .severe, with: .white, on: .red)
                consoleDestination.formatters = [xcodeColorsLogFormatter]
            }
        }
    }
    
    static func setLogLevel(_ level: String!) -> Void {
        
        initLogger(useColors: false)
        
        var logLevel: XCGLogger.Level
        
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
        case "wtf":
            logLevel = .severe
            break
        default:
            logLevel = .info
            break
        }
        
        LOGGER.setup(level: logLevel, showFunctionName: true, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true)
        LOGGER.info("log level: \(level!)")
    }
    
    static func v(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.verbose(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "V", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
    
    static func verbose(_ request: URLRequest?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        if let request = request {
            var message = "URL: \(request.url!) - \(request.httpMethod!) - Headers: \(request.allHTTPHeaderFields!)"
            if let body = request.httpBody {
                message += " - Parameters: \(String(data: body, encoding: String.Encoding.utf8)!)"
            }
            v(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    static func d(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.debug(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "D", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
    
    static func debug(_ request: URLRequest?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        if let request = request {
            var message = "URL: \(request.url!) - \(request.httpMethod!) - Headers: \(request.allHTTPHeaderFields!)"
            if let body = request.httpBody {
                message += " - Parameters: \(String(data: body, encoding: String.Encoding.utf8)!)"
            }
            d(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    static func i(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.info(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "I", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
    
    static func w(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.warning(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "W", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
    
    static func e(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.error(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "E", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
    
    static func e(_ request: URLRequest?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        if let request = request {
            var message = "URL: \(request.url!) - \(request.httpMethod!) - Headers: \(request.allHTTPHeaderFields!)"
            if let body = request.httpBody {
                message += " - Parameters: \(String(data: body, encoding: String.Encoding.utf8)!)"
            }
            e(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
    
    static func wtf(_ message: String?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        LOGGER.severe(message, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        SBCrashReport.log(message, level: "WTF", function: functionName.description, file: fileName.description, line: lineNumber.description)
    }
}
