//
//  AppDelegate+IncomingCall.swift
//  Fone
//
//  Created by PC on 11/06/20.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import UserNotifications

extension AppDelegate {
    
    func displayIncomingCall(
      uuid: UUID,
      handle: String,
      hasVideo: Bool = false,
      completion: ((Error?) -> Void)?
    ) {
     
    }
    
    func registerForLocalNotifications() {
        // Define the custom actions.
        let inviteAction = UNNotificationAction(identifier: "INVITE_ACTION",
              title: "Simulate VoIP Push",
              options: UNNotificationActionOptions(rawValue: 0))
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
              title: "Decline",
              options: .destructive)
        let notificationCenter = UNUserNotificationCenter.current()

        // Define the notification type
        let meetingInviteCategory = UNNotificationCategory(identifier: "ROOM_INVITATION",
                                                           actions: [inviteAction, declineAction],
                                                           intentIdentifiers: [],
                                                           options: .customDismissAction)
        notificationCenter.setNotificationCategories([meetingInviteCategory])

        // Register for notification callbacks.
        notificationCenter.delegate = self

        // Request permission to display alerts and play sounds.
        notificationCenter.requestAuthorization(options: [.alert])
           { (granted, error) in
              // Enable or disable features based on authorization.
           }
    }
    
    
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        userInfo = notification.request.content.userInfo
        
        
        if let messageID = userInfo![gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        if userInfo != nil {
            self.handleNotificationsForCall(userInfo: userInfo!)
        }
        topViewController()?.seralizeNotificationResult()
        completionHandler([.alert,.sound,.badge])
    }
    
    func handleNotificationsForCall(userInfo : [AnyHashable : Any]){
        if let push_type = userInfo[AnyHashable("push_type")] as? String {
            print(push_type)
            if push_type == "call_decline"{
                if let topVC = topViewController() {
                    if topVC is VideoCallVC {
                        let userName = userInfo[AnyHashable("user_name")] as? String ?? "User"
                        topVC.showAlert(message: "\(userName) decline your call.") { (alert) in
                            let vc = topVC as! VideoCallVC
                            vc.disconnect(sender: UIButton())
                        }
                    }
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        userInfo = response.notification.request.content.userInfo
        // Print message ID.
        
        
        if let messageID = userInfo![gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
    
        topViewController()?.seralizeNotificationResult()
        
        completionHandler()
    }
}
