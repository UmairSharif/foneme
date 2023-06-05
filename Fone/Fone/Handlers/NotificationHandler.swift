//
//  NotificationHandler.swift
//  Fone
//
//  Created by Bester on 13/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import Foundation

enum CurrentCallStatus: Int {
    case Incoming = 0
    case OutGoing = 1
    case Nothing = 2
}


class NotificationHandler : NSObject
{
    static let shared = NotificationHandler()
    var isReceived : Bool = false
    var receiverId : String?
    var notificationType : String?
    var dialerName : String?
    var callStatusLogId : String?
    var callType : String?
    var dialerNumber : String?
    var status : String?
    var dialerId : String?
    var receiverNumber : String?
    var channelName : String?
    var callDate : String?
    var callStatus : Bool?
    var dialerImageUrl : String?
    var contentAvailable : Bool?
    var dialerFoneId : String?
    var isCallNotificationHandled : Bool?
    var isVideo : Bool?
    var currentCallStatus = CurrentCallStatus.Nothing
    var currentCallUUID: UUID?
    var fcmToken: String?
    var userID: String?
    var isAnwereCall: Bool?
    var isDeclinedByUserBeforeAttend: Bool?

    static func setSharedNotificationsForOutgoingCall(){
        NotificationHandler.shared.isReceived = false
        NotificationHandler.shared.receiverId = nil
        NotificationHandler.shared.notificationType = nil
        NotificationHandler.shared.callStatusLogId = nil
        NotificationHandler.shared.callType = nil
        NotificationHandler.shared.dialerNumber = nil
        NotificationHandler.shared.status = nil
        NotificationHandler.shared.dialerId = nil
        NotificationHandler.shared.receiverNumber = nil
        NotificationHandler.shared.channelName = nil
        NotificationHandler.shared.callDate = nil
        NotificationHandler.shared.dialerImageUrl = nil
        NotificationHandler.shared.fcmToken = nil
        NotificationHandler.shared.userID = nil
        NotificationHandler.shared.currentCallUUID = nil
        NotificationHandler.shared.callStatus = false
        NotificationHandler.shared.currentCallStatus = .Nothing
        NotificationHandler.shared.dialerName = nil
        NotificationHandler.shared.dialerImageUrl = nil
        NotificationHandler.shared.isVideo = false
        NotificationHandler.shared.isAnwereCall = nil
        NotificationHandler.shared.isDeclinedByUserBeforeAttend = nil
    }

}
