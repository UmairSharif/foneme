//
//  User.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import Foundation


class User: Codable {
    
    var userId : String?
    var name : String?
    var email : String?
    var address : String?
    var mobile : String?
    var userImage : String?
    var numberWithOutCode : String?
    var coutryCode : String?
    var aboutme : String?
    var profession : String?
    var url: String?
    var ContactCNIC: String?
    
    // Internal value use to seperate login type
    var isSocialLogin:Bool? = false
    
    var uniqueContact: String {
        if let mobile = mobile, !mobile.isEmpty {
            return mobile
        }
        if let email = email, !email.isEmpty {
            return email
        }
        return ""
    }
    
    public func updateUserLocationWithBlock(latitude: String, longitude: String, completionHandler: @escaping (_ status: Bool) -> ()) {
        
        guard let currentUserID = userId else {
            completionHandler(false)
            return
        }
        
        let parameters = ["Latitude": latitude, "Longitude": longitude, "UserID": currentUserID]
        let headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(UpdateUserLocation, params: parameters, type: .POST, currentView: nil, header: headers) { response in
            if let json = response {
                let statusCode = json["StatusCode"].string ?? ""
                completionHandler(statusCode == "200")
            } else {
                completionHandler(false)
            }
        }
        
    }
}
