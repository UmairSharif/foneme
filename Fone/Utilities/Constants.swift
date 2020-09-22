//
//  Constants.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation
import UIKit

//let BrainTree_toKinizationKey = "sandbox_ktbkxkdd_trhv6grk27vpbzkp"
let BrainTree_toKinizationKey = "production_csr6kp5g_ysvjqxmg78mdgnbf"


let SubscriptionStatus = "subscriptionStatus"
let SubscriptionPlan = "planId"

let APP_ID = "5A3F0F54-1ED8-43D0-A352-627AFE220EC4"
let CHANNEL_URL = "https://api-5A3F0F54-1ED8-43D0-A352-627AFE220EC4.sendbird.com"

let APP_NAME = "Basket Ball App"
let key_User_Profile = "User_Profile"
//let key_Provider_Profile = "Provider_Profile"
let Key_Login_Token = "LoginToken"
let Key_Login_Status = "LoginStatus"
let Key_VOIP_Token = "VOIPToken"
let ClientId = "aad4dc0739b64c529ab86c2126ed341c"
let Key_FCM_token = "FCMToken"
let OneSignalId = "783cb86b-0366-4269-84b5-1029c3970e4c"//"8e245475-891c-4b63-a6c0-615e1cddbd65"
let oneSignalSendNotification = "https://onesignal.com/api/v1/notifications"
let oneSignalRegisterVOIP = "https://onesignal.com/api/v1/players"

let Min_Contact_Number_Lenght = 6


//****************************************//
//******       VARIABLES           *******//
//****************************************//

var appDeleg = UIApplication.shared.delegate as! AppDelegate

var VoipToken : String? {
    if let token = UserDefaults.standard.string(forKey: Key_VOIP_Token) {
        return token
    }
    return nil
}

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

