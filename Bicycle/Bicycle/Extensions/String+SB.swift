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

import Foundation

extension String {
    
    func boolValue() -> Bool {
        return self == "true"
    }
    
    func concat(with other: String?, separator: String = " ") -> String? {
        let results = [self, other].flatMap {$0}
        guard results.count > 0 else { return nil }
        return results.joined(separator: separator)
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    func firstCharacterUppercased(with locale: Locale?) -> String {
        if let firstCharacter = self.first, self.count > 0 {
            return replacingCharacters(in: startIndex ..< index(after: startIndex), with: String(firstCharacter).uppercased(with: locale))
        }
        return self
    }
    
    func isDecimal() -> Bool {
        return self.range(of: "^\\d+([\\.,]\\d*)?$", options: .regularExpression, range: nil, locale: nil) != nil
    }
}
