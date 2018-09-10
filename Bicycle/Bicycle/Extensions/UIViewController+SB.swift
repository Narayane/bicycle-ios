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

import Foundation
import UIKit

extension UIViewController {
    
    func createBarButton(image: UIImage, width: Int, height: Int, selector: Selector) -> UIBarButtonItem {
        let iconSize = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
        let iconButton = UIButton(frame: iconSize)
        let resizedImage = image.resizeTo(width: CGFloat(width), height: CGFloat(height)).withRenderingMode(.alwaysTemplate)
        iconButton.setBackgroundImage(resizedImage, for: .normal)
        iconButton.addTarget(self, action: selector, for: .touchUpInside)
        return UIBarButtonItem(customView: iconButton)
    }
}
