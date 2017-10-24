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

extension UIColor {
    
    public convenience init(hex: String) {
        
        var stringValue: String = hex.trim().uppercased()
        
        if (stringValue.hasPrefix("#")) {
            stringValue.remove(at: stringValue.startIndex)
        }
        
        if ((stringValue.characters.count) == 6) {
            
            var rgbValue:UInt32 = 0
            Scanner(string: stringValue).scanHexInt32(&rgbValue)
            
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0)
            )
        } else if ((stringValue.characters.count) == 8) {
            
            // deal with alpha component
            
            var argbValue:UInt32 = 0
            Scanner(string: stringValue).scanHexInt32(&argbValue)
            
            self.init(
                red: CGFloat((argbValue & 0x00FF0000) >> 16) / 255.0,
                green: CGFloat((argbValue & 0x0000FF00) >> 8) / 255.0,
                blue: CGFloat(argbValue & 0x000000FF) / 255.0,
                alpha: CGFloat((argbValue & 0xFF000000) >> 24) / 255.0
            )
        } else {
            self.init()
        }
    }
}
