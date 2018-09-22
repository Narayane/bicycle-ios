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
import Dip_UI

class BICSplashViewController: UIViewController {

    @IBOutlet weak var labelCatching: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    
    var viewModel: BICSplashViewModel?
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        observeStates()
        observeEvents()
        viewModel?.loadConfig()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Fileprivate methods
    
    fileprivate func initUI() {
        labelCatching.text = "bic_app_catching".localized()
        labelTitle.text = ""
        labelCatching.text = ""
    }
    
    fileprivate func observeStates() {
        launch {
            viewModel?.states.asObservable().observeOn(MainScheduler.instance).subscribe({ (rx) in
                guard let state = rx.element else { return }
                log.v("state -> \(String(describing: type(of: state)))")
                switch (state) {
                case is StateSplashConfig:
                    self.labelTitle.text = "bic_messages_info_init".localized()
                case is StateSplashContracts:
                    self.labelTitle.text = "bic_messages_info_config".localized()
                default: break
                }
            })
        }
    }
    
    fileprivate func observeEvents() {
        launch {
            viewModel?.events.asObservable().observeOn(MainScheduler.instance).subscribe({ (rx) in
                guard let event = rx.element else { return }
                log.v("event -> \(String(describing: type(of: event)))")
                switch (event) {
                case is EventSplashConfigLoaded, is EventSplashLoadConfigFailed:
                    self.viewModel?.loadAllContracts()
                case is EventSplashCheckContracts:
                    self.labelSubtitle.text = "bic_messages_info_check_contracts_data_version".localized()
                case is EventSplashAvailableContracts:
                    guard let event = event as? EventSplashAvailableContracts else { return }
                    //i(crashReport.logMessage("[INFO]", "load $count contracts"))
                    log.i("load \(event.count) contracts")
                    self.labelSubtitle.text = String.localizedStringWithFormat("bic_messages_info_contracts_loaded".localized(), event.count)
                    self.viewModel?.requestDataSendingPermissions()
                case is EventSplashRequestDataPermissions:
                    guard let event = event as? EventSplashRequestDataPermissions else { return }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
                        var debug = false
                        #if DEBUG
                        debug = true
                        #endif
                        if event.needed || debug {
                            //startActivity(BICDataPermissionsActivity.getIntent(this@BICSplashActivity))
                        } else {
                            //startActivity(BICHomeActivity.getIntent(this@BICSplashActivity))
                        }
                    })
                default: break
                }
            })
        }
    }
}

//MARK: - StoryboardInstantiatable
extension BICSplashViewController: StoryboardInstantiatable {}
