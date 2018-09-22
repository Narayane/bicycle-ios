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

import Foundation
import RxCocoa
import RxSwift
import MapKit

class BICHomeViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let contractService: BICContractRepository
    
    var currentContract: Variable<BICContract?>
    var hasCurrentContractChanged: Variable<Bool?>
    var currentStations: Variable<[BICStation]?>
    
    init(contractService: BICContractRepository) {
        self.contractService = contractService
        self.currentContract = Variable(nil)
        self.hasCurrentContractChanged = Variable(nil)
        self.currentStations = Variable(nil)
    }
    
    func getAllContracts() -> [BICContract] {
        return self.contractService.allContracts
    }
    
    func refreshContractStations(_ contract: BICContract) {
        log.d(String(format: "refresh contract stations: %@ (%@)", contract.name!))
        contractService.getStationsFor(contract: contract).subscribe(onSuccess: { (stations) in
            self.currentStations.value = stations
        }) { (error) in
            self.currentStations.value = nil
        }.disposed(by: disposeBag)
        /*BICStationService.shared.loadStationsFor(contract: contract, success: { (stations) in
            self.createAnnotationsFor(stations: stations)
        }, error: {
            self.queueMain.async {
                Toast.init(text: NSLocalizedString("bic_dialogs_message_stations_data_not_loaded", comment: ""), delay: 0, duration: 5).show()
            }
        })*/
    }
    
    func determineCurrentContract(region: MKCoordinateRegion) {
        
        var invalidateCurrentContract = false
        var hasChanged = false
        var current = currentContract.value
        
        if let currentRegion = current?.region, !currentRegion.intersect(region) {
            invalidateCurrentContract = true
            hasChanged = true
            current = nil
        }
        
        if (current == nil || invalidateCurrentContract) {
            current = self.contractService.getContract(for: region.center)
            hasChanged = hasChanged || current != nil
        }
        
        hasCurrentContractChanged.value = hasChanged
        if (currentContract.value != nil && current != nil) {
            if (currentContract.value! != current!) {
                // current has changed
                currentContract.value = current
            }
        } else {
            // someone is null
            currentContract.value = current
        }
    }
}
