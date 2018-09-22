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
import RxAlamofire
import RxCocoa
import RxSwift

class CityBikesDataSource {
    
    static let shared: CityBikesDataSource = {
        let instance = CityBikesDataSource()
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
            log.v(response.request)
            
            switch response.result {
            case .success(let value):
                handleSuccessWith(value.stations)
                break
            case .failure(let error):
                log.e(error.localizedDescription)
                log.e(response.request)
                handleFailureWith()
                break
            }
        }
    }
    
    func getStationsBy(url: String) -> Single<[BICStation]> {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let endpoint = url + "?fields=stations"
        
        return sessionManager.rx.request(.get, endpoint).responseMappable(as: CTBResponseDto.self)
            .subscribeOn(MainScheduler.instance)
            .do(onNext: { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map({ (response) -> [CTBStationDto] in
                response.stations
            })
            .concatMap({ (dtos) -> Observable<CTBStationDto> in
                Observable.from(dtos)
            })
            .map({ (dto) -> BICStation in
                BICStation(citybikes: dto)
            })
            .toArray().asSingle()
    }
}
