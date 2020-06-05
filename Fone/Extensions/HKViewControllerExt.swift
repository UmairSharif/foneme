//
//  HKViewControllerExt.swift
//  Raven
//
//  Created by hassan qureshi on 9/12/18.
//  Copyright © 2018 mindslab. All rights reserved.
//

import AVFoundation
import CallKit
import Photos
import CoreData
import Foundation
import SwiftyJSON
import TwilioVoice


extension UIViewController {
    
    
    //Error Alert
    
    func errorAlert(_ message : String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //  MAKR:- Custom Alerts
    func showAlert(_ message : String) {
        
        self.showAlert("Success", message)
        
    }
    
    func showAlert(_ title: String, _ message: String) {
        
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        let alertSimple = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertSimple.addAction(okAction)
        
        self.present(alertSimple, animated: true, completion: nil)
        
    }
    
    
    // MARK:- UIVIEW Animation
    func startRotateAnimation(_ viewToAnimate: UIView) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = 360.0
        rotationAnimation.duration = 50.0
        rotationAnimation.repeatCount = 1000.0
        viewToAnimate.layer.add(rotationAnimation, forKey: nil)
    }
    
    func stopRotateAnimation(_ viewToAnimate: UIView) {
        viewToAnimate.layer.removeAllAnimations()
    }
    
    
    func bottomTopAppearAnimation(_ view: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
            view.frame.origin.y -= UIScreen.main.bounds.height
            view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func topBottomHidingAnimation(_ view: UIView) {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseIn], animations: {
            view.frame.origin.y += UIScreen.main.bounds.height
            view.layoutIfNeeded()
        }, completion: nil)
    }
    
    
    // MARK:- ADD CHILD VC
    func addChildVC(_ child: UIViewController) -> UIView? {
        
        addChild(child)
        self.view.addSubview(child.view)
        child.view.frame = self.view.frame
        child.view.isHidden = true
        child.didMove(toParent: self)
        
        return child.view
    }
    
    func addChildVC(_ child: UIViewController, inside view: UIView) {
        
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.frame
        child.didMove(toParent: self)
        
    }
    
    func seralizeNotificationResult()
    {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = delegate.userInfo
        print(userInfo)
        let aps = userInfo?[AnyHashable("aps")] as? NSDictionary
        
        let receiverId = userInfo?["ReceiverId"] as? String
        let notificationType = userInfo?["NotificationType"] as? String
        let callStatusLogId = userInfo?["CallLogStatusId"] as? String
        let callType = userInfo?["CallType"] as? String
        let dialerNumber = userInfo?["DialerNumber"] as? String
        let status = userInfo?["Status"] as? String
        let dialerId = userInfo?["DialerId"] as? String
        let receiverNumber = userInfo?["ReceiverNumber"] as? String
        let channelName = userInfo?["ChannelName"] as? String
        let callDate = userInfo?["CallDate"] as? String
        let contentAvailable = userInfo?["content_available"] as? Bool
        let dialerImageUrl = userInfo?["DialerImageUrl"] as? String
        let alert = aps?["alert"] as? NSDictionary
        _ = alert?[AnyHashable("body")] as? String
        _ = alert?["title"] as? String
        
        
        if notificationType == "CLLCN"
        {
            
            NotificationHandler.shared.receiverId = receiverId
            NotificationHandler.shared.notificationType = notificationType
            NotificationHandler.shared.callStatusLogId = callStatusLogId
            NotificationHandler.shared.callType = callType
            NotificationHandler.shared.dialerNumber = dialerNumber
            NotificationHandler.shared.status = status
            NotificationHandler.shared.dialerId = dialerId
            NotificationHandler.shared.receiverNumber = receiverNumber
            NotificationHandler.shared.channelName = channelName
            NotificationHandler.shared.callDate = callDate
            NotificationHandler.shared.dialerImageUrl = dialerImageUrl
            NotificationHandler.shared.callStatus = true
            NotificationHandler.shared.contentAvailable = contentAvailable
            
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Speaker error : \(error)")
            }
            
            let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "Fone"))
            provider.setDelegate(self, queue: nil)
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: dialerNumber ?? "")
            provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in })
        }
        else if notificationType == "UNA"
        {
            NotificationHandler.shared.callStatus = false
            self.dismiss(animated: true, completion: nil)
            performsEndCallAction()
        }
            
        else if notificationType == "CE"
        {
            NotificationHandler.shared.callStatus = false
            self.dismiss(animated: true, completion: nil)
            performsEndCallAction()
        }
    }
    
    func performsEndCallAction() {
        let uuid = UUID()
           let callKitCallController: CXCallController?
           let endCallAction = CXEndCallAction(call: uuid)
           callKitCallController = CXCallController()
           let transaction = CXTransaction(action: endCallAction)
           
           callKitCallController?.request(transaction) { error in
               if let error = error {
                   NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
               } else {
                   NSLog("EndCallAction transaction request successful")
               }
           }
       }
    
    
    func sendMissedCallNotificationAPI(){
        
        let parameter = [
            "SenderMobileNumber" : NotificationHandler.shared.receiverNumber ?? "",
            "NotificationType" : "UNA",
            "ReceiverUserId" : NotificationHandler.shared.dialerId ?? ""
            ] as [String : Any]
        print(parameter)
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(endCallUrl, params: parameter, type:Method.POST, currentView: self.view, header: headers) { (response) in
            print(response ?? JSON.null)
            
            if let json = response {
                if !json.isEmpty {
                    print(json)
                    
                    self.addCallsLogsAPI()
                }
            }
        }
    }
    
    
    func addCallsLogsAPI()
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let givenDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM/dd/yyyy HH:mm:ss a"
        let dateTime = formatter.string(from: givenDate ?? Date())
        
        let parameter = [
                   "ReceiverId" : NotificationHandler.shared.receiverId ?? "",
                   "CallConnectionId" : NotificationHandler.shared.callStatusLogId ?? "",
                   "ReceiverStatus" : "MIS",
                   "CallReceivingTime" : dateTime,
                   "NotificationType" : "CE"
                   ] as [String : Any]
               print(parameter)
               
               let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
               var headers = [String:String]()
               headers = ["Content-Type": "application/json",
                          "Authorization" : "bearer " + loginToken!]
               
               ServerCall.makeCallWitoutFile(addCallLogUrl, params: parameter, type:Method.POST, currentView: self.view, header: headers) { (response) in
                   print(response ?? JSON.null)
                   
                   if let json = response {
                       if !json.isEmpty {
                           print(json)
                       }
                   }
               }
    }
    
    func navigateToCallScreen()
    {
        if NotificationHandler.shared.callType == "AD"{
            let tabBarController = UIStoryboard().loadTabBarController()
            let selectedIndexe = tabBarController.selectedIndex
            let desiredVC = UIStoryboard().loadVideoCallVC()
            
            if selectedIndexe == 0 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else if selectedIndexe == 1 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else if selectedIndexe == 2 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else
            {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
        }
    }
}

extension UIViewController : CXProviderDelegate{
    public func providerDidReset(_ provider: CXProvider) {
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    
        if NotificationHandler.shared.callType == "AD"{
            let tabBarController = UIStoryboard().loadTabBarController()
            let selectedIndexe = tabBarController.selectedIndex
            let desiredVC = UIStoryboard().loadVideoCallVC()
            
            if selectedIndexe == 0 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else if selectedIndexe == 1 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else if selectedIndexe == 2 {
                self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
            else
            {
               self.navigationController?.present(desiredVC, animated: true, completion: nil)
            }
        }
        action.fulfill()
    }
    
   public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    
    DispatchQueue.main.async {
        
        if NotificationHandler.shared.callStatus ?? false
        {
            topViewController()?.sendMissedCallNotificationAPI()
        }
        
        action.fulfill()
   
       }
    }
}
