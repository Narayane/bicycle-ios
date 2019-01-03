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

// MARK: States
class StateShowContracts: SBState {}
class StateShowStations: SBState {}

// MARK: Events
class EventOutOfAnyContract: SBEvent {}
class EventNewContract: SBEvent {
    var contract: BICContract
    init(contract: BICContract) {
        self.contract = contract
    }
}
class EventSameContract: SBEvent {}
class EventContractList: SBEvent {
    var contracts: [BICContract]
    init(contracts: [BICContract]) {
        self.contracts = contracts
    }
}
class EventStationList: SBEvent {
    var stations: [BICStation]
    init(stations: [BICStation]) {
        self.stations = stations
    }
}

class BICHomeViewModel: SBViewModel {
    
    private let contractRepository: BICContractRepository
    
    var currentContract: BICContract? = nil
    
    init(contractRepository: BICContractRepository) {
        self.contractRepository = contractRepository
    }
    
    // MARK: Public methods
    func getAllContracts() {
        states.accept(StateShowContracts())
        currentContract = nil
        launch {
            contractRepository.loadAllContracts()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (contracts) in
                    self.events.accept(EventContractList(contracts: contracts))
                }, onError: { (error) in
                    self.events.accept(EventFailure(error))
                })
        }
    }
    
    func getStationsFor(contract: BICContract) {
        states.accept(StateShowStations())
        launch {
            contractRepository.loadStationsBy(contract: contract)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (stations) in
                    self.events.accept(EventStationList(stations: stations))
                }, onError: { (error) in
                    self.events.accept(EventFailure(error))
                })
        }
    }
    
    func refreshStationsFor(contract: BICContract) {
        launch {
            contractRepository.reloadStationsBy(contract: contract)
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { (stations) in
                    self.events.accept(EventStationList(stations: stations))
                }, onError: { (error) in
                    self.events.accept(EventFailure(error))
                })
        }
    }
    
    func determineCurrentContract(region: MKCoordinateRegion) {
        
        log.v("determine current contrat")
        
        var invalidateCurrentContract = false
        var hasChanged = false
        var current: BICContract? = nil
        
        if let intersected = currentContract?.region.intersect(region), !intersected {
            invalidateCurrentContract = true
        }
        
        if (currentContract == nil || invalidateCurrentContract) {
            current = self.contractRepository.getContract(for: region.center)
            hasChanged = current != nil
        }
        
        if (current != nil && hasChanged)  {
            currentContract = current
            events.accept(EventNewContract(contract: current!))
        } else if (currentContract != nil && !invalidateCurrentContract) {
            events.accept(EventSameContract())
        } else {
            currentContract = nil
            events.accept(EventOutOfAnyContract())
        }
    }
}
