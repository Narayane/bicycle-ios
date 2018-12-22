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

import UIKit
import RxCocoa
import RxSwift
import Dip

class BICDataPermissionsViewController: UIViewController {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDataWarning: UILabel!
    @IBOutlet weak var labelCrashDataText: UILabel!
    @IBOutlet weak var labelCrashDataSwitch: UILabel!
    @IBOutlet weak var switchAllowCrashDataSending: UISwitch!
    @IBOutlet weak var labelUseDataText: UILabel!
    @IBOutlet weak var labelUseDataSwitch: UILabel!
    @IBOutlet weak var switchAllowUseDataSending: UISwitch!
    @IBOutlet weak var labelDataPermissionsWarning: UILabel!
    @IBOutlet weak var buttonValidate: UIButton!
    
    var viewModel: BICOnboardingViewModel!
    var analytics: SBAnalytics!
    var crashReport: SBCrashReport!

    override func viewDidLoad() {
        super.viewDidLoad()
        initLayout()
        observeEvents()
        viewModel.loadDataSendingPermissions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UI events
    @IBAction func buttonValidatedidTouch(_ sender: UIButton) {
        log.i("set initial data sending permissions: crash (\(switchAllowCrashDataSending.isOn)), use (\(switchAllowUseDataSending.isOn))")
        viewModel.saveDataSendingPermissions(allowCrashDataSending: switchAllowCrashDataSending.isOn, allowUseDataSending: switchAllowUseDataSending.isOn)
    }
    
    // MARK: Fileprivate methods
    fileprivate func initLayout() {
        labelTitle.text = "bic_onboarding_screen_title".localized()
        labelDataWarning.text = "bic_onboarding_screen_personal_data".localized()
        labelCrashDataText.text = "bic_onboarding_screen_crash_data_desc".localized()
        labelCrashDataSwitch.text = "bic_onboarding_screen_crash_data_label".localized()
        labelUseDataText.text = "bic_onboarding_screen_use_data_desc".localized()
        labelUseDataSwitch.text = "bic_onboarding_screen_use_data_label".localized()
        labelDataPermissionsWarning.text = "bic_onboarding_screen_warning".localized()
        buttonValidate.setTitle("bic_actions_validate_choices".localized(), for: .normal)
    }
    
    fileprivate func observeEvents() {
        launch {
            viewModel.events.asObservable().observeOn(MainScheduler.instance).subscribe({ (rx) in
                guard let event = rx.element else { return }
                log.v("event -> \(String(describing: type(of: event)))")
                switch (event) {
                case is EventDataSendingPermissionsLoaded:
                    guard let event = event as? EventDataSendingPermissionsLoaded else { return }
                    self.switchAllowUseDataSending.setOn(event.allowCrashDataSending, animated: false)
                    self.switchAllowUseDataSending.setOn(event.allowUseDataSending, animated: false)
                case is EventDataSendingPermissionsSet:
                    DispatchQueue.main.async {
                        let viewController = BICHomeViewController()
                        let navigationController = UINavigationController(rootViewController: viewController)
                        let primaryColor = UIColor(hex: (Bundle.main.object(forInfoDictionaryKey: "BICPrimaryColor") as? String)!)
                        navigationController.styleNavigationBar(barTintColor: primaryColor, tintColor: UIColor.white)
                        navigationController.modalTransitionStyle = .crossDissolve
                        self.present(navigationController, animated: true, completion: nil)
                    }
                default: break
                }
            })
        }
    }
}

//MARK: - StoryboardInstantiatable
extension BICDataPermissionsViewController: StoryboardInstantiatable {}
