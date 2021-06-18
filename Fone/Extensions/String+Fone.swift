//
//  String+Fone.swift
//  Fone
//
//  Created by Thu Le on 18/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import Foundation

extension String {
    var cnicToLink: String {
        if self.starts(with: "fone.me")
            || self.starts(with: "https://fone.me")
            || self.starts(with: "http://fone.me") {
            return self
        }
        return "fone.me/\(self)"
    }
}
