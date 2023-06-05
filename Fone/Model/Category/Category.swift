//
//  Category.swift
//  TTGTagSwiftExample
//
//  Created by Apple on 2/1/23.
//

import UIKit

class Category: Decodable {
    var id: Int
    var name: String
    var subcategories: [Subcategory]
    
    init(id: Int, name: String, subcategories: [Subcategory]) {
        self.id = id
        self.name = name
        self.subcategories = subcategories
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "CategoryId"
        case name = "CategoryName"
        case subcategories = "Subcategories"
    }
}
