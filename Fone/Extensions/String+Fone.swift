//
//  String+Fone.swift
//  Fone
//
//  Created by Thu Le on 18/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var cnicToLink: String {
        if self.starts(with: "fone.me")
            || self.starts(with: "https://fone.me")
            || self.starts(with: "http://fone.me") {
            return self
        }
        return "fone.me/\(self)"
    }
    
    var isValidFoneId: Bool {
        if isEmpty {
            return false
        }
        if contains(".") || contains(" ") {
            return false
        }
        return "https://fone.me/\(self)".isValidUrl
    }
    
    var isValidPublicGroupLink: Bool {
        if isEmpty {
            return false
        }
        if contains(".") || contains(" ") {
            return false
        }
        return "https://fone.me/g/\(self)".isValidUrl
    }
    
    var isValidUrl: Bool {
        guard let url = URL(string: self)
            else { return false }

        if !UIApplication.shared.canOpenURL(url) { return false }

        let regEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
        return predicate.evaluate(with: self)
    }
    
    func comparePhoneNumber(number: String?) -> Bool {
        guard !self.isEmpty, let number = number, !number.isEmpty else {
            return false
        }
        
        let firstNum = self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        let secondNum = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        return firstNum.compare(secondNum) == .orderedSame
    }
}
