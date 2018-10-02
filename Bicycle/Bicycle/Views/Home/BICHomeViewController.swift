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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        /*clusterContracts.zoomLevel = BICConstants.CLUSTERING_ZOOM_LEVEL_START
        clusterStations.zoomLevel = BICConstants.CLUSTERING_ZOOM_LEVEL_START*/
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
        log.i("touch map")
        hideBottomSheet()
    }
    
    @IBAction func onCenterOnUserLocationButtonTouched(_ sender: UIButton) {
        log.i("click on button: center on user location")
        centerOnUserLocation()
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
            let coordinateRegion: MKCoordinateRegion! = MKCoordinateRegion.init(center: existingUserLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    private func refreshAnnotations() {
        let level = mapView.zoomLevel
        log.d("current zoom level: \(level)")
        if level >= 10 {
            deleteContractsAnnotations()
            self.viewModelHome?.determineCurrentContract(region: self.mapView.region)
        } else {
            self.viewModelHome?.currentContract = nil
            stopTimer()
            //createContractsAnnotations()
            self.viewModelHome?.getAllContracts()
        }
    }
    
    /*private func createContractsAnnotations() {
        queueComputation.async {
            self.annotations = self.viewModelHome?.getAllContracts().map({ (contract) -> BICContractAnnotation in
                let annotation = BICContractAnnotation()
                annotation.coordinate = contract.center
                annotation.title = contract.name
                annotation.region = contract.region
                return annotation
            })
            if let annotations = self.annotations {
                log.v("create \(annotations.count) contract annotations")
                self.queueMain.async {
                    log.v("empty clustering manager")
                    self.clusterStations.reload(mapView: self.mapView)
                    log.v("draw contracts annotations")
                    self.mapView.addAnnotations(annotations)
                }
            }
        }
    }*/
    
    private func deleteContractsAnnotations() {
        let count = self.clusterContracts.annotations.count
        if count > 0 {
            log.v("delete \(count) existing contract annotations")
            self.clusterStations.removeAll()
        }
    }
    
    // MARK: Fileprivate methods
    fileprivate func showBottomSheet() {
        if constraintBottomSheetViewTop.constant == 0 {
            constraintBottomSheetViewTop.constant = bottomSheetView.frame.height
            UIView.animate(withDuration: 0, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    fileprivate func hideBottomSheet() {
        if constraintBottomSheetViewTop.constant > 0 {
            constraintBottomSheetViewTop.constant = 0
            UIView.animate(withDuration: 0, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    fileprivate func initLayout() {
        navigationItem.title = "Bicycle"
        //buttonCenterOnUserLocation.setImage(#imageLiteral(resourceName: "BICIconLocation").resizeTo(width: 30, height: 30), for: .normal)
    }
    
    fileprivate func observeStates() {
        launch {
            viewModelHome?.states.asObservable().observeOn(MainScheduler.instance).subscribe { (rx) in
                guard let state = rx.element else { return }
                log.v("state -> \(String(describing: type(of: state)))")
                switch (state) {
                case is StateShowContracts:
                    //fabContractZoom.visibility = View.INVISIBLE
                    break
                case is StateShowStations:
                    //fabContractZoom.visibility = View.GONE
                    break
                default: break
                }
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
                    self.clusterContracts.removeAll()
                    self.hideBottomSheet()
                    let annotations = event.contracts.map({ (contract) -> BICContractAnnotation in
                        let annotation = BICContractAnnotation()
                        annotation.coordinate = contract.center
                        annotation.title = contract.name
                        annotation.region = contract.region
                        return annotation
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
                    self.hideBottomSheet()
                    let annotations = event.stations.map({ (station) -> BICStationAnnotation in
                        let annotation = BICStationAnnotation()
                        annotation.coordinate = station.coordinate!
                        annotation.title = station.name!
                        annotation.freeCount = station.freeCount
                        annotation.bikesCount = station.bikesCount
                        return annotation
                    })
                    self.clusterStations.add(annotations)
                    self.clusterStations.reload(mapView: self.mapView)
                case is EventFailure:
                    if let currentState = self.viewModelHome?.states.value {
                        switch currentState {
                        case is StateShowContracts:
                            self.clusterContracts.removeAll()
                            self.hideBottomSheet()
                            //TODO: display error message
                        case is StateShowStations:
                            self.clusterStations.removeAll()
                            self.hideBottomSheet()
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
        
        if annotation is BICContractAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CONTRACT_CELL_REUSE_ID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: CONTRACT_CELL_REUSE_ID)
                annotationView?.canShowCallout = false
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                annotationView?.image = #imageLiteral(resourceName: "BICImgContract").resizeTo(width: 64, height: 64)
                annotationView?.centerOffset = CGPoint(x: 0.0, y:-(annotationView!.image!.size.height / 2))
            } else {
                annotationView?.annotation = annotation
            }
        } else if annotation is ClusterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CLUSTER_CELL_REUSE_ID) as? ClusterAnnotationView
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: CLUSTER_CELL_REUSE_ID, style: .color(UIColor(hex: "#58bc47"), radius: 25))
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
        } else {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: STATION_CELL_REUSE_ID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: STATION_CELL_REUSE_ID)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            let stationAnnotation = annotation as! BICStationAnnotation
            var image = #imageLiteral(resourceName: "BICImgStation").resizeTo(width: 64, height: 64)
            if let bikes = stationAnnotation.bikesCount?.description {
                image = image.drawText(bikes, at: CGPoint(x: 0, y: 5), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
            }
            if let free = stationAnnotation.freeCount?.description {
                image = image.drawText(free, at: CGPoint(x: 0, y: 30), font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
            }
            annotationView?.image = image
            annotationView?.centerOffset = CGPoint(x: 0, y:-(image.size.height / 2))
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard !(view.annotation is MKUserLocation) else {
            return
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard !(view.annotation is MKUserLocation) else {
            return
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        log.d("current zoom level: \(mapView.zoomLevel)")
        refreshAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let contractAnnotation = view.annotation as? BICContractAnnotation, let region = contractAnnotation.region, control == view.rightCalloutAccessoryView {
            self.mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - StoryboardInstantiatable
extension BICHomeViewController: StoryboardInstantiatable {}
