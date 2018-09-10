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
import SearchTextField
import RxCocoa
import RxSwift
import Cluster
import Toaster

private let CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP = CGFloat(-180)
private let STATION_CELL_REUSE_ID = "station_marker"
private let CLUSTER_CELL_REUSE_ID = "cluster_marker"
private let CONTRACT_CELL_REUSE_ID = "contract_marker"

class BICHomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonCenterOnUserLocation: UIButton!
    
    var viewModelMap: BICMapViewModel
    var viewModelHome: BICHomeViewModel
    
    private let disposeBag = DisposeBag()
    
    private var clusteringManager: ClusterManager
    private var timer: Timer?
    private let queueMain = DispatchQueue.main
    private let queueComputation = DispatchQueue.global(qos: .userInitiated)
    
    private var annotations: [MKAnnotation]?
    
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    
    // MARK: - Constructors
    
    init() {
        self.viewModelMap = BICMapViewModel()
        self.viewModelHome = BICHomeViewModel(contractService: BICContractService())
        self.clusteringManager = ClusterManager()
        super.init(nibName: "BICHomeViewController", bundle: nil)
        //clusteringManager?.zoomLevel = BICConstants.CLUSTERING_ZOOM_LEVEL_START
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.viewModelMap = BICMapViewModel()
        self.viewModelHome = BICHomeViewModel(contractService: BICContractService())
        self.clusteringManager = ClusterManager()
        super.init(coder: aDecoder)
    }
    
    // MARK: - Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Bicycle"
        //buttonCenterOnUserLocation.setImage(#imageLiteral(resourceName: "BICIconLocation").resizeTo(width: 30, height: 30), for: .normal)
        
        viewModelHome.hasCurrentContractChanged.asObservable().subscribe { (event) in
            if let hasChanged = event.element!, !hasChanged {
                log.v("current contract has not changed")
                self.queueMain.async {
                    self.clusteringManager.reload(mapView: self.mapView)
                }
            }
        }.disposed(by: self.disposeBag)
        viewModelHome.currentContract.asObservable().subscribe { (event) in
            if let contract = event.element! {
                self.stopTimer()
                self.viewModelHome.refreshContractStations(contract)
                self.startTimer()
            } else {
                log.d("current region is out of contracts covers")
                self.stopTimer()
            }
        }.disposed(by: self.disposeBag)
        viewModelHome.currentStations.asObservable().subscribe { (event) in
            if let annotations = self.annotations {
                self.queueMain.async {
                    self.mapView.removeAnnotations(annotations)
                }
                self.annotations = nil
                self.clusteringManager.removeAll()
            }
            self.annotations = event.element!?.map({ (station) -> BICStationAnnotation in
                let annotation = BICStationAnnotation()
                annotation.coordinate = station.coordinate!
                annotation.title = station.name!
                annotation.freeCount = station.freeCount
                annotation.bikesCount = station.bikesCount
                return annotation
            })
            guard let annotations = self.annotations else { return }
            self.clusteringManager.add(annotations)
            self.queueMain.async {
                self.clusteringManager.reload(mapView: self.mapView)
            }
        }.disposed(by: self.disposeBag)
        viewModelMap.userLocation.asObservable().subscribe { (event) in
            if let _ = event.element {
                self.mapView.showsUserLocation = true
                self.centerOnUserLocation()
            } else {
                self.mapView.showsUserLocation = false
            }
        }.disposed(by: disposeBag)
        viewModelMap.isLocationAuthorizationDenied.asDriver().drive(buttonCenterOnUserLocation.rx.isHidden).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModelMap.determineUserLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI Events
    
    @IBAction func onMapTouched(_ sender: UITapGestureRecognizer) {
        log.i("touch map")
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
                if let current = self.viewModelHome.currentContract.value {
                    self.viewModelHome.refreshContractStations(current)
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
        if let existingUserLocation = viewModelMap.userLocation.value {
            log.i("center on user location")
            let coordinateRegion: MKCoordinateRegion! = MKCoordinateRegionMakeWithDistance(existingUserLocation.coordinate, 1000, 1000)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    private func refreshAnnotations() {
        let level = mapView.zoomLevel
        log.d("current zoom level: \(level)")
        if level >= 10 {
            self.deleteContractsAnnotations()
            self.viewModelHome.determineCurrentContract(region: self.mapView.region)
        } else {
            self.viewModelHome.currentContract.value = nil
            stopTimer()
            createContractsAnnotations()
        }
    }
    
    private func createContractsAnnotations() {
        queueComputation.async {
            self.annotations = self.viewModelHome.getAllContracts().map({ (contract) -> BICContractAnnotation in
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
                    self.clusteringManager.reload(mapView: self.mapView)
                    log.v("draw contracts annotations")
                    self.mapView.addAnnotations(annotations)
                }
            }
        }
    }
    
    private func deleteContractsAnnotations() {
        queueComputation.async {
            let count = self.clusteringManager.annotations.count
            if count > 0 {
                if let annotations = self.annotations {
                    log.v("remove \(annotations.count) existing station annotations")
                    self.clusteringManager.removeAll()
                    self.annotations = nil
                }
            }
        }
    }
}

// MARK: -

extension BICHomeViewController: MKMapViewDelegate {
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if annotation is BICContractAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CONTRACT_CELL_REUSE_ID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: CONTRACT_CELL_REUSE_ID)
                annotationView?.canShowCallout = true
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
                annotationView?.canShowCallout = true
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

// MARK: -

/*extension BICHomeViewController: CLLocationManagerDelegate {
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            log.d("notDetermined")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            break
        case .restricted:
            log.d("restricted")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            break
        case .denied:
            log.d("denied")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            refreshAnnotations()
            break
        case .authorizedAlways:
            log.d("authorizedAlways")
            buttonCenterOnUserLocation.isHidden = false
            buttonDepartureUserLocation.isHidden = false
            buttonArrivalUserLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break
        case .authorizedWhenInUse:
            log.d("authorizedWhenInUse")
            buttonCenterOnUserLocation.isHidden = false
            buttonDepartureUserLocation.isHidden = false
            buttonArrivalUserLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first!
        if let location = userLocation {
            log.d("user location updated to \(location.coordinate.latitude),\(location.coordinate.longitude)")
            mapView.showsUserLocation = true
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            centerOnUserLocation()
        } else {
            mapView.showsUserLocation = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.e("fail to determine user location: \(error.localizedDescription)")
    }
}*/
