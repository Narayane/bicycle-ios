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

extension UINavigationController {
    
    func styleNavigationBar(barTintColor: String?, tintColor: String?) {
        if let barTintColorString = barTintColor, let tintColorString = tintColor {
            styleNavigationBar(barTintColor: UIColor(hex: barTintColorString), tintColor: UIColor(hex: tintColorString))
        }
    }
    
    func styleNavigationBar(barTintColor: UIColor?, tintColor: UIColor?) {
        if let barTintcolor = barTintColor {
            navigationBar.isTranslucent = false
            navigationBar.barTintColor = barTintcolor
            navigationBar.tintColor = tintColor
            if let tintColor = tintColor {
                navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: tintColor]
            }
        }
    }
    
}
