//
//  TextStyling.swift
//  Fone
//
//  Created by Bharat Nakum on 24/06/22.
//  Copyright © 2022 Fone.Me. All rights reserved.
//

import Foundation
import UIKit

class TextStyling {
    // This will apply Blue color to secondString parameter. You can see the example in SignIn and SignUp screen.
    static func applyAttributedTextStyle(firstString: String, secondString: String) -> NSMutableAttributedString {
        let strTitle = NSAttributedString(string: (firstString + secondString))
        let attributedString = NSMutableAttributedString(attributedString: strTitle)
        attributedString.addAttributes(
                    [NSAttributedString.Key.foregroundColor: UIColor.blue],
                    range: NSRange.init(location: firstString.count, length: secondString.count)
                )
        return attributedString
    }
}
