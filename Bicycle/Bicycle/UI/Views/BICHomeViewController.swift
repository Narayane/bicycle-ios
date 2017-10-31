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
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var textFieldDepartureAddress: SearchTextField! {
        didSet {
            textFieldDepartureAddress.placeholder = "Adresse de départ"
            textFieldDepartureAddress.delegate = self
            textFieldDepartureAddress.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            textFieldDepartureAddress.theme.font = UIFont.systemFont(ofSize: textFieldDepartureAddress.font!.pointSize)
            textFieldDepartureAddress.highlightAttributes = [NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: textFieldDepartureAddress.font!.pointSize)]
            textFieldDepartureAddress.theme.bgColor = UIColor.white
            textFieldDepartureAddress.theme.cellHeight = 50
            textFieldDepartureAddress.itemSelectionHandler = { filteredResults, itemPosition in
                let item = filteredResults[itemPosition]
                self.textFieldDepartureAddress.text = item.title.concat(with: item.subtitle)
                self.textFieldDepartureBikeCount.becomeFirstResponder()
            }
        }
    }
    @IBOutlet weak var buttonDepartureUserLocation: UIButton!
    @IBOutlet weak var indicatorDepartureUserLocation: UIActivityIndicatorView!
    @IBOutlet weak var textFieldDepartureBikeCount: UITextField! {
        didSet {
            textFieldDepartureBikeCount.text = "1"
            textFieldDepartureBikeCount.delegate = self
            textFieldDepartureBikeCount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    @IBOutlet weak var textFieldArrivalAddress: SearchTextField! {
        didSet {
            textFieldArrivalAddress.placeholder = "Adresse d'arrivée"
            textFieldArrivalAddress.delegate = self
            textFieldArrivalAddress.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            textFieldArrivalAddress.theme.font = UIFont.systemFont(ofSize: textFieldArrivalAddress.font!.pointSize)
            textFieldArrivalAddress.highlightAttributes = [NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: textFieldArrivalAddress.font!.pointSize)]
            textFieldArrivalAddress.theme.bgColor = UIColor.white
            textFieldArrivalAddress.theme.cellHeight = 50
            textFieldArrivalAddress.itemSelectionHandler = { filteredResults, itemPosition in
                let item = filteredResults[itemPosition]
                self.textFieldArrivalAddress.text = item.title.concat(with: item.subtitle)
                self.textFieldArrivalBikeCount.becomeFirstResponder()
            }
        }
    }
    @IBOutlet weak var buttonArrivalUserLocation: UIButton!
    @IBOutlet weak var indicatorArrivalUserLocation: UIActivityIndicatorView!
    @IBOutlet weak var textFieldArrivalBikeCount: UITextField! {
        didSet {
            textFieldArrivalBikeCount.text = "1"
            textFieldArrivalBikeCount.delegate = self
            textFieldArrivalBikeCount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    @IBOutlet weak var buttonSearch: UIButton! {
        didSet {
            buttonSearch.setTitle("Rechercher", for: .normal)
            buttonSearch.setTitleColor(UIColor.white, for: .disabled)
            buttonSearch.setBackgroundColor(UIColor.lightGray, for: .disabled)
        }
    }
    @IBOutlet weak var swipeUpGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var swipeDownGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var indicatorSearch: UIActivityIndicatorView!
    @IBOutlet weak var buttonToggleSearchPanel: UIButton!
    
    @IBOutlet weak var constraintSearchViewTop: NSLayoutConstraint! {
        didSet {
            constraintSearchViewTop.constant = CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP
        }
    }
    
    var viewModel: BICHomeViewModel!
    
    private let disposeBag = DisposeBag()
    
    private var locationManager: CLLocationManager?
    private var clusteringManager: ClusterManager?
    private var timer: Timer?
    private let queueMain = DispatchQueue.main
    private let queueComputation = DispatchQueue.global(qos: .userInitiated)
    
    private var userLocation: CLLocation?
    private var annotations: [MKAnnotation]?
    
    private var activeTextField: SearchTextField?
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    private var barButtonSearch: UIBarButtonItem?
    
    // MARK: - Constructors
    
    init() {
        super.init(nibName: "BICHomeViewController", bundle: nil)
        viewModel = BICHomeViewModel()
        clusteringManager = ClusterManager()
        //clusteringManager?.zoomLevel = BICConstants.CLUSTERING_ZOOM_LEVEL_START
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Bicycle"
        barButtonSearch = UIBarButtonItem(title: "Trajet", style: .plain, target: self, action: #selector(BICHomeViewController.onSearchButtonBarTouched(sender:)))
        navigationItem.rightBarButtonItem = barButtonSearch
        
        searchCompleter.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        determineUserLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        locationManager = nil
        viewModel = nil
    }
    
    // MARK: UI Events
    
    @IBAction func onMapTouched(_ sender: UITapGestureRecognizer) {
        SBLog.i("touch map")
        hideSearchView()
    }
    
    @IBAction func onArrivalUserLocationButtonTouched(_ sender: UIButton) {
        SBLog.i("click on button: arrival user location")
        
        buttonArrivalUserLocation.isHidden = true
        indicatorArrivalUserLocation.isHidden = false
        
        let geocoder: CLGeocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation!, completionHandler: { (placemarks, error) in
            if let _ = error {
                self.textFieldArrivalAddress.text = String(format: "%f,%f", self.userLocation!.coordinate.latitude, self.userLocation!.coordinate.longitude)
            } else if let placemarks = placemarks, placemarks.count > 0 {
                var text = placemarks[0].name
                text = text?.concat(with: placemarks[0].postalCode, separator: ", ")
                text = text?.concat(with: placemarks[0].locality, separator: " ")
                text = text?.concat(with: placemarks[0].country, separator: ", ")
                SBLog.d("find arrival user location reverse geocoding: \(String(describing: text))")
                self.textFieldArrivalAddress.text = text
                self.textFieldDidChange(self.textFieldArrivalAddress)
            }
            self.indicatorArrivalUserLocation.isHidden = true
            self.buttonArrivalUserLocation.isHidden = false
            self.textFieldArrivalBikeCount.becomeFirstResponder()
        })
    }
    
    @IBAction func onDepartureUserLocationButtonTouched(_ sender: UIButton) {
        SBLog.i("click on button: departure user location")
        
        buttonDepartureUserLocation.isHidden = true
        indicatorDepartureUserLocation.isHidden = false
        
        let geocoder: CLGeocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation!, completionHandler: { (placemarks, error) in
            if let _ = error {
                self.textFieldDepartureAddress.text = String(format: "%f,%f", self.userLocation!.coordinate.latitude, self.userLocation!.coordinate.longitude)
            } else if let placemarks = placemarks, placemarks.count > 0 {
                var text = placemarks[0].name
                text = text?.concat(with: placemarks[0].postalCode, separator: ", ")
                text = text?.concat(with: placemarks[0].locality, separator: " ")
                text = text?.concat(with: placemarks[0].country, separator: ", ")
                SBLog.d("find departure user location reverse geocoding: \(String(describing: text))")
                self.textFieldDepartureAddress.text = text
                self.textFieldDidChange(self.textFieldDepartureAddress)
            }
            self.indicatorDepartureUserLocation.isHidden = true
            self.buttonDepartureUserLocation.isHidden = false
            self.textFieldDepartureBikeCount.becomeFirstResponder()
        })
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        searchCompleter.queryFragment = textField.text!
        buttonSearch.isEnabled = !textFieldDepartureAddress.text!.isEmpty && !textFieldDepartureBikeCount.text!.isEmpty && !textFieldArrivalAddress.text!.isEmpty && !textFieldArrivalBikeCount.text!.isEmpty
    }
    
    @IBAction func onCenterOnUserLocationButtonTouched(_ sender: UIButton) {
        SBLog.i("click on button: center on user location")
        centerOnUserLocation()
    }

    @IBAction func onSearchViewSwipeUpInvoked(_ sender: UISwipeGestureRecognizer) {
        SBLog.i("swipe up on: search view")
        //if state == STATE_NORMAL {
            hideSearchView()
        /*} else if state == STATE_RIDE {
            collapseSearchView()
        }*/
    }
    
    @IBAction func onSearchViewSwipeDownInvoked(_ sender: UISwipeGestureRecognizer) {
        SBLog.i("swipe down on: search view")
        //expandSearchView()
    }
    
    @IBAction func onSearchButtonBarTouched(sender: UIBarButtonItem) {
        SBLog.i("click on bar button: search")
        showSearchView()
    }
    
    @IBAction func onHideSearchViewButtonTouched(sender: UIButton) {
        //if state == STATE_NORMAL {
            SBLog.i("click on button: hide search view")
            hideSearchView()
        /*} else if state == STATE_RIDE {
            if constraintSearchViewTop.constant == 0 {
                collapseSearchView()
            } else if constraintSearchViewTop.constant == CONSTANT_SEARCH_VIEW_RIDE_MARGIN_TOP {
                expandSearchView()
            }
        }*/
    }
    
    // MARK: Timer
    
    private func stopTimer() {
        if timer != nil {
            SBLog.d("stop timer")
        }
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimer() {
        if timer == nil {
            SBLog.d("start timer")
            timer = Timer.scheduledTimer(withTimeInterval: BICConstants.TIME_BEFORE_REFRESH_DATA_IN_SECONDS, repeats: true, block: { _ in
                SBLog.d("timer fired: \(String(describing: self.timer?.fireDate.format(format: "hh:mm:ss")))")
                self.refreshContractData(self.viewModel.currentContract!)
            })
        }
    }
    
    // MARK: Contracts
    
    private func refreshContractData(_ contract: BICContract) {
        SBLog.d(String(format: "refresh contract data: %@ (%@)", contract.name!, contract.provider!.tag))
        BICStationService.shared.loadStationsFor(contract: contract, success: { (stations) in
            self.createAnnotationsFor(stations: stations)
        }, error: {
            self.queueMain.async {
                Toast.init(text: NSLocalizedString("bic_dialogs_message_stations_data_not_loaded", comment: ""), delay: 0, duration: 5).show()
            }
        })
    }
    
    private func determineCurrentContract() {
        
        var invalidateCurrentContract = false
        var hasChanged = false
        
        let visibleRegionCenter = mapView.region.center
        
        if let region = viewModel.currentContract?.region, !visibleRegionCenter.isIncludedIn(region: region) {
            invalidateCurrentContract = true
            hasChanged = true
            viewModel.currentContract = nil
        }
        
        if (viewModel.currentContract == nil || invalidateCurrentContract) {
            viewModel.currentContract = BICContractService.shared.getContract(for: visibleRegionCenter)
            hasChanged = hasChanged || viewModel.currentContract != nil
        }
        
        if let current = viewModel.currentContract {
            if hasChanged {
                stopTimer()
                refreshContractData(current)
                startTimer()
            } else {
                SBLog.v("current contract has not changed")
                self.queueMain.async {
                    self.clusteringManager?.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
                }
            }
        } else {
            SBLog.d("current region is out of contracts covers")
            stopTimer()
        }
    }
    
    // MARK: Annotations
    
    private func refreshAnnotations() {
        if mapView.zoomLevel >= BICConstants.CLUSTERING_ZOOM_LEVEL_STOP {
            determineCurrentContract()
        } else {
            viewModel.currentContract = nil
            stopTimer()
            // use contracts data
            createAnnotationsFor(contracts: BICContractService.shared.allContracts)
        }
    }
    
    private func createAnnotationsFor(stations: [BICStation]) {
        queueComputation.async {
            if let annotations = self.annotations as? [BICContractAnnotation] {
                SBLog.v("remove \(annotations.count) existing contract annotations")
                self.queueMain.async {
                    self.mapView.removeAnnotations(annotations)
                }
                self.annotations = nil
            } else if let annotations = self.annotations, let count = self.clusteringManager?.annotations.count, count > 0 {
                SBLog.v("remove \(annotations.count) existing station annotations")
                self.clusteringManager?.removeAll()
                self.annotations = nil
            }
            self.annotations = stations.map({ (station) -> BICStationAnnotation in
                let annotation = BICStationAnnotation()
                annotation.coordinate = station.coordinate!
                annotation.title = station.name!
                annotation.freeCount = station.freeCount
                annotation.bikesCount = station.bikesCount
                return annotation
            })
            if let annotations = self.annotations {
                SBLog.v("create \(annotations.count) station annotations")
                self.clusteringManager?.add(annotations)
            }
            self.queueMain.async {
                self.clusteringManager?.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
            }
        }
    }
    
    private func createAnnotationsFor(contracts: [BICContract]) {
        queueComputation.async {
            if let count = self.clusteringManager?.annotations.count, count > 0 {
                if let annotations = self.annotations {
                    SBLog.v("remove \(annotations.count) existing station annotations")
                    self.clusteringManager?.removeAll()
                    self.annotations = nil
                }
                self.annotations = contracts.map({ (contract) -> BICContractAnnotation in
                    let annotation = BICContractAnnotation()
                    annotation.coordinate = contract.center!
                    annotation.title = contract.name!
                    annotation.region = contract.region
                    return annotation
                })
                if let annotations = self.annotations {
                    SBLog.v("create \(annotations.count) contract annotations")
                    self.queueMain.async {
                        SBLog.v("empty clustering manager")
                        self.clusteringManager?.reload(self.mapView, visibleMapRect: self.mapView.visibleMapRect)
                        SBLog.v("draw contracts annotations")
                        self.mapView.addAnnotations(annotations)
                    }
                }
            } else if let annotations = self.annotations, self.mapView.annotations.count < 2 {
                // case when stations data was not retrieved previously
                SBLog.v("create \(annotations.count) contract annotations")
                self.queueMain.async {
                    SBLog.v("draw contracts annotations")
                    self.mapView.addAnnotations(annotations)
                }
            } else if self.mapView.annotations.count == 0 {
                // user has denied location update
                self.annotations = contracts.map({ (contract) -> BICContractAnnotation in
                    let annotation = BICContractAnnotation()
                    annotation.coordinate = contract.center!
                    annotation.title = contract.name!
                    annotation.region = contract.region
                    return annotation
                })
                SBLog.v("create \(self.annotations!.count) contract annotations")
                self.queueMain.async {
                    SBLog.v("draw contracts annotations")
                    self.mapView.addAnnotations(self.annotations!)
                }
            }
        }
    }
    
    // MARK: Search View
    
    private func disableSearchView() {
        textFieldDepartureAddress.isEnabled = false
        textFieldDepartureBikeCount.isEnabled = false
        textFieldArrivalAddress.isEnabled = false
        textFieldArrivalBikeCount.isEnabled = false
        buttonSearch.isHidden = true
        indicatorSearch.isHidden = false
        swipeUpGestureRecognizer.isEnabled = false
        buttonToggleSearchPanel.isEnabled = false
    }
    
    private func enableSearchView() {
        textFieldDepartureAddress.isEnabled = true
        textFieldDepartureBikeCount.isEnabled = true
        textFieldArrivalAddress.isEnabled = true
        textFieldArrivalBikeCount.isEnabled = true
        buttonSearch.isHidden = false
        indicatorSearch.isHidden = true
        swipeUpGestureRecognizer.isEnabled = true
        buttonToggleSearchPanel.isEnabled = true
    }
    
    private func hideSearchView() {
        if constraintSearchViewTop.constant == 0 {
            SBLog.d("hide search view")
            rotateSearchPanelButtonToggle(withDuration: 0.25, delay: 0)
            constraintSearchViewTop.constant = CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP
            UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            navigationItem.rightBarButtonItem = barButtonSearch
            view.endEditing(true)
        }
    }
    
    private func showSearchView() {
        if constraintSearchViewTop.constant == CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP {
            SBLog.d("show search view")
            constraintSearchViewTop.constant = 0
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (_) in
                self.textFieldDepartureAddress.becomeFirstResponder()
            })
            rotateSearchPanelButtonToggle(withDuration: 0.25, delay: 0.1)
        }
        navigationItem.rightBarButtonItem = nil
    }
    
    private func rotateSearchPanelButtonToggle(withDuration: TimeInterval, delay: TimeInterval) {
        UIView.animate(withDuration: withDuration, delay: delay, options: .curveEaseInOut, animations: {
            self.buttonToggleSearchPanel.transform = self.buttonToggleSearchPanel.transform.rotated(by: CGFloat(Double.pi))
        }, completion: nil)
    }
    
    // MARK: User Location
    
    private func centerOnUserLocation() {
        if let existingUserLocation = userLocation {
            SBLog.i("center on user location")
            let coordinateRegion: MKCoordinateRegion! = MKCoordinateRegionMakeWithDistance(existingUserLocation.coordinate, 1000, 1000)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    private func determineUserLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
}

// MARK: -

extension BICHomeViewController: MKLocalSearchCompleterDelegate {
    
    // MARK: MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        activeTextField?.filterItems(searchResults.map({ (searchCompletion) -> SearchTextFieldItem in
            return SearchTextFieldItem(title: searchCompletion.title, subtitle: searchCompletion.subtitle)
        }))
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
}

// MARK: -

extension BICHomeViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == textFieldDepartureBikeCount || textField == textFieldArrivalBikeCount {
            let newText = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            if newText.isEmpty {
                return true
            }
            else if let intValue = Int(newText), intValue < 100 {
                return true
            }
            return false
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField is SearchTextField {
            activeTextField = textField as? SearchTextField
        } else {
            activeTextField = nil
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case textFieldDepartureAddress:
            textFieldDepartureBikeCount.becomeFirstResponder()
            break
        case textFieldDepartureBikeCount:
            textFieldArrivalAddress.becomeFirstResponder()
            break
        case textFieldArrivalAddress:
            textFieldArrivalBikeCount.becomeFirstResponder()
            break
        default:
            //validateRideData()
            break
        }
        return false
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
                annotationView?.image = #imageLiteral(resourceName: "BICImgContract").resizeTo(width: 51, height: 62)
                annotationView?.centerOffset = CGPoint(x: 0.0, y:-(annotationView!.image!.size.height / 2))
            } else {
                annotationView?.annotation = annotation
            }
        } else if annotation is ClusterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: CLUSTER_CELL_REUSE_ID) as? ClusterAnnotationView
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: CLUSTER_CELL_REUSE_ID, type: .color(UIColor(hex: "#58bc47"), radius: 25))
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
            var image = #imageLiteral(resourceName: "BICImgStation").resizeTo(width: 51, height: 62)
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
        SBLog.d("current zoom level: \(mapView.zoomLevel)")
        refreshAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let contractAnnotation = view.annotation as? BICContractAnnotation, let region = contractAnnotation.region, control == view.rightCalloutAccessoryView {
            self.mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: -

extension BICHomeViewController: CLLocationManagerDelegate {
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            SBLog.d("notDetermined")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            break;
        case .restricted:
            SBLog.d("restricted")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            break;
        case .denied:
            SBLog.d("denied")
            buttonCenterOnUserLocation.isHidden = true
            buttonDepartureUserLocation.isHidden = true
            buttonArrivalUserLocation.isHidden = true
            refreshAnnotations()
            break;
        case .authorizedAlways:
            SBLog.d("authorizedAlways")
            buttonCenterOnUserLocation.isHidden = false
            buttonDepartureUserLocation.isHidden = false
            buttonArrivalUserLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break;
        case .authorizedWhenInUse:
            SBLog.d("authorizedWhenInUse")
            buttonCenterOnUserLocation.isHidden = false
            buttonDepartureUserLocation.isHidden = false
            buttonArrivalUserLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break;
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first!
        if let location = userLocation {
            SBLog.d("user location updated to \(location.coordinate.latitude),\(location.coordinate.longitude)")
            mapView.showsUserLocation = true
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            centerOnUserLocation()
        } else {
            mapView.showsUserLocation = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        SBLog.e("fail to determine user location: \(error.localizedDescription)")
    }
}
