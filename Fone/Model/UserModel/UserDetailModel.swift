//
//  UserDetailModel.swift
//  Fone
//
//  Created by Jahan on 7/23/20.
//  Copyright © 2020 Optechno. All rights reserved.
//

import SwiftyJSON
import UIKit

struct UserDetailModel : Codable {
    
    var cnic : String!
    var contactFT : String!
    var contactVT : String!
    var countryCode : String!
    var email : String!
    var fatherName : String!
    var imageUrl : String!
    var mobileNumberWithoutCode : String!
    var name : String!
    var phoneNumber : String!
    var statusCode : String!
    var userId : String!

    /**
     * Instantiate the instance using the passed json values to set the properties values
     */
    init(fromJson json: JSON!){
        if json.isEmpty{
            return
        }
        var ContactsCnic = json["Address"].stringValue
        if ContactsCnic.isEmpty {
            ContactsCnic = json["ContactCNIC"].stringValue
        }
        cnic = ContactsCnic

        
        
        contactFT = json["ContactFT"].stringValue
        contactVT = json["ContactVT"].stringValue
        countryCode = json["CountryCode"].stringValue
        email = json["Email"].stringValue
        fatherName = json["FatherName"].stringValue
        imageUrl = json["ImageUrl"].stringValue
        mobileNumberWithoutCode = json["MobileNumberWithoutCode"].stringValue
        name = json["Name"].stringValue
        phoneNumber = json["PhoneNumber"].stringValue
        statusCode = json["StatusCode"].stringValue
        userId = json["UserId"].stringValue
    }


}
