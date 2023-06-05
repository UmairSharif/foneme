//
//  VideoCallVC+Extension.swift
//  Fluff
//
//  Created by Jahan on 6/16/20.
//  Copyright © 2020 xe. All rights reserved.
//


import UIKit
import TwilioVideo
import SwiftyJSON
import CallKit
import AVFoundation
import UserNotifications
import PushKit
import Alamofire

extension VideoCallVC : CXProviderDelegate {
    func recevierSendNotificationAPI(_ status : String){
        
        let parameter = [
            "SenderMobileNumber" : NotificationHandler.shared.receiverNumber ?? "",
            "NotificationType" : status,
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
                print(json)
                if !json.isEmpty {
                    print(json)
                    if status == "MIS" {
                        self.addCallLogAPI(status: status, notifType: "CE")
                    }
                }
            }
        }
    }
    
    func dialerSendNotificationAPI_old(){
        var mobileNumber : String?
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                mobileNumber = user.mobile ?? ""
            }
        }
        
        var notificationType : String?
        if callConnectionStatus
        {
            notificationType = "CE"
        }
        else
        {
            notificationType = "MIS"
        }
        
        let parameter = [
            "SenderMobileNumber" : mobileNumber ?? "",
            "NotificationType" : notificationType ?? "",
            "ReceiverMobileNumber" : recieverNumber ?? ""
            ] as [String : Any]
        print(parameter)
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(missCallUrl, params: parameter, type:Method.POST, currentView: self.view, header: headers) { (response) in
            print(response ?? JSON.null)
            
            if let json = response {
                if !json.isEmpty {
                    print(json)
                    
                }
            }
           
        }
    }
    
  //  func sendMissedCallNotificationAPI(){
        func dialerSendNotificationAPI(){
            var mobileNumber : String?
                   if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                       print(userProfileData)
                       if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                           mobileNumber = user.userId ?? ""
                       }
                   }

           let parameter = [
            "SenderMobileNumber" : self.userDetails?.mobileNumberWithoutCode ?? "",
               "NotificationType" : "MIS",
               "ReceiverUserId" :mobileNumber ?? ""
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
                       
                       self.addMissCallsLogsAPI()
                   }
               }
           }
       }
       
       
       func addMissCallsLogsAPI() {
        
        let receiverId = self.userDetails?.userId
        var mobileNumber = ""
                          if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                              print(userProfileData)
                              if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                                  mobileNumber = user.mobile ?? ""
                              }
                          }

           let formatter = DateFormatter()
           formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
           let myString = formatter.string(from: Date())
           let givenDate = formatter.date(from: myString)
           formatter.dateFormat = "MMM/dd/yyyy HH:mm:ss a"
           let dateTime = formatter.string(from: givenDate ?? Date())
           
           let parameter = [
                      "SenderMobileNumber" : self.userDetails?.phoneNumber ?? "",
                      "CallReceivingTime" : dateTime,
                            "NotificationType" : "UNA",
                            "ReceiverStatus" : "MIS",
                            "ReceiverUserId" : receiverId ?? ""
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
       
    
    func providerDidReset(_ provider: CXProvider) {
        logMessage(messageText: "providerDidReset:")
        
        // AudioDevice is enabled by default
        self.audioDevice.isEnabled = true
        
        room?.disconnect()
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        logMessage(messageText: "providerDidBegin")
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1) ) {
//            self.playSound(withFileName: "iphone-original")
//
//        }

    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        logMessage(messageText: "provider:didActivateAudioSession:")
        
        self.audioDevice.isEnabled = true
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        logMessage(messageText: "provider:didDeactivateAudioSession:")
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        logMessage(messageText: "provider:timedOutPerformingAction:")
        self.dialerSendNotificationAPI()
        self.showAlert(message: "Call timeout") { (handle) in
            self.disconnect(sender: UIButton())
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        logMessage(messageText: "provider:performStartCallAction:")
        
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        // Stop the audio unit by setting isEnabled to `false`.
        self.audioDevice.isEnabled = false;
        
        // Configure the AVAudioSession by executign the audio device's `block`.
        self.audioDevice.block()
        self.playSound()
        callKitProvider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
        //action.handle.value
        self.roomFCMToken = UserDefaults.standard.value(forKey: Key_FCM_token) as? String ?? ""
        
        self.getTokenAPI { (success) in
            if success {
                self.performRoomConnect(uuid: action.callUUID, roomName: self.roomName) { (success) in
                    if (success) {
                        self.playSound()
                        provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
                        action.fulfill()
                    } else {
                        action.fail()
                    }
                }
            }
        }
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        logMessage(messageText: "provider:performAnswerCallAction:")
        
        /*
         * Configure the audio session, but do not start call audio here, since it must be done once
         * the audio session has been activated by the system after having its priority elevated.
         */
        
        // Stop the audio unit by setting isEnabled to `false`.
        DispatchQueue.main.async {
            self.audioDevice.isEnabled = false;
            self.player?.stop()
            // Configure the AVAudioSession by executign the audio device's `block`.
            self.audioDevice.block()
            if self.isVideo {
                self.previewView.isHidden = true
                self.previewCallingView.isHidden = false
            }else{
                self.previewView.isHidden = true
                self.previewCallingView.isHidden = true
                self.remoteCallingView.isHidden = true
            }
            self.roomName = NotificationHandler.shared.dialerNumber ?? ""
            action.fulfill(withDateConnected: Date())
            self.performRoomConnect(uuid: action.callUUID, roomName: self.roomName) { (success) in
                if (success) {
                    if self.isVideo {
                        self.previewView.isHidden = false
                        self.previewCallingView.isHidden = true
                    }else{
                        self.previewView.isHidden = true
                        self.previewCallingView.isHidden = true
                        self.remoteCallingView.isHidden = true
                    }
                } else {
                    action.fail()
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        self.player?.stop()

        if self.isDeclinedCall == false {
            self.isDeclinedCall = true
        }
        
        let transaction = CXTransaction(action: action)
        self.callKitCallController.request(transaction) { error in
            if let error = error {
                print("EndCallAction transaction request failed: \(error.localizedDescription).")
                self.callKitProvider.reportCall(with: action.callUUID, endedAt: Date(), reason: .remoteEnded)
            }
            print("EndCallAction transaction request successful")
            
        }
        
        room?.disconnect()
        
        self.camera = nil
        self.localAudioTrack = nil
        self.localVideoTrack = nil
        self.remoteParticipant = nil
        self.room = nil
        provider.reportCall(with: action.callUUID, endedAt: Date(), reason: .remoteEnded)
        provider.invalidate()
        action.fulfill()
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                if self.isIncommingCall {
//                    self.sendFCMPush(title: "Call Declined", description: "\(user.name ?? "user") decline your call.", fcmToken: NotificationHandler.shared.fcmToken!, params: ["push_type":"call_decline","user_name":user.name ?? "User"])

                    self.recevierSendNotificationAPI("UNA")
                }
                
            }
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("provier:performSetMutedCallAction:")
        
        muteAudio(isMuted: action.isMuted)
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provier:performSetHeldCallAction:")
        
        let cxObserver = callKitCallController.callObserver
        let calls = cxObserver.calls
        
        guard let call = calls.first(where:{$0.uuid == action.callUUID}) else {
            action.fail()
            return
        }
        
        if call.isOnHold {
            holdCall(onHold: false)
        } else {
            holdCall(onHold: true)
        }
        action.fulfill()
    }
    
    
}

// MARK:- Call Kit Actions
extension VideoCallVC {
    
    func performStartCallAction(uuid: UUID, roomName: String?) {
        let callHandle = CXHandle(type: .phoneNumber, value: roomName ?? "")
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        
        startCallAction.isVideo = self.isVideo
        
        let transaction = CXTransaction(action: startCallAction)
        
        callKitCallController.request(transaction)  { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }
            NSLog("StartCallAction transaction request successful")
        }
    }
    
    func reportIncomingCall(uuid: UUID, roomName: String?, completion: ((NSError?) -> Void)? = nil) {
        
        let callHandle = CXHandle(type: .generic, value: roomName ?? "" )
        let callUpdate = CXCallUpdate()
        
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = false
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = self.isVideo
        
        self.isIncommingCall = true
        self.roomFCMToken = NotificationHandler.shared.fcmToken ?? ""
        callKitProvider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
                        
       //  self.playSound(withFileName: "iphone-original")
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2) ) {
//                 self.playSound(withFileName: "iphone-original")
//            }
            
            if error == nil {
                NSLog("Incoming call successfully reported.")
                
            } else {
                NSLog("Failed to report incoming call successfully: \(String(describing: error?.localizedDescription)).")
            }
            completion?(error as NSError?)
        }
    }
    
    func performRoomConnect(uuid: UUID, roomName: String? , completionHandler: @escaping (Bool) -> Swift.Void) {
        // Configure access token either from server or manually.
        // If the default wasn't changed, try fetching from server.
        self.prepareLocalMedia()
        var userId : String = ""
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId ?? ""
            }
        }
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["AccessToken": loginToken!,
                      "UserId": userId,
                      "ChannelName": roomName!
            ] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(getCallTokenUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                
                let token = json["JWTToken"].string ?? ""
                self.accessToken = token
                UserDefaults.standard.set(token, forKey: "token")
                UserDefaults.standard.synchronize()
                
                let videoOptions = VideoBandwidthProfileOptions { builder in
                    // Minimum subscribe priority of Dominant Speaker's RemoteVideoTracks
                    builder.dominantSpeakerPriority = .high
                    
                    // Maximum bandwidth (Kbps) to be allocated to subscribed RemoteVideoTracks
                    builder.maxSubscriptionBitrate = 6000
                    
                    // Max number of visible RemoteVideoTracks. Other RemoteVideoTracks will be switched off
                    builder.maxTracks = 5
                    
                    // Subscription mode: collaboration, grid, presentation
                    builder.mode = .presentation
                    
                    // Configure remote track's render dimensions per track priority
                    let renderDimensions = VideoRenderDimensions()
                    
                    // Desired render dimensions of RemoteVideoTracks with priority low.
                    renderDimensions.low = VideoDimensions(width: 352, height: 288)
                    
                    // Desired render dimensions of RemoteVideoTracks with priority standard.
                    renderDimensions.standard = VideoDimensions(width: 640, height: 480)
                    
                    // Desired render dimensions of RemoteVideoTracks with priority high.
                    renderDimensions.high = VideoDimensions(width: 1280, height: 720)
                    
                    builder.renderDimensions = renderDimensions
                    
                    // Track Switch Off mode: .detected, .predicted, .disabled
                    builder.trackSwitchOffMode = .predicted
                }
                let bandwidthProfileOptions = BandwidthProfileOptions(videoOptions: videoOptions)
                
                
                // Preparing the connect options with the access token that we fetched (or hardcoded).
                let connectOptions = ConnectOptions.init(token: token) { (builder) in
                    
                    // Use the local media that we prepared earlier.
                    builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [LocalAudioTrack]()
                    if self.isVideo {
                        builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [LocalVideoTrack]()
                        
                        // Use the preferred video codec
                        if let preferredVideoCodec = AVSettings.shared.videoCodec {
                            builder.preferredVideoCodecs = [preferredVideoCodec]
                        }
                    }
                    
                    // Use the preferred audio codec
                    if let preferredAudioCodec = AVSettings.shared.audioCodec {
                        builder.preferredAudioCodecs = [preferredAudioCodec]
                    }
                    
                    
                    
                    // Use the preferred encoding parameters
                    if let encodingParameters = AVSettings.shared.getEncodingParameters() {
                        builder.encodingParameters = encodingParameters
                    }
                    
                    // Use the preferred signaling region
                    if let signalingRegion = AVSettings.shared.signalingRegion {
                        builder.region = signalingRegion
                    }
                    if self.isVideo {
                        builder.bandwidthProfileOptions = bandwidthProfileOptions
                    }
                    
                    // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
                    // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
                    builder.roomName = self.roomTextField.text
                    builder.uuid = uuid
                    
                    builder.isAutomaticSubscriptionEnabled = true
                    
                }
                
                // Connect to the Room using the options we provided.
                
                self.room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
                self.logMessage(messageText: "Attempting to connect to room \(String(describing: roomName))")
                
                self.callKitCompletionHandler = completionHandler
                
            }
            else{
                print(response?.error?.localizedDescription ?? "Error")
            }
        }
        
    }
    
    func sendVOIPNotification(voipToken:String,roomName : String,uuid : String , fcmToken : String ,completion: @escaping (_ success : Bool) -> Void) {
        print("My Video :",self.isVideo)
        DispatchQueue.main.async {
            var userId : String?
            var dialerNumber : String?
            var dialerName : String?
            var dialerId : String?
            var dialerImageUrl : String?
            //sendVOIPNotification
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    userId = user.userId
                    dialerNumber = user.mobile
                    dialerName = user.name
                    dialerId = user.address ?? user.email
                    dialerImageUrl = user.userImage
                }
            }
            var type = "AD"
            if self.isVideo == true {
                type = "VD"
            }
            
            let params = ["DialerNumber": dialerNumber ?? "",
                          "ReceiverNumber": self.recieverNumber ?? "",
                          "Status": "OG",
                          "CallType" : type,
                          "AppType" : "IOS",
                          "ChannelName" : dialerNumber ?? "",
                          "UserId" : userId ?? "",
                          "CallStatusType": "APPTOAPP",
                          "room_name":roomName,
                          "uuid":uuid ,
                          "fcmToken":fcmToken
                ] as [String:Any]
            
            print("sendVOIPNotification: \(params)")
            //                "include_player_ids":["8e115324-34f7-48da-b2bb-d8fe0a87f370"],
//"2a237d4c-f138-4eaa-839a-c6d697a1174e"
            //                "include_player_ids":[voipToken],

            //voipToken
           //US //"6fed3c72-3e5f-4053-b3b1-bb0352de4570",
            //Rajesh "b9d6a0e0-c53d-4dc6-ba38-e2a7987e0fdd"
            //"telephone.caf"
            //"d1878280-d9b6-4689-a70f-a1be87acde0a" Rajesh DEV
            //d1878280-d9b6-4689-a70f-a1be87acde0a
            print("oneSignalSendNotification: \(oneSignalSendNotification)")
            
            let Dataparam : [String : Any] = ["DialerNumber": dialerNumber ?? "",
                                              "ReceiverNumber": self.recieverNumber ?? "",
                                              "dialerName": dialerName ?? "",
                                              "dialerFoneId": dialerId ?? "",
                                              "dialerImage": dialerImageUrl ?? "",
                                              "Status": "OG",
                                              "NotificationType":"CLLCN",
                                              "CallType" : type,
                                              "AppType" : "IOS",
                                              "ChannelName" : dialerNumber ?? "",
                                              "CallerName": dialerName ?? "",
                                              "UserId" : userId ?? "",
                                              "CallStatusType": "APPTOAPP",
                                              "room_name":roomName,
                                              "uuid":uuid ,
                                              "isVideo":self.isVideo,
                                              "fcmToken":fcmToken]
            let  param : [ String : Any] = ["app_id": OneSignalId,
                                            "contents": ["en":"English Message"],
                                            "apns_push_type_override":"voip",
                                            "include_player_ids":[voipToken],
                                            "ios_sound":"iphone-original.caf","data": Dataparam]
            let parameters: Parameters = param
            
            print(parameters)
            let header = ["Content-Type":"application/json",
                          "Authorization":"Basic ZTI1ZGZmZWItZmE1MC00OWRjLTlhMjEtYmFlNDgyZjc0OWI0"]
            Alamofire.request(oneSignalSendNotification, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header)
                .validate()
                .responseString { (response) in
                    do{
                        let json = try JSON(data: response.data!)
                        print(json)
                        completion(true)
                    }
                    catch{
                        completion(false)
                    }
            }
            
        }
    }
    
    
    func getEncodingParameters() -> EncodingParameters?  {
        if maxAudioBitrate == 0 && maxVideoBitrate == 0 {
            return nil;
        } else {
            return EncodingParameters(audioBitrate: maxAudioBitrate,
                                      videoBitrate: maxVideoBitrate)
        }
    }
}



extension VideoCallVC: PushKitEventDelegate {
    
    func credentialsUpdated(credentials: PKPushCredentials) {
        print("a")
    }
    
    func credentialsInvalidated() {
        print("b")
    }
    
    func incomingPushReceived(payload: PKPushPayload) {
        handleVOIPPush(payload: payload)
    }
    
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        handleVOIPPush(payload: payload)
        
    }
    
    func handleVOIPPush(payload : PKPushPayload) {
        print(payload.dictionaryPayload)
        let custumDic = payload.dictionaryPayload["custom"] as! [String : Any]
        let payloadDict = custumDic["a"] as? [String : Any]
        let receiverId = payloadDict?["ReceiverId"] as? String ?? ""
        let notificationType = payloadDict?["NotificationType"] as? String ?? ""
        let callStatusLogId = payloadDict?["CallLogStatusId"] as? String ?? ""
        let callType = payloadDict?["CallType"] as? String ?? ""
        let dialerNumber = payloadDict?["DialerNumber"] as? String ?? ""
        let status = payloadDict?["Status"] as? String ?? ""
        let callerName = payloadDict?["CallerName"] as? String ?? ""
        let dialerId = payloadDict?["dialerFoneId"] as? String ?? ""
        let dialerName = payloadDict?["dialerName"] as? String ?? ""
        let receiverNumber = payloadDict?["ReceiverNumber"] as? String ?? ""
        let channelName = payloadDict?["ChannelName"] as? String ?? ""
        let callDate = payloadDict?["CallDate"] as? String ?? ""
        let dialerImageUrl = payloadDict?["DialerImageUrl"] as? String ?? ""
        let fcmToken = payloadDict?["fcmToken"] as? String ?? ""
        let UserId = payloadDict?["UserId"] as? String ?? ""
        let uuid = payloadDict?["uuid"] as? String ?? ""
        let isVideoParam = payloadDict?["isVideo"] as? Bool ?? false
        _ = payloadDict?["alert"] as? String ?? ""
        _ = payloadDict?["body"] as? String ?? ""
        _ = payloadDict?["title"] as? String ?? ""
        
        if UIApplication.shared.applicationState == UIApplication.State.background {
            
            if notificationType  == "CLLCN"
            {
                DispatchQueue.main.async {
                    
                    let update = CXCallUpdate()
                    update.remoteHandle = CXHandle(type: .phoneNumber, value: callerName )
                    NotificationHandler.shared.isReceived = true
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
                    NotificationHandler.shared.fcmToken = fcmToken
                    NotificationHandler.shared.userID = UserId
                    NotificationHandler.shared.currentCallUUID = UUID(uuidString: uuid)
                    NotificationHandler.shared.callStatus = true
                    NotificationHandler.shared.dialerFoneId = dialerId
                    NotificationHandler.shared.dialerName = dialerName
                    NotificationHandler.shared.dialerImageUrl = dialerImageUrl
                    NotificationHandler.shared.isVideo = isVideoParam
                }
            }
                
            else if notificationType  == "UNA"
            {
                self.performsEndCallAction()
                NotificationHandler.shared.callStatus = false
            }
                
            else if notificationType == "CE"
            {
                
                self.performsEndCallAction()
                NotificationHandler.shared.callStatus = false
            }
            
        }
        if UIApplication.shared.applicationState == UIApplication.State.active {
            print("Active")
            
            if notificationType == "CLLCN"
            {
                DispatchQueue.main.async {
                    
                    let update = CXCallUpdate()
                    update.remoteHandle = CXHandle(type: .generic, value: self.name  )
                    NotificationHandler.shared.isReceived = true
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
                    NotificationHandler.shared.fcmToken = fcmToken
                    NotificationHandler.shared.userID = UserId
                    NotificationHandler.shared.currentCallUUID = UUID(uuidString: (uuid ))
                    NotificationHandler.shared.callStatus = true
                    NotificationHandler.shared.dialerFoneId = dialerId
                    NotificationHandler.shared.dialerName = dialerName
                    NotificationHandler.shared.dialerImageUrl = dialerImageUrl
                    NotificationHandler.shared.isVideo = isVideoParam
                }
            }
            else if notificationType  == "UNA"
            {
                self.performsEndCallAction()
                NotificationHandler.shared.callStatus = false
            }
                
            else if notificationType  == "CE"
            {
                
                self.performsEndCallAction()
                NotificationHandler.shared.callStatus = false
            }
        }else {
            // fireRepeatingNotification(counter: 0)
        }
        print("My Video :",self.isVideo)
        if isVideoParam {
            self.isVideo = true
            self.btnHoldCall.isHidden = false
        }else{
            self.btnHoldCall.isHidden = true
            self.isVideo = false
            self.previewCallingView.isHidden = true
            self.previewView.isHidden = true
            self.remoteCallingView.isHidden = true
        }
        self.roomName = dialerName
        self.reportIncomingCall(uuid: UUID(), roomName: self.roomName) { _ in
            // Always call the completion handler when done.
            
        }
        
    }
    
    func incomingPushHandled() {
        print("e")
    }
    
    func fireRepeatingNotification(counter  : Int) {
        
        if counter > 15{
            return
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            
            UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
                var identifiers: [String] = []
                for notification:UNNotificationRequest in notificationRequests {
                    if notification.identifier == "identifierCancel" {
                        identifiers.append(notification.identifier)
                    }
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let content = UNMutableNotificationContent()
            
            if let callType = appDeleg.userInfo?["CallType"] as? String {
                var callTypeString = "video"
                if callType == "AD" {
                    callTypeString = "audio"
                }
                callTypeString += "  call"
                var notificationTitle = "You are receiving " + (callType == "AD" ? "an " :  "a ") + callTypeString
                if let dialerFoneId = appDeleg.userInfo?["DialerFoneID"] as? String {
                    notificationTitle += (" from " + dialerFoneId)
                }else {
                    notificationTitle += (" from someone")
                }
                content.title = notificationTitle
                content.body = "Tap to connect"
                content.categoryIdentifier = "ROOM_INVITATION"
                content.userInfo = appDeleg.userInfo ?? [ : ]
                //content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
                let identifier = "identifierCancel"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let theError = error {
                        print("Error posting local notification \(theError)")
                    }
                }
                AudioServicesPlaySystemSound(1003);
                self.fireRepeatingNotification(counter: counter + 1)
            }
            //DialerFoneID, RecieverFoneID
        }
    }
}


// MARK:- RemoteParticipantDelegate
extension VideoCallVC : RemoteParticipantDelegate {
    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has offered to share the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) published video track")
    }
    
    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has stopped sharing the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished video track")
    }
    
    func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has offered to share the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) published audio track")
    }
    
    func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) unpublished audio track")
    }
    
    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // The LocalParticipant is subscribed to the RemoteParticipant's video Track. Frames will begin to arrive now.
        
        
        //        let session = AVAudioSession.sharedInstance()
        //        var _: Error?
        //        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        //        try? session.setMode(AVAudioSession.Mode.voiceChat)
        //
        //        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        //
        //        try? session.setActive(true)
        
        logMessage(messageText: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")
        
        if self.isVideo {
            if (self.remoteParticipant == nil) {
                _ = renderRemoteParticipant(participant: participant)
            }
        }else{
            self.remoteCallingView.isHidden = true
            self.previewView.isHidden = true
            self.previewCallingView.isHidden = true
        }
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")
        
        if self.remoteParticipant == participant {
            // Find another Participant video to render, if possible.
            if var remainingParticipants = room?.remoteParticipants,
                let index = remainingParticipants.firstIndex(of: participant) {
                remainingParticipants.remove(at: index)
                renderRemoteParticipants(participants: remainingParticipants)
            }
        }
    }
    
    func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.
        if !(NotificationHandler.shared.callStatus ?? false){
            
            print("Call Connected")
            self.callConnectionStatus = true
        }
        else
        {
            if self.isIncommingCall {
                self.addCallLogAPI(status: "IC", notifType: "CR")
            }else{
                self.addCallLogAPI(status: "OC", notifType: "CR")
            }
        }

        self.isCallStarted = true
        //callerView.isHidden = true
        //Timer for call
        if NotificationHandler.shared.currentCallStatus == CurrentCallStatus.Incoming {
            statusLbl.text = "fone.me/\(NotificationHandler.shared.dialerFoneId ?? "")"
            self.UserNameLbl.text = NotificationHandler.shared.dialerName
            self.callerImage.sd_setImage(with: URL(string: NotificationHandler.shared.dialerImageUrl ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            statusLbl.isHidden = false
        }else {
            
        }
        self.player?.stop()
        self.timerLbl.isHidden = false
        self.runTimer()
        
        logMessage(messageText: "Subscribed to audio track for Participant \(participant.identity)")
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
        logMessage(messageText: "Unsubscribed from audio track for Participant \(participant.identity)")
    }
    
    func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled video track")
        self.remoteCallingView.isHidden = false
    }
    
    func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        self.remoteCallingView.isHidden = true
        self.previewView.isHidden = true
        logMessage(messageText: "Participant \(participant.identity) disabled video track")
    }
    
    func remoteParticipantDidEnableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled audio track")
    }
    
    func remoteParticipantDidDisableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled audio track")
    }
    
    func didFailToSubscribeToAudioTrack(publication: RemoteAudioTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }
    
    func didFailToSubscribeToVideoTrack(publication: RemoteVideoTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
    
    func addCallLogAPI(status : String , notifType : String)
    {
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM/dd/yyyy HH:mm:ss a"
        let dateTime = formatter.string(from: yourDate ?? Date())
        var params = ["":""] as [String : Any]
        if self.isIncommingCall {
            params = ["ReceiverId": NotificationHandler.shared.receiverId ?? "",
                          "CallConnectionId": NotificationHandler.shared.callStatusLogId ?? "",
                          "ReceiverStatus": status,
                          "CallReceivingTime" : dateTime,
                          "NotificationType"  : notifType
                ]
        }else{
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    params = ["ReceiverId": user.userId ?? "",
                              "CallConnectionId": NotificationHandler.shared.callStatusLogId ?? "",
                              "ReceiverStatus": status,
                              "CallReceivingTime" : dateTime,
                              "NotificationType"  : notifType
                    ]
                    
                }
            }
        }
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(addCallLogUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                
                print(json)
                
            }
        }
    }
    
}

// MARK:- VideoViewDelegate
extension VideoCallVC : VideoViewDelegate {
    func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
    func videoViewDidReceiveData(view: VideoView) {
        print("My Checking")
        if (self.remoteCallingView == view) {
        }
    }
}

// MARK:- CameraSourceDelegate
extension VideoCallVC : CameraSourceDelegate {
    func cameraSourceDidFail(source: CameraSource, error: Error) {
        logMessage(messageText: "Camera source failed with error: \(error.localizedDescription)")
    }
}



// MARK:- RoomDelegate
extension VideoCallVC : RoomDelegate {
    func roomDidConnect(room: Room) {
        // At the moment, this example only supports rendering one Participant at a time.
        print(room.name)
        logMessage(messageText: "Connected to room \(room.name) as \(room.localParticipant?.identity ?? "")")
        
        // This example only renders 1 RemoteVideoTrack at a time. Listen for all events to decide which track to render.
        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = self
        }
        
        let cxObserver = callKitCallController.callObserver
        let calls = cxObserver.calls
        
        // Let the call provider know that the outgoing call has connected
        if let uuid = room.uuid, let call = calls.first(where:{$0.uuid == uuid}) {
            if call.isOutgoing {
                callKitProvider.reportOutgoingCall(with: uuid, connectedAt: nil)
            }
        }
        
        self.callKitCompletionHandler!(true)
        if self.isIncommingCall == false {
            self.loadViewIfNeeded()
            //sendVOIPNotification()
            
        }
        
        if !NotificationHandler.shared.isReceived {
            
            self.sendVOIPNotification(voipToken: self.roomVOIPToken, roomName: room.name, uuid: room.uuid!.uuidString, fcmToken: self.roomFCMToken) { (success) in
                if success {
//                    self.sendVOIPNotification(voipToken: self.roomVOIPToken, roomName: room.name, uuid: room.uuid!.uuidString, fcmToken: self.roomFCMToken) { (success) in
//                        if success {
//
//                        }
                 //   }
                }
            }
        }
        
        
        
    }
    
    func roomDidDisconnect(room: Room, error: Error?) {
        logMessage(messageText: "Disconnected from room \(room.name), error = \(String(describing: error))")
        
        if !self.userInitiatedDisconnect, let uuid = room.uuid, let error = error {
            var reason = CXCallEndedReason.remoteEnded
            
            if (error as NSError).code != TwilioVideoSDK.Error.roomRoomCompletedError.rawValue {
                reason = .failed
            }
            
            self.callKitProvider.reportCall(with: uuid, endedAt: nil, reason: reason)
        }
        
        self.room = nil
        self.callKitCompletionHandler = nil
        self.callKitProvider.invalidate()
        self.userInitiatedDisconnect = false
    }
    
    func roomDidFailToConnect(room: Room, error: Error) {
        logMessage(messageText: "Failed to connect to room with error: \(error.localizedDescription)")
        self.callKitProvider.invalidate()
        self.callKitCompletionHandler!(false)
        self.room = nil
        self.player?.stop()
        self.showCustomAlert(title: "Error", message: "Failed to connect to room with error: \(error.localizedDescription)") { (alert) in
            self.disconnect(sender: UIButton())
        }
    }
    
    func roomIsReconnecting(room: Room, error: Error) {
        logMessage(messageText: "Reconnecting to room \(room.name), error = \(String(describing: error))")
    }
    
    func roomDidReconnect(room: Room) {
        logMessage(messageText: "Reconnected to room \(room.name)")
    }
    
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        // Listen for events from all Participants to decide which RemoteVideoTrack to render.
        participant.delegate = self
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
        self.roomFCMToken = ""
        self.disconnect(sender: UIButton())
        // Nothing to do in this example. Subscription events are used to add/remove renderers.
    }
}
