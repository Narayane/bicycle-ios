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

extension AppDelegate {
    
    func styleStatusBar(hexaBackgroundColor: String?) {
        if let hexaBackgroundColor = hexaBackgroundColor {
            styleStatusBar(backgroundColor: UIColor(hex: hexaBackgroundColor))
        }
    }
    
    func styleStatusBar(backgroundColor: UIColor?) {
        if let backgroundColor = backgroundColor, let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView, statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
            statusBar.backgroundColor = backgroundColor
        }
    }
}
