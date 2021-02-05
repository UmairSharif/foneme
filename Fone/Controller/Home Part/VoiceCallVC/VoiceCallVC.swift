//
//  VoiceCallVC.swift
//  Fone
//
//  Created by Bester on 16/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import PushKit
import CallKit
import Alamofire
import SwiftyJSON
import TwilioVoice
import AVFoundation

let accessTokenEndpoint = "/accesstoken"
let identity = "AliceIdentity"
let twimlParamTo = "to"

class VoiceCallVC: UIViewController {

    @IBOutlet weak var stackCALL: UIStackView!
    //IBOutlet and Variables
    var callTo : String?
    
    @IBOutlet var callBtn: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var callerImage: UIImageView!
    @IBOutlet weak var timerLbl : UILabel!
    
    var mute = false
    var userImage : String?
    var deviceTokenString: String?
    var accessTokenResponse: String?
    
    var voipRegistry: PKPushRegistry
    var incomingPushCompletionCallback: (()->Swift.Void?)? = nil
    
    var isSpinning: Bool
    var incomingAlertController: UIAlertController?
    var timer: Timer?
    var seconds = Int()
    var callInvite: TVOCallInvite?
    var call: TVOCall?
    var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil
    var audioDevice: TVODefaultAudioDevice = TVODefaultAudioDevice()
    
    let callKitProvider: CXProvider
    let callKitCallController: CXCallController
    var userInitiatedDisconnect: Bool = false
    var isLoudeSpeakerOn: Bool = true
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    
    required init?(coder aDecoder: NSCoder) {
        isSpinning = false
        voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        let configuration = CXProviderConfiguration(localizedName: "Fone")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.ringtoneSound = "iphone-original.caf"
        if let callKitIcon = UIImage(named: "iconMask80") {
            configuration.iconTemplateImageData = callKitIcon.pngData()
        }
        
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
        
        super.init(coder: aDecoder)
        
        //callKitProvider.setDelegate(self, queue: nil)
        
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
    }
    
    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        callKitProvider.invalidate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        TwilioVoice.audioDevice = audioDevice
        
        //Setup Permission
        permissionSetup()
        
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        network.reachability.whenReachable = { reachability in
                       
                   self.netStatus = true
                   UserDefaults.standard.set("Yes", forKey: "netStatus")
                   UserDefaults.standard.synchronize()
               }
                  
               network.reachability.whenUnreachable = { reachability in
               
                   self.netStatus = false
                   UserDefaults.standard.set("No", forKey: "netStatus")
                   UserDefaults.standard.synchronize()
                 
                   let alertController = UIAlertController(title: "No Internet!", message: "Please connect your device to the internet.", preferredStyle: .alert)
                           
                   let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                       
                   }

                   alertController.addAction(action1)
                   self.present(alertController, animated: true, completion: nil)
                   
                   }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
    
       self.timerLbl.isHidden = true
       self.seconds = 86400
        self.callerImage.sd_setImage(with: URL(string: userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        DispatchQueue.main.async {
            self.callerImage.layer.cornerRadius = self.callerImage.frame.height/2
            self.callerImage.layer.masksToBounds = true
        }
      
    }
    
    
    func runTimer() {
         timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: #selector(updateTimer), userInfo: nil, repeats: true)
     }
     
     @objc func updateTimer() {
         
         seconds += 1
         self.timerLbl.text = timeString(time: TimeInterval(seconds))
         
     }
     

     func timeString(time:TimeInterval) -> String {
    
         _ = Int(time) / 3600
         let minutes = Int(time) / 60 % 60
         let seconds = Int(time) % 60
         return String(format:"%02i:%02i",minutes,seconds)
     }
    
    func permissionSetup()
    {
        let uuid = UUID()
        var handle = "Voice Bot"
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                handle = user.mobile ?? ""
            }
        }
        
        
        self.checkRecordPermission { (permissionGranted) in
                        if (!permissionGranted) {
                            let alertController: UIAlertController = UIAlertController(title: "Voice Quick Start",
                                                                                       message: "Microphone permission not granted",
                                                                                       preferredStyle: .alert)
                            
                            let continueWithMic: UIAlertAction = UIAlertAction(title: "Continue without microphone",
                                                                               style: .default,
                                                                               handler: { (action) in
                                                                                self.performStartCallAction(uuid: uuid, handle: handle)
                            })
                            alertController.addAction(continueWithMic)
                            
                            let goToSettings: UIAlertAction = UIAlertAction(title: "Settings",
                                                                            style: .default,
                                                                            handler: { (action) in
                                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                                          options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                                                                                          completionHandler: nil)
                            })
                            alertController.addAction(goToSettings)
                            
                            let cancel: UIAlertAction = UIAlertAction(title: "Cancel",
                                                                      style: .cancel,
                                                                      handler: { (action) in
                                                                        self.toggleUIState(isEnabled: true, showCallControl: false)
        //                                                                self.stopSpin()
                            })
                            alertController.addAction(cancel)
                            
                            self.present(alertController, animated: true, completion: nil)
                        } else {
                            self.performStartCallAction(uuid: uuid, handle: handle)
                        }
                    }
    }
    

     func sendCallNotificationAPI()
       {
           var userId : String?
           var dialerNumber : String?
           
           if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
               print(userProfileData)
               if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                   userId = user.userId
                   dialerNumber = user.mobile
               }
           }
           
           let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
           let params = ["DialerNumber": dialerNumber ?? "",
                         "ReceiverNumber": callTo ?? "",
                         "Status": "OG",
                         "CallType" : "AD",
                         "AppType" : "IOS",
                         "ChannelName" : dialerNumber ?? "",
                         "UserId" : userId ?? "",
                         "CallStatusType": ""
               ] as [String:Any]
           
           print("params: \(params)")
           
           var headers = [String:String]()
           headers = ["Content-Type": "application/json",
                      "Authorization" : "bearer " + loginToken!]
           
           ServerCall.makeCallWitoutFile(sendCallNotificationUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
               
               if let json = response {
                  
                   print(json)
                   
               }
           }
       }
}

extension VoiceCallVC: PKPushRegistryDelegate {
    
    func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
        let permissionStatus: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case AVAudioSessionRecordPermission.granted:
            // Record permission already granted.
            completion(true)
            break
        case AVAudioSessionRecordPermission.denied:
            // Record permission denied.
            completion(false)
            break
        case AVAudioSessionRecordPermission.undetermined:
            // Requesting record permission.
            // Optional: pop up app dialog to let the users know if they want to request.
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                completion(granted)
            })
            break
        default:
            completion(false)
            break
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        NSLog("pushRegistry:didUpdatePushCredentials:forType:")
        
        if (type != .voIP) {
            return
        }
        
        self.fetchAccessToken { (accessToken) in
            self.accessTokenResponse = accessToken
            guard let accessToken = self.accessTokenResponse else {
                return
            }
            
            let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
            
            TwilioVoice.register(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
                if let error = error {
                    NSLog("An error occurred while registering: \(error.localizedDescription)")
                }
                else {
                    NSLog("Successfully registered for VoIP push notifications.")
                }
            }
            
            self.deviceTokenString = deviceToken
        }

    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
        
        if (type != .voIP) {
            return
        }
        
        self.fetchAccessToken { (accessToken) in
            self.accessTokenResponse = accessToken
            guard let deviceToken = self.deviceTokenString, let accessToken = self.accessTokenResponse else {
                return
            }
            
            TwilioVoice.unregister(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
                if let error = error {
                    NSLog("An error occurred while unregistering: \(error.localizedDescription)")
                }
                else {
                    NSLog("Successfully unregistered from VoIP push notifications.")
                }
            }
            
            self.deviceTokenString = nil
        }
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")
        
        if (type == PKPushType.voIP) {
            // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
            TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
            //TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self)
        }
        
        if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
            // Save for later when the notification is properly handled.
            self.incomingPushCompletionCallback = completion
        } else {
            /**
             * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
             * CallKit and fulfill the completion before exiting this callback method.
             */
            completion()
        }
    }
    
    func incomingPushHandled() {
        if let completion = self.incomingPushCompletionCallback {
            completion()
            self.incomingPushCompletionCallback = nil
        }
    }
    
    func fetchAccessToken(completion: @escaping (String) -> ()) {

//        var sender = ""
//        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
//            print(userProfileData)
//            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
//                sender = user.mobile ?? ""
//            }
//        }
        
        var userId : String?
        var dialerNumber : String?
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
                dialerNumber = user.mobile
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")

        var token: String = ""
        let parameters: Parameters = [
            "AccessToken": loginToken! as Any,
            "UserId": userId! as Any,
            "ChannelName": dialerNumber! as Any
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer " + loginToken!,
        ]
        
        print(parameters)
        print(headers)

        let api = "http://zwilio.com/api/account/v1/tokenforcall"
        Alamofire.request(api, method: .post, parameters: parameters, encoding: JSONEncoding.default,headers: headers).responseString { response in
            guard let dataresponse = response as? DataResponse<String> else {return}
            
            if let result = dataresponse.data{
                let json = JSON(result)
                print(json)
                token = json["JWTVoice"].stringValue
                completion(token)
            }
        }
    }
}


extension VoiceCallVC: TVONotificationDelegate {
    func notificationError(_ error: Error) {
        print(error.localizedDescription)
    }
    
    
    func callInviteReceived(_ callInvite: TVOCallInvite) {
        NSLog("callInviteReceived:")
        
        var from:String = callInvite.from ?? "Voice Bot"
        from = from.replacingOccurrences(of: "client:", with: "")
        
        if (self.callInvite != nil) {
            NSLog("A CallInvite is already in progress. Ignoring the incoming CallInvite from \(from)")
            if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
                self.incomingPushHandled()
            }
            return;
        } else if (self.call != nil) {
            NSLog("Already an active call.");
            NSLog("  >> Ignoring call from \(from)");
            if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
                self.incomingPushHandled()
            }
            return;
        }
        
        self.callInvite = callInvite
        
        reportIncomingCall(from: from, uuid: callInvite.uuid)
    }
    
    func reportIncomingCall(from: String, uuid: UUID) {
        let callHandle = CXHandle(type: .generic, value: from)
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        callKitProvider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                NSLog("Failed to report incoming call successfully: \(error.localizedDescription).")
            } else {
                NSLog("Incoming call successfully reported.")
            }
        }
    }
    
    func cancelledCallInviteReceived(_ cancelledCallInvite: TVOCancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")

        if (self.callInvite == nil ||
            self.callInvite!.callSid != cancelledCallInvite.callSid) {
            NSLog("No matching pending CallInvite. Ignoring the Cancelled CallInvite")
            return
        }

        performEndCallAction(uuid: self.callInvite!.uuid)

        self.callInvite = nil

    }
    
    func performEndCallAction(uuid: UUID) {
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        self.timer?.invalidate()
        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                NSLog("EndCallAction transaction request successful")
            }
        }
    }
}

extension VoiceCallVC: TVOCallDelegate {
    
    func callDidStartRinging(_ call: TVOCall) {
            NSLog("callDidStartRinging:")
            
    //        self.placeCallButton.setTitle("Ringing", for: .normal)
        }
        
        func callDidConnect(_ call: TVOCall) {
            self.call = call
            self.callKitCompletionCallback!(true)
            self.callKitCompletionCallback = nil
            
    //        self.placeCallButton.setTitle("Hang Up", for: .normal)
            
            toggleUIState(isEnabled: true, showCallControl: true)
    //        stopSpin()
            toggleAudioRoute(toSpeaker: true)
            
            //Send call Notification
            self.sendCallNotificationAPI()
        }
        
        func callDidReconnect(_ call: TVOCall) {
            NSLog("callDidReconnect:")
            
    //        self.placeCallButton.setTitle("Hang Up", for: .normal)
            
            toggleUIState(isEnabled: true, showCallControl: true)
        }
        
        func call(_ call: TVOCall, isReconnectingWithError error: Error) {
            NSLog("call:isReconnectingWithError:")
            
    //        self.placeCallButton.setTitle("Reconnecting", for: .normal)
            
            toggleUIState(isEnabled: false, showCallControl: false)
        }
        
        // MARK: AVAudioSession
        func toggleAudioRoute(toSpeaker: Bool) {
            // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
            audioDevice.block = {
                kTVODefaultAVAudioSessionConfigurationBlock()
                do {
                    if (toSpeaker) {
                        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                    } else {
                        try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                    }
                } catch {
                    NSLog(error.localizedDescription)
                }
            }
            audioDevice.block()
        }
        
        
        func toggleUIState(isEnabled: Bool, showCallControl: Bool) {
            //callBtn.isEnabled = isEnabled
            if (showCallControl) {
    //            callControlView.isHidden = false
    //            muteSwitch.isOn = false
    //            speakerSwitch.isOn = true
            } else {
    //            callControlView.isHidden = true
            }
        }
        
        func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
            NSLog("Call failed to connect: \(error.localizedDescription)")
            
            if let completion = self.callKitCompletionCallback {
                completion(false)
            }
            
            performEndCallAction(uuid: call.uuid)
            callDisconnected()
        }
        
        func callDisconnected() {
            self.call = nil
            self.callKitCompletionCallback = nil
            self.userInitiatedDisconnect = false
            
    //        stopSpin()
            toggleUIState(isEnabled: true, showCallControl: false)
            dismiss(animated: true) {}
            //self.callBtn.setTitle("Call", for: .normal)
        }
        
        func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
            if let error = error {
                NSLog("Call failed: \(error.localizedDescription)")
            } else {
                NSLog("Call disconnected")
            }
            self.timer?.invalidate()
            if !self.userInitiatedDisconnect {
                var reason = CXCallEndedReason.remoteEnded
                
                if error != nil {
                    reason = .failed
                }
                
                self.callKitProvider.reportCall(with: call.uuid, endedAt: Date(), reason: reason)
            }
            
            callDisconnected()
        }
}

extension VoiceCallVC {
    
    // MARK: CXProviderDelegate
    
    func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        audioDevice.isEnabled = true
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        self.dismiss(animated: true, completion: nil)
        NSLog("provider:didDeactivateAudioSession:")
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")
        
        toggleUIState(isEnabled: false, showCallControl: false)
//        startSpin()
        
        audioDevice.isEnabled = false
        audioDevice.block();
        
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        
        var sender = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                sender = user.mobile ?? ""
            }
        }
        self.timerLbl.isHidden = false
        self.runTimer()
        self.performVoiceCall(uuid: action.callUUID, client: sender) { (success) in
            if (success) {
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }
    
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("provider:performAnswerCallAction:")
        
        assert(action.callUUID == self.callInvite?.uuid)
        
        audioDevice.isEnabled = false
        audioDevice.block();
        
        self.performAnswerVoiceCall(uuid: action.callUUID) { (success) in
            if (success) {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        
        if (self.callInvite != nil) {
            self.callInvite!.reject()
            self.callInvite = nil
        } else if (self.call != nil) {
            self.call?.disconnect()
        }
        
        audioDevice.isEnabled = true
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provider:performSetHeldAction:")
        if (self.call?.state == .connected) {
            self.call?.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    // MARK: Call Kit Actions
    func performStartCallAction(uuid: UUID, handle: String) {
       
        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)
        //CXErrorCodeRequestTransactionError.emptyTransaction
        callKitCallController.request(transaction)  { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }
            
            NSLog("StartCallAction transaction request successful")
            
            let callUpdate = CXCallUpdate()
            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false
            
            self.callKitProvider.reportCall(with: uuid, updated: callUpdate)
        }
    }
    
    func performVoiceCall(uuid: UUID, client: String?, completionHandler: @escaping (Bool) -> Swift.Void) {
        
        self.fetchAccessToken { (accessToken) in
            self.accessTokenResponse = accessToken
            guard let accessToken = self.accessTokenResponse else {
                completionHandler(false)
                return
            }

//            let reciever = "callto" + (self.callTo ?? "")
  
            let reciever = self.callTo ?? ""

            let connectOptions: TVOConnectOptions = TVOConnectOptions(accessToken: accessToken) { (builder) in
                builder.params = [twimlParamTo : reciever,"To": reciever]
                builder.uuid = uuid
            }
            
            self.call = TwilioVoice.connect(with: connectOptions, delegate: self)
            self.callKitCompletionCallback = completionHandler
        }
    }
    
    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {
        
        let acceptOptions: TVOAcceptOptions = TVOAcceptOptions(callInvite: self.callInvite!) { (builder) in
            builder.uuid = self.callInvite?.uuid
        }
        self.call = self.callInvite?.accept(with: acceptOptions, delegate: self)
        self.callInvite = nil
        self.callKitCompletionCallback = completionHandler
        if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
            self.incomingPushHandled()
        }
    }
    
//    @IBAction func muteSwitchToggled(_ sender: UISwitch) {
//        if let call = call {
//            call.isMuted = sender.isOn
//        } else {
//            NSLog("No active call to be muted")
//        }
//    }
    
    @IBAction func speakerBtnTapped(_ sender: Any) {
           if mute {
               mute = false
               self.speakerButton.setImage(UIImage(named: "SpeekerSel"), for: UIControl.State.normal)
               let session = AVAudioSession.sharedInstance()
               var _: Error?
               try? session.setCategory(AVAudioSession.Category.playAndRecord)
               try? session.setMode(AVAudioSession.Mode.voiceChat)
               try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
               try? session.setActive(true)
           }
           else if !mute
           {
               
               mute = true
               self.speakerButton.setImage(UIImage(named: "SpeekNormal"), for: UIControl.State.normal)
               let session = AVAudioSession.sharedInstance()
               var _: Error?
               try? session.setCategory(AVAudioSession.Category.playAndRecord)
               try? session.setMode(AVAudioSession.Mode.voiceChat)
               try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
               try? session.setActive(true)
           }
       }
    
    @IBAction func endBtnTapped(_ sender : UIButton)
    {
        
        
        if let call = call {
            stackCALL.alpha = 0.5
            call.disconnect()
        }else {
            
            
            stackCALL.alpha = 0.5
            sleep(2)

            self.dismiss(animated: true, completion: nil)
        }
    }
}
