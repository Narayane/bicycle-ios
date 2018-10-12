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

import UIKit
import MapKit
import RxCocoa
import RxSwift
import Cluster
import Toaster
import Dip

private let CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP = CGFloat(-180)
private let STATION_CELL_REUSE_ID = "station_marker"
private let CLUSTER_CELL_REUSE_ID = "cluster_marker"
private let CONTRACT_CELL_REUSE_ID = "contract_marker"

class BICHomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonCenterOnUserLocation: UIButton!
    @IBOutlet weak var bottomSheetView: UIView!
    @IBOutlet weak var bottomSheetTitle: UILabel!
    @IBOutlet weak var bottomSheetSubtitle: UILabel!
    @IBOutlet weak var bottomSheetAvailableBikesCount: UILabel!
    @IBOutlet weak var bottomSheetFreeStandsCount: UILabel!
    @IBOutlet weak var fabContractZoom: UIButton!
    
    @IBOutlet weak var constraintBottomSheetViewTop: NSLayoutConstraint!
    
    var viewModelMap: BICMapViewModel?
    var viewModelHome: BICHomeViewModel?
    
    private let disposeBag = DisposeBag()
    
    private var clusterContracts: ClusterManager = ClusterManager()
    private var clusterStations: ClusterManager = ClusterManager()
    private var timer: Timer?
    private let queueMain = DispatchQueue.main
    private let queueComputation = DispatchQueue.global(qos: .userInitiated)
    
    private var annotations: [MKAnnotation]?
    private var selectedAnnotationView: MKAnnotationView?
    private var previousZoomLevel: Int?
    private var preventRegionDidChange = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initLayout()
        observeStates()
        observeEvents()
        observeUserLocation()
        
        launch {
            viewModelMap?.isLocationAuthorizationDenied.asDriver().drive(buttonCenterOnUserLocation.rx.isHidden)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModelMap?.determineUserLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Events
    @IBAction func onMapTouched(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.view)
        if let subview = self.view.hitTest(tapLocation, with: nil) {
            if subview.isKind(of: NSClassFromString("MKNewAnnotationContainerView")!) {
                log.i("touch map")
                hideBottomSheet(annotationView: selectedAnnotationView)
            }
        }
    }
    
    @IBAction func onCenterOnUserLocationButtonTouched(_ sender: UIButton) {
        log.i("click on button: center on user location")
        centerOnUserLocation()
    }
    
    @IBAction func didContractZoomButtonTouch(_ sender: UIButton) {
        if let contract = (selectedAnnotationView?.annotation as? BICContractAnnotation)?.contract, let region = mapView.getRegion(center: contract.center, zoomLevel: 11) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: Timer
    private func startTimer() {
        if timer == nil {
            log.d("start timer")
            timer = Timer.scheduledTimer(withTimeInterval: BICConstants.TIME_BEFORE_REFRESH_DATA_IN_SECONDS, repeats: true, block: { _ in
                log.d("timer fired: \(String(describing: self.timer?.fireDate.format(format: "hh:mm:ss")))")
                if let current = self.viewModelHome?.currentContract {
                    self.viewModelHome?.refreshStationsFor(contract: current)
                }
            })
        }
    }
    
    private func stopTimer() {
        if timer != nil {
            log.d("stop timer")
        }
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: Annotations
    private func centerOnUserLocation() {
        if let existingUserLocation = viewModelMap?.userLocation.value {
            log.i("center on user location")
            let coordinateRegion: MKCoordinateRegion! = MKCoordinateRegion.init(center: existingUserLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    private func refreshAnnotations() {
        let zoomLevel = mapView.zoomLevel
        log.d("current zoom level: \(zoomLevel)")
        if let previous = previousZoomLevel {
            if (zoomLevel != previous) {
                hideBottomSheet(annotationView: selectedAnnotationView)
            }
        }
        previousZoomLevel = zoomLevel
        if zoomLevel >= 10 {
            if !haveStationAnnotations() {
                log.v("delete contract annotations")
                clusterContracts.removeAll()
                clusterContracts.reload(mapView: mapView)
            }
            viewModelHome?.determineCurrentContract(region: mapView.region)
        } else {
            stopTimer()
            if !haveContractAnnotations() {
                log.v("delete station annotations")
                clusterStations.removeAll()
                clusterStations.reload(mapView: mapView)
                viewModelHome?.getAllContracts()
            } else {
                clusterContracts.reload(mapView: mapView)
            }
        }
    }
    
    private func haveContractAnnotations() -> Bool {
        return clusterContracts.annotations.count > 0
    }
    
    private func haveStationAnnotations() -> Bool {
        return clusterStations.annotations.count > 0
    }
    
    // MARK: Fileprivate methods
    fileprivate func refreshBottomSheetLayout(annotation: MKAnnotation) {
        switch annotation {
        case let contractAnnotation as BICContractAnnotation:
            bottomSheetTitle.text = contractAnnotation.contract.name
            bottomSheetSubtitle.text = contractAnnotation.contract.countryName ?? "-"
            bottomSheetAvailableBikesCount.text = ""
            bottomSheetFreeStandsCount.text = "bic_plurals_stations".localized(contractAnnotation.contract.stationCount)
        case let stationAnnotation as BICStationAnnotation:
            bottomSheetTitle.text = stationAnnotation.station.displayName
            bottomSheetSubtitle.text = viewModelHome?.currentContract?.name ?? "-"
            bottomSheetAvailableBikesCount.text = "bic_plurals_available_bikes".localized(stationAnnotation.station.bikesCount ?? 0)
            bottomSheetFreeStandsCount.text = "bic_plurals_free_stands".localized(stationAnnotation.station.freeCount ?? 0)
        default: break
        }
    }
    
    fileprivate func showBottomSheet(annotationView: MKAnnotationView) {
        DispatchQueue.main.async {
            
            if self.selectedAnnotationView != nil {
                guard let selectedAnnotation = self.selectedAnnotationView?.annotation as? Annotation, let touchedAnnotation = annotationView.annotation as? Annotation, !selectedAnnotation.isEqual(touchedAnnotation) else { return }
            }
            
            let touchedAnnotation = annotationView.annotation as! Annotation
            self.mapView.setCenter(touchedAnnotation.coordinate, animated: true)
            self.preventRegionDidChange = true
            switch touchedAnnotation {
            case is BICContractAnnotation:
                annotationView.image = #imageLiteral(resourceName: "BICImgContractSelected").resizeTo(width: 64, height: 64)
            case let stationAnnotation as BICStationAnnotation:
                var image = #imageLiteral(resourceName: "BICImgStationSelected").resizeTo(width: 64, height: 64)
                if let bikes = stationAnnotation.station.bikesCount?.description {
                    image = image.drawText(bikes, at: CGPoint(x: 0, y: 5), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
                }
                if let free = stationAnnotation.station.freeCount?.description {
                    image = image.drawText(free, at: CGPoint(x: 0, y: 30), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
                }
                annotationView.image = image
                annotationView.centerOffset = CGPoint(x: 0, y:-(image.size.height / 2))
            default: break
            }
            self.selectedAnnotationView = annotationView
            
            self.refreshBottomSheetLayout(annotation: touchedAnnotation)
            
            if let currentState = self.viewModelHome?.states.value {
                switch (currentState) {
                case is StateShowContracts:
                    self.fabContractZoom.isHidden = false
                default:
                    self.fabContractZoom.isHidden = true
                }
            }
            
            if self.constraintBottomSheetViewTop.constant == 0 {
                self.constraintBottomSheetViewTop.constant = self.bottomSheetView.frame.height * -1
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    fileprivate func hideBottomSheet(annotationView: MKAnnotationView?) {
        DispatchQueue.main.async {
            if let annotationView = self.selectedAnnotationView {
                let touchedAnnotation = annotationView.annotation as! Annotation
                switch touchedAnnotation {
                case is BICContractAnnotation:
                    annotationView.image = #imageLiteral(resourceName: "BICImgContract").resizeTo(width: 64, height: 64)
                case let stationAnnotation as BICStationAnnotation:
                    var image = #imageLiteral(resourceName: "BICImgStation").resizeTo(width: 64, height: 64)
                    if let bikes = stationAnnotation.station.bikesCount?.description {
                        image = image.drawText(bikes, at: CGPoint(x: 0, y: 5), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
                    }
                    if let free = stationAnnotation.station.freeCount?.description {
                        image = image.drawText(free, at: CGPoint(x: 0, y: 30), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
                    }
                    annotationView.image = image
                    annotationView.centerOffset = CGPoint(x: 0, y:-(image.size.height / 2))
                    
                default: break
                }
                self.selectedAnnotationView = nil
                
                if self.constraintBottomSheetViewTop.constant < 0 {
                    self.constraintBottomSheetViewTop.constant = 0
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: { (success) in
                        self.fabContractZoom.isHidden = true
                    })
                }
            }
        }
    }
    
    fileprivate func initLayout() {
        navigationItem.title = "Bicycle"
        /*clusterContracts.minCountForClustering = 4
        clusterStations.minCountForClustering = 8*/
    }
    
    fileprivate func observeStates() {
        launch {
            viewModelHome?.states.asObservable().observeOn(MainScheduler.instance).subscribe { (rx) in
                guard let state = rx.element else { return }
                log.v("state -> \(String(describing: type(of: state)))")
                switch (state) {
                case is StateShowContracts:
                    break
                case is StateShowStations:
                    break
                default: break
                }
                self.fabContractZoom.isHidden = true
            }
        }
    }
    
    fileprivate func observeEvents() {
        launch {
            viewModelHome?.events.asObservable().observeOn(MainScheduler.instance).subscribe({ (rx) in
                guard let event = rx.element else { return }
                log.v("event -> \(String(describing: type(of: event)))")
                switch event {
                case is EventContractList:
                    guard let event = event as? EventContractList else { return }
                    self.hideBottomSheet(annotationView: self.selectedAnnotationView)
                    let annotations = event.contracts.map({ (contract) -> BICContractAnnotation in
                        return BICContractAnnotation(contract: contract)
                    })
                    self.clusterContracts.add(annotations)
                    self.clusterContracts.reload(mapView: self.mapView)
                case is EventOutOfAnyContract:
                    log.d("current bounds is out of contracts cover")
                    self.stopTimer()
                case is EventNewContract:
                    guard let event = event as? EventNewContract else { return }
                    self.stopTimer()
                    log.d("refresh contract stations: \(String(describing: event.contract.name))")
                    // refresh current contract stations data
                    self.viewModelHome?.getStationsFor(contract: event.contract)
                    self.startTimer()
                case is EventSameContract:
                    log.v("current contract has not changed")
                    // reload clustering
                    self.clusterStations.reload(mapView: self.mapView)
                case is EventStationList:
                    guard let event = event as? EventStationList else { return }
                    self.clusterStations.removeAll()
                    self.hideBottomSheet(annotationView: self.selectedAnnotationView)
                    let annotations = event.stations.map({ (station) -> BICStationAnnotation in
                        return BICStationAnnotation(station: station)
                    })
                    self.clusterStations.add(annotations)
                    self.clusterStations.reload(mapView: self.mapView)
                case is EventFailure:
                    if let currentState = self.viewModelHome?.states.value {
                        switch currentState {
                        case is StateShowContracts:
                            self.clusterContracts.removeAll()
                            self.hideBottomSheet(annotationView: self.selectedAnnotationView)
                            //TODO: display error message
                        case is StateShowStations:
                            self.clusterStations.removeAll()
                            self.hideBottomSheet(annotationView: self.selectedAnnotationView)
                            //showErrorForCurrentContractStation()
                        default: break
                        }
                    }
                default: break
                }
            })
        }
    }
    
    fileprivate func observeUserLocation() {
        launch {
            viewModelMap?.userLocation.asObservable().subscribe { (event) in
                if let _ = event.element {
                    self.mapView.showsUserLocation = true
                    self.centerOnUserLocation()
                } else {
                    self.mapView.showsUserLocation = false
                }
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension BICHomeViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        switch annotation {
        case is BICContractAnnotation:
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CONTRACT_CELL_REUSE_ID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: CONTRACT_CELL_REUSE_ID)
                annotationView?.canShowCallout = false
                annotationView?.image = #imageLiteral(resourceName: "BICImgContract").resizeTo(width: 64, height: 64)
                annotationView?.centerOffset = CGPoint(x: 0.0, y:-(annotationView!.image!.size.height / 2))
            } else {
                annotationView?.annotation = annotation
            }
        case let stationAnnotation as BICStationAnnotation:
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: STATION_CELL_REUSE_ID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: STATION_CELL_REUSE_ID)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            var image = #imageLiteral(resourceName: "BICImgStation").resizeTo(width: 64, height: 64)
            if let bikes = stationAnnotation.station.bikesCount?.description {
                image = image.drawText(bikes, at: CGPoint(x: 0, y: 5), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
            }
            if let free = stationAnnotation.station.freeCount?.description {
                image = image.drawText(free, at: CGPoint(x: 0, y: 30), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
            }
            annotationView?.image = image
            annotationView?.centerOffset = CGPoint(x: 0, y:-(image.size.height / 2))
        default:
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CLUSTER_CELL_REUSE_ID) as? ClusterAnnotationView
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: CLUSTER_CELL_REUSE_ID, style: .color(UIColor(hex: "#58bc47"), radius: 25))
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard !(view.annotation is MKUserLocation) else {
            return
        }
        showBottomSheet(annotationView: view)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard !(view.annotation is MKUserLocation) else {
            return
        }
        hideBottomSheet(annotationView: self.selectedAnnotationView)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard !preventRegionDidChange else { return preventRegionDidChange = false }
        refreshAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        /*if let contractAnnotation = view.annotation as? BICContractAnnotation, let region = contractAnnotation.contract.region, control == view.rightCalloutAccessoryView {
            self.mapView.setRegion(region, animated: true)
        }*/
    }
}

// MARK: - StoryboardInstantiatable
extension BICHomeViewController: StoryboardInstantiatable {}
