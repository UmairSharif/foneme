//
//  URL.swift
//  RestaurantFinder
//
//  Created by Hamza on 10/16/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import Foundation

let IS_SANDBOX = 1
let BASEURL =   "https://zwilio.com/"
//************** Authenticate Part URL *************/////

//let BASEURL = "https://foneme.zwilio.com/"
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
let createGroupChannel = "\(BASEURL)api/account/v1/createGroupChannel"
let getGroupByDeepLink = "\(BASEURL)api/account/v1/getGroupByDeepLink"
let updateGroupChannel = "\(BASEURL)api/account/v1/updateGroupChannel"
let getSingleGroupDetails = "\(BASEURL)api/account/v1/getSingleGroupDetails"
let GetUserProfile = "\(BASEURL)api/account/v1/cnctoprofile"
//searchuser
let updateAboutme = "\(BASEURL)api/account/v1/updateAboutme"
let getuserdetail = "\(BASEURL)api/account/v1/phoneNumberToProfile"
let SearchGroupbyName = "\(BASEURL)api/account/v1/getGroupByName"
 
let BrainTreeServer = "http://yogofly.com/wizride3/upload/file/brain"
//let BrainTreeServer = "https://techmowebexperts.com/brain"
let getBrainTreePlans = "\(BrainTreeServer)/plans.php?sandbox=\(IS_SANDBOX)"
let getSubscriptions_Customer = "\(BrainTreeServer)/createCustomer.php?mode=getSubscriptions&sandbox=\(IS_SANDBOX)&phone="
let setSubscriptions_Customer = "\(BrainTreeServer)/createCustomer.php?sandbox=\(IS_SANDBOX)"
let cancelSubscription_Customer = "\(BrainTreeServer)/cancelSubscription.php?sandbox=\(IS_SANDBOX)&subscriptionId="

//d/file/brain/cancelSubscription.php?subscriptionId=3zybdg&sandbox=1
let addSocialLinkUrl = "\(BASEURL)api/account/v1/addSocialLink"
let deleteSocialLinkUrl = "\(BASEURL)api/account/v1/deleteSocialLink"
let updateSocialLinkUrl = "\(BASEURL)api/account/v1/updateSocialLink"
