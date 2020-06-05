//
//  Constants.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation
import UIKit


let APP_ID = "5A3F0F54-1ED8-43D0-A352-627AFE220EC4"
let CHANNEL_URL = "https://api-5A3F0F54-1ED8-43D0-A352-627AFE220EC4.sendbird.com"

let APP_NAME = "Basket Ball App"
let key_User_Profile = "User_Profile"
//let key_Provider_Profile = "Provider_Profile"
let Key_Login_Token = "LoginToken"
let Key_Login_Status = "LoginStatus"
let ClientId = "aad4dc0739b64c529ab86c2126ed341c"
let Key_FCM_token = "FCMToken"

//****************************************//
//******       VARIABLES           *******//
//****************************************//

var appDeleg = UIApplication.shared.delegate as! AppDelegate

var LoginToken : String? {
    if let token = UserDefaults.standard.string(forKey: Key_Login_Token) {
        return token
    }
    return nil
}

var FCMToken : String? {
    if let token = UserDefaults.standard.string(forKey: Key_FCM_token) {
        return token
    }
    return nil
}

var isLoggedIn : Bool {
    return UserDefaults.standard.bool(forKey: Key_Login_Status)
}

var userType : Int {
    return UserDefaults.standard.integer(forKey: "userType")
}

var userProfile : User {
    var aUser = User()
    if let userObjData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
        if let userObj = try? PropertyListDecoder().decode(User.self, from: userObjData) {
            aUser = userObj
        }
    }
    return aUser
}

//var providerProfile : Provider {
//    var aProvider = Provider()
//    if let providerObjData = UserDefaults.standard.object(forKey: key_Provider_Profile) as? Data {
//        if let providerObj = try? PropertyListDecoder().decode(Provider.self, from: providerObjData) {
//            aProvider = providerObj
//        }
//    }
//    return aProvider
//}


var isiPhone : DEVICE {
    if UIScreen.main.bounds.size.height == 568.0 {
        return DEVICE.iPhone5S
    }
    else if UIScreen.main.bounds.size.height == 750.0 {
        return DEVICE.iPhoneX
    }
    return DEVICE.iPhone6S
}


//****************************************//
//******           BLOCKS          *******//
//****************************************//

//typealias CompletionHandler = (_ Success: Bool) -> ()





// MARK:- Current UIView
public func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
        return topViewController(nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
        if let selected = tab.selectedViewController {
            return topViewController(selected)
        }
    }
    if let presented = base?.presentedViewController {
        return topViewController(presented)
    }
    return base
}
