//
//  URL.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation

let BASEURL = "https://zwilio.com/"
//************** Authenticate Part URL *************/////
let registerUrl = "\(BASEURL)api/account/v1/register"
let getSMSCodeUrl = "\(BASEURL)api/account/v1/getsmscode"
let verifyPincodeUrl = "\(BASEURL)api/account/v1/verifysmscode"
let getAccessTokenUrl = "\(BASEURL)token"
let updateProfileUrl = "\(BASEURL)api/account/v1/updateuserprofile"
let getCallTokenUrl = "\(BASEURL)api/account/v1/tokenforcall"
let sendCallNotificationUrl = "\(BASEURL)api/account/v1/sendcallnotification"
let getCallLogsUrl = "\(BASEURL)api/account/v1/usercalllogs"
let logoutUrl = "\(BASEURL)api/account/v1/logout"
let endCallUrl = "\(BASEURL)api/account/v1/userpushnotifications"
let addCallLogUrl = "\(BASEURL)api/account/v1/callstatushandling"
let saveContactUrl = "\(BASEURL)api/account/v1/usercontacts"
let missCallUrl = "\(BASEURL)api/account/v1/dialerpushnotifications"
let getProfileUrl = "\(BASEURL)api/account/v1/lookuser"
let addMyFriend = "\(BASEURL)api/account/v1/addmyfriend"
let removeMyFriend = "\(BASEURL)api/account/v1/removemyfriend"
let searchUser = "\(BASEURL)api/account/v1/searchuser"
let changeuservoiptoken = "\(BASEURL)api/account/v1/changeuservoiptoken"
let changeuserdevicetoken = "\(BASEURL)api/account/v1/changeuserdevicetoken"
let sendFcmOPt = "\(BASEURL)api/account/v1/sendFcmOPt"
//searchuser
