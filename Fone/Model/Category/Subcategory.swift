//
//  Skill.swift
//  TTGTagSwiftExample
//
//  Created by Apple on 2/1/23.
//

import UIKit

class Subcategory: Decodable {
    var id: Int
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}
