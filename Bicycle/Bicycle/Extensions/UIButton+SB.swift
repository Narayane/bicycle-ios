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
import ObjectiveC

var cornerRadiusHandle: UInt8 = 0
var normalColorHandle: UInt8 = 0
var disabledColorHandle: UInt8 = 0
var highlightedColorHandle: UInt8 = 0
var selectedColorHandle: UInt8 = 0

extension UIButton {
    
    @IBInspectable var bgCornerRadius: CGFloat {
        get {
            if let cornerRadius = objc_getAssociatedObject(self, &cornerRadiusHandle) as? CGFloat {
                return cornerRadius
            }
            return 0
        }
        set {
            let cornerRadius = newValue
            self.layer.cornerRadius = cornerRadius
            objc_setAssociatedObject(self, &cornerRadiusHandle, Int(cornerRadius), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @IBInspectable var bgNormalColor: UIColor? {
        get {
            if let color = objc_getAssociatedObject(self, &normalColorHandle) as? UIColor {
                return color
            }
            return nil
        }
        set {
            if let color = newValue {
                self.setBackgroundColor(color, for: .normal)
                objc_setAssociatedObject(self, &normalColorHandle, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            } else {
                self.setBackgroundImage(nil, for: .normal)
                objc_setAssociatedObject(self, &normalColorHandle, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            }
        }
    }
    
    @IBInspectable var bgDisabledColor: UIColor? {
        get {
            if let color = objc_getAssociatedObject(self, &disabledColorHandle) as? UIColor {
                return color
            }
            return nil
        }
        set {
            if let color = newValue {
                self.setBackgroundColor(color, for: .disabled)
                objc_setAssociatedObject(self, &disabledColorHandle, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            } else {
                self.setBackgroundImage(nil, for: .disabled)
                objc_setAssociatedObject(self, &disabledColorHandle, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            }
        }
    }
    
    @IBInspectable var bgHighlightedColor: UIColor? {
        get {
            if let color = objc_getAssociatedObject(self, &highlightedColorHandle) as? UIColor {
                return color
            }
            return nil
        }
        set {
            if let color = newValue {
                self.setBackgroundColor(color, for: .highlighted)
                objc_setAssociatedObject(self, &highlightedColorHandle, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            } else {
                self.setBackgroundImage(nil, for: .highlighted)
                objc_setAssociatedObject(self, &highlightedColorHandle, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    @IBInspectable
    var bgSelectedColor: UIColor? {
        get {
            if let color = objc_getAssociatedObject(self, &selectedColorHandle) as? UIColor {
                return color
            }
            return nil
        }
        set {
            if let color = newValue {
                self.setBackgroundColor(color, for: .selected)
                objc_setAssociatedObject(self, &selectedColorHandle, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            } else {
                self.setBackgroundImage(nil, for: .selected)
                objc_setAssociatedObject(self, &selectedColorHandle, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    func setBackgroundColor(_ color: UIColor, for state: UIControlState) {
        if let image = self.image(from: color) {
            if self.bgCornerRadius == 0.0 {
                setBackgroundImage(image, for: state)
                return
            }
            
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
            
            UIBezierPath(roundedRect: bounds, cornerRadius: self.bgCornerRadius).addClip()
            image.draw(in: bounds)
            let clippedBackgroundImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            setBackgroundImage(clippedBackgroundImage, for: state)
        }
    }
    
    private func image(from color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), true, 0.0)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return image
    }
}

