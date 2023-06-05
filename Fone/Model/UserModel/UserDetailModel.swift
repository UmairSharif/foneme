//
//  UserDetailModel.swift
//  Fone
//
//  Created by Jahan on 7/23/20.
//  Copyright © 2020 Optechno. All rights reserved.
//

import SwiftyJSON
import UIKit

struct UserDetailModel: Codable {

    var cnic: String!
    var contactFT: String!
    var contactVT: String!
    var countryCode: String!
    var email: String!
    var fatherName: String!
    var imageUrl: String!
    var mobileNumberWithoutCode: String!
    var name: String!
    var phoneNumber: String!
    var statusCode: String!
    var userId: String!
    var aboutme: String!
    var profession: String!
    var location: String!
    var socialLinks: [SocialLink]!
    
    var uniqueContact: String {
        if let mobile = phoneNumber, !phoneNumber.isEmpty {
            return mobile
        }
        if let email = email, !email.isEmpty {
            return email
        }
        return ""
    }
    
    /**
     * Instantiate the instance using the passed json values to set the properties values
     */
    init(fromJson json: JSON!) {
        if json.isEmpty {
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

        if let dict = json["AboutMe"].dictionaryObject
        {
            aboutme = dict["AboutMe"] as? String ?? ""
            location = ""
            if let str = dict["Address"] as? String, str != "null"
            {
                location = dict["Address"] as? String ?? ""
            }
            profession = dict["Profession"] as? String ?? ""
            
            if let socialLinkDicts = dict["UserAboutMeLink"] as? [[String: Any]] {
                socialLinks = []
                socialLinkDicts.forEach { item in
                    socialLinks.append(SocialLink(dict: item))
                }
            } else {
                socialLinks = []
            }
        } else {
            socialLinks = []
        }
    }
}

struct SocialLink: Codable {
    let id: Int
    let name: String
    let url: String
    
    init(dict: [String: Any]) {
        id = dict["Id"] as? Int ?? 0
        name = dict["Name"] as? String ?? ""
        url = dict["SocialLink"] as? String ?? ""
    }
    
    init(id: Int, name: String, link: String) {
        self.id = id
        self.name = name
        self.url = link
    }
}
