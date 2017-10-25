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

private let CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP = CGFloat(-180)

class BICHomeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, MKLocalSearchCompleterDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonMyLocation: UIButton!
    
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var textFieldDepartureAddress: SearchTextField!
    @IBOutlet weak var buttonDepartureMyLocation: UIButton!
    @IBOutlet weak var indicatorDepartureMyLocation: UIActivityIndicatorView!
    @IBOutlet weak var textFieldDepartureBikeCount: UITextField!
    @IBOutlet weak var textFieldArrivalAddress: SearchTextField!
    @IBOutlet weak var buttonArrivalMyLocation: UIButton!
    @IBOutlet weak var indicatorArrivalMyLocation: UIActivityIndicatorView!
    @IBOutlet weak var textFieldArrivalBikeCount: UITextField!
    @IBOutlet weak var buttonSearch: UIButton!
    @IBOutlet weak var swipeUpGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var swipeDownGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var indicatorSearch: UIActivityIndicatorView!
    @IBOutlet weak var buttonToggleSearchPanel: UIButton!
    
    @IBOutlet weak var constraintSearchViewTop: NSLayoutConstraint!
    
    var viewModel: BICHomeViewModel!
    
    private let disposeBag = DisposeBag()
    
    private var locationManager: CLLocationManager?
    private var userLocation: CLLocation?
    
    private var activeTextField: SearchTextField?
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Bicycle"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Trajet", style: .plain, target: self, action: #selector(BICHomeViewController.onSearchButtonBarTouched(sender:)))
        
        initLayout()
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
    }
    
    // MARK: - UI Events
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        searchCompleter.queryFragment = textField.text!
        buttonSearch.isEnabled = !textFieldDepartureAddress.text!.isEmpty && !textFieldDepartureBikeCount.text!.isEmpty && !textFieldArrivalAddress.text!.isEmpty && !textFieldArrivalBikeCount.text!.isEmpty
    }
    
    @IBAction func onSearchButtonBarTouched(sender: UIBarButtonItem) {
        SBLog.i("click on bar button: search")
        showSearchView()
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
            rotateSearchPanelButtonToggle()
        }
        navigationItem.leftBarButtonItem = nil
    }
    
    private func rotateSearchPanelButtonToggle() {
        UIView.animate(withDuration: 0.25, delay: 0.15, options: .curveEaseInOut, animations: {
            self.buttonToggleSearchPanel.transform = self.buttonToggleSearchPanel.transform.rotated(by: CGFloat(Double.pi))
        }, completion: nil)
    }
    
    private func centerToUserLocation() {
        if let existingUserLocation = userLocation {
            SBLog.i("center to user location")
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
    
    private func initArrivalAddressTextField() {
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
    
    private func initDepartureAddressTextField() {
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
    
    private func initLayout() {
        mapView.delegate = self
        searchCompleter.delegate = self
        constraintSearchViewTop.constant = CONSTANT_SEARCH_VIEW_NORMAL_MARGIN_TOP
        initDepartureAddressTextField()
        textFieldDepartureBikeCount.text = "1"
        textFieldDepartureBikeCount.delegate = self
        textFieldDepartureBikeCount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        initArrivalAddressTextField()
        textFieldArrivalBikeCount.text = "1"
        textFieldArrivalBikeCount.delegate = self
        textFieldArrivalBikeCount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        buttonSearch.setTitle("Rechercher", for: .normal)
        buttonSearch.setTitleColor(UIColor.white, for: .disabled)
        buttonSearch.setBackgroundColor(UIColor.lightGray, for: .disabled)
        //buttonToggleSearchPanel.setImage(#imageLiteral(resourceName: "OBKICArrowDown"), for: .normal)
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        activeTextField?.filterItems(searchResults.map({ (searchCompletion) -> SearchTextFieldItem in
            return SearchTextFieldItem(title: searchCompletion.title, subtitle: searchCompletion.subtitle)
        }))
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
    }
    
    // MARK: - UITextFieldDelegate
    
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
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            SBLog.d("notDetermined")
            buttonMyLocation.isHidden = true
            buttonDepartureMyLocation.isHidden = true
            buttonArrivalMyLocation.isHidden = true
            break;
        case .restricted:
            SBLog.d("restricted")
            buttonMyLocation.isHidden = true
            buttonDepartureMyLocation.isHidden = true
            buttonArrivalMyLocation.isHidden = true
            break;
        case .denied:
            SBLog.d("denied")
            buttonMyLocation.isHidden = true
            buttonDepartureMyLocation.isHidden = true
            buttonArrivalMyLocation.isHidden = true
            //refreshAnnotations()
            break;
        case .authorizedAlways:
            SBLog.d("authorizedAlways")
            buttonMyLocation.isHidden = false
            buttonDepartureMyLocation.isHidden = false
            buttonArrivalMyLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break;
        case .authorizedWhenInUse:
            SBLog.d("authorizedWhenInUse")
            buttonMyLocation.isHidden = false
            buttonDepartureMyLocation.isHidden = false
            buttonArrivalMyLocation.isHidden = false
            locationManager?.startUpdatingLocation()
            break;
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first!
        if let location = userLocation {
            SBLog.d("user location updated: \(location.coordinate.latitude),\(location.coordinate.longitude)")
            mapView.showsUserLocation = true
            locationManager?.stopUpdatingLocation()
            locationManager = nil
            centerToUserLocation()
        } else {
            mapView.showsUserLocation = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        SBLog.e("fail to init user location: \(error.localizedDescription)")
    }

}
