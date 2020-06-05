//
//  NotificationHandler.swift
//  Fone
//
//  Created by Bester on 13/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import Foundation

class NotificationHandler : NSObject
{
    static let shared = NotificationHandler()
    
    var receiverId : String?
    var notificationType : String?
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
}
