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

import Alamofire
import AlamofireObjectMapper

class CityBikesRestClient {
    
    static let shared: CityBikesRestClient = {
        let instance = CityBikesRestClient()
        return instance
    }()
    
    private let sessionManager: SessionManager
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        sessionManager = SessionManager(configuration: configuration)
    }

    func getStationsBy(url: String, handleSuccessWith: @escaping (_ stations: [CTBStationDto]) -> Void, handleFailureWith: @escaping () -> Void) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let URL: URLConvertible = url + "?fields=stations"
        
        sessionManager.request(URL).validate().responseObject { (response: DataResponse<CTBResponseDto>) in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            SBLog.verbose(response.request)
            
            switch response.result {
            case .success(let value):
                handleSuccessWith(value.stations ?? [])
                break
            case .failure(let error):
                SBLog.e(error.localizedDescription)
                SBLog.e(response.request)
                handleFailureWith()
                break
            }
        }
    }

}
