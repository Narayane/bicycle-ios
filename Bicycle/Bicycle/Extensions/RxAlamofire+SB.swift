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
import Alamofire
import RxAlamofire
import RxSwift

private let nullString = "(null)"
private let separatorString = "*******************************"

extension Observable where E == DataRequest {
    func log() -> Observable {
        return self.do { self.log() }
    }
}

extension Reactive where Base: DataRequest {
    func log() {
        self.base.log()
    }
}

extension ObservableType where E == (HTTPURLResponse, Any) {
    
}

extension ObservableType where E == (HTTPURLResponse, [String: Any]) {
    
}

extension DataRequest {
    /*public func logRequest() -> Self {
        print(terminator:"\n")
        print("🚀 REQUEST: \(self.request!.URL!)", terminator:"\n")
        debugPrint(self, terminator:"\n\n")
        
        _ = rx_responseJSON()
            .subscribe(
                onNext: { (response, json) in
                    print("✅ RESPONSE:", terminator:"\n")
                    debugPrint(response, terminator:"\n")
                    debugPrint(json, terminator: "\n\n")
            },
                onError: { [weak self] errorType in
                    print("❌ RESPONSE ERROR: \(errorType)", terminator:"\n")
                    debugPrint(self?.response, terminator:"\n\n")
            })
        
        return self
    }*/
    
    func log() {
        
        guard let request = self.request else {
            return
        }
        
        let method = request.httpMethod!
        let url = request.url?.absoluteString ?? nullString
        let headers = prettyPrintedString(from: request.allHTTPHeaderFields) ?? nullString
        
        // separator
        let openSeparator = "\(separatorString)\n"
        let closeSeparator = "\n\(separatorString)"
        let body = string(from: request.httpBody, prettyPrint: true) ?? nullString
        SBLog.self.d("\(openSeparator)[Request] \(method) '\(url)':\n\n[Headers]\n\(headers)\n\n[Body]\n\(body)\(closeSeparator)")
    }
    
    private func string(from data: Data?, prettyPrint: Bool) -> String? {
        
        guard let data = data else {
            return nil
        }
        
        var response: String? = nil
        
        if prettyPrint,
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let prettyString = prettyPrintedString(from: json) {
            response = prettyString
        }
            
        else if let dataString = String.init(data: data, encoding: .utf8) {
            response = dataString
        }
        
        return response
    }
    
    private func prettyPrintedString(from json: Any?) -> String? {
        guard let json = json else {
            return nil
        }
        
        var response: String? = nil
        
        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
            let dataString = String.init(data: data, encoding: .utf8) {
            response = dataString
        }
        
        return response
    }
}
