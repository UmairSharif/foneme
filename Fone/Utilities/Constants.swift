//
//  Constants.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation
import UIKit

let KEY_OPEN_PROFILE_SOCIAL_LINKS = "KEY_OPEN_PROFILE_SOCIAL_LINKS"

let BrainTree_toKinizationKey = "sandbox_ktbkxkdd_trhv6grk27vpbzkp"
let BrainTree_toKinizationKey_Pro = "production_csr6kp5g_ysvjqxmg78mdgnbf"


let SubscriptionStatus = "subscriptionStatus"
let SubscriptionPlan = "planId"
let SubscriptionId = "subscriptionId"
let SubscriptionDays = "subscriptionDays"
//"5A3F0F54-1ED8-43D0-A352-627AFE220EC4"

let APP_ID = "A1DBCE29-98BD-42E9-AA18-CC85D771FF98"
let CHANNEL_URL = "https://api-A1DBCE29-98BD-42E9-AA18-CC85D771FF98.sendbird.com"

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

let appDelegateShareInst = UIApplication.shared.delegate as! AppDelegate

//****************************************//
//******       VARIABLES           *******//
//****************************************//

var appDeleg = UIApplication.shared.delegate as! AppDelegate
/// Default is New York, USA location. This value is used if user's location is disabled (Denied permission)
var GLBLatitude = 40.730610
var GLBLongitude = -73.935242
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

extension Date {

    func timeAgoSinceDate() -> String {

        // From Time
        let fromDate = self

        // To Time
        let toDate = Date()

        // Estimation
        // Year
        if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
        }

        // Month
        if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
        }

        // Day
        if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {

            return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
        }

        // Hours
        if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {

            return interval == 1 ? "\(interval)" + " " + "hour ago" : "\(interval)" + " " + "hours ago"
        }

        // Minute
        if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {

            return interval == 1 ? "\(interval)" + " " + "minute ago" : "\(interval)" + " " + "minutes ago"
        }

        return "a moment ago"
    }
}

extension String {

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date

    }
}

extension Date {

    func toString(withFormat format: String = "EEEE ، d MMMM yyyy") -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fa-IR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
        dateFormatter.calendar = Calendar(identifier: .persian)
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)

        return str
    }
}
