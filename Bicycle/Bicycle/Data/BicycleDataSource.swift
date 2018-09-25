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

import Alamofire
import AlamofireObjectMapper
import RxAlamofire
import RxCocoa
import RxSwift

class BicycleDataSource {
    
    private let sessionManager: SessionManager
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        sessionManager = SessionManager(configuration: configuration)
    }
    
    func getConfig() -> Single<BICConfigResponseDto> {
        
        let endpoint = "\(BICKeys.STORAGE_ENDPOINT)/config.json?alt=media&token=\(BICKeys.STORAGE_TOKEN)"
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        return sessionManager.rx.request(.get, endpoint).log().responseMappable(as: BICConfigResponseDto.self)
            .subscribeOn(MainScheduler.instance)
            .do {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            .asSingle()
    }
    
    func getContracts() -> Single<BICContractsDataResponseDto> {
        
        let endpoint = "\(BICKeys.STORAGE_ENDPOINT)/contracts.json?alt=media&token=\(BICKeys.STORAGE_TOKEN)"
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        return sessionManager.rx.request(.get, endpoint).log().responseMappable(as: BICContractsDataResponseDto.self)
            .subscribeOn(MainScheduler.instance)
            .do {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            .asSingle()
    }
}
