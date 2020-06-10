//
//  VoiceCallVC.swift
//  Fone
//
//  Created by Bester on 09/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import CallKit
import PushKit
import AVFoundation
import TwilioVideo
import SwiftyJSON
import TwilioVoice

class VideoCallVC: UIViewController {

    //IBOutlet and Variables
    @IBOutlet weak var remoteView: TVIVideoView!
    @IBOutlet weak var previewView: TVIVideoView!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var timerLbl : UILabel!
    @IBOutlet weak var callerImage: UIImageView!
    
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var remoteParticipant: TVIRemoteParticipant?
    var roomName = String()
    var channelName : String?
    var otherVoideUserNumber : String?
    var otherUserIncomingNumber = ""
    var player: AVAudioPlayer?
    var name = ""
    var mute = false
    var recieverNumber : String?
    var userImage : String?
    var timer: Timer?
    var seconds = Int()
    var callConnectionStatus : Bool = false
    var cxCallController = CXCallController()
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    
    var isVideo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide Remote and Previews
         remoteView.isHidden = true
         previewView.isHidden = true
        
        //Setup UI
        setupUI()
        
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
        
        if !(NotificationHandler.shared.callStatus ?? false)
        {
            let dialerImageUrl = NotificationHandler.shared.dialerImageUrl
            self.callerImage.sd_setImage(with: URL(string: dialerImageUrl ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        else
        {
            self.callerImage.sd_setImage(with: URL(string: userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        
        self.timerLbl.isHidden = true
        self.seconds = 86400
    }
    

    func setupUI()
    {
        //Get Call Token API
        getTokenAPI()
    }
    
    
    func getTokenAPI()
    {
        var userId : String?
        
        if !(NotificationHandler.shared.callStatus ?? false){
            //roomName = recieverNumber ?? ""
            
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    roomName = user.mobile ?? ""
                }
            }
        }
        else
        {
            roomName = NotificationHandler.shared.channelName ?? ""
        }
        
        print(roomName)
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                       print(userProfileData)
                       if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                           userId = user.userId
                       }
                   }
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["AccessToken": loginToken!,
                      "UserId": userId!,
                      "ChannelName": roomName
            ] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(getCallTokenUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                
                let token = json["JWTToken"].string ?? ""
                UserDefaults.standard.set(token, forKey: "token")
                UserDefaults.standard.synchronize()
                
                if !(NotificationHandler.shared.callStatus ?? false)
                {
                    //Send call Notification
                    self.sendCallNotificationAPI()
                }
                
                self.configureSetup(token : token)
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
                      "ReceiverNumber": recieverNumber ?? "",
                      "Status": "OG",
                      "CallType" : "AD",
                      "AppType" : "IOS",
                      "ChannelName" : dialerNumber ?? "",
                      "UserId" : userId ?? "",
                      "CallStatusType": "APPTOAPP"
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
    
    
    func playSound() {
        DispatchQueue.main.async {
            guard let url = Bundle.main.url(forResource: "telephone", withExtension: "mp3") else { return }
            
            do {
                //try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                
                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                
                /* iOS 10 and earlier require the following line:
                 player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
                
                guard let player = self.player else { return }
                
                player.play()
                
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
    }
    

    func configureSetup(token : String){
           
           // Prepare local media which we will share with Room Participants.
           self.prepareLocalMedia()
           
           // Preparing the connect options with the access token that we fetched (or hardcoded).
           let connectOptions = TVIConnectOptions.init(token: token) { (builder) in
               
               // Use the local media that we prepared earlier.
               builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
               builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
               
               // Use the preferred audio codec
               if let preferredAudioCodec = Settings.shared.audioCodec {
                   builder.preferredAudioCodecs = [preferredAudioCodec]
               }
               
               // Use the preferred video codec
               if let preferredVideoCodec = Settings.shared.videoCodec {
                   builder.preferredVideoCodecs = [preferredVideoCodec]
               }
               
               // Use the preferred encoding parameters
               if let encodingParameters = Settings.shared.getEncodingParameters() {
                   builder.encodingParameters = encodingParameters
               }
               
               // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
               // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
               builder.roomName = self.roomTextField.text
           }
           
           // Connect to the Room using the options we provided.
           room = TwilioVideo.connect(with: connectOptions, delegate: self)
           logMessage(messageText: "Attempting to connect to room \(String(describing: self.roomTextField.text))")
           
           self.showRoomUI(inRoom: true)
           self.dismissKeyboard()
       }
    
    func dismissKeyboard() {
        if (self.roomTextField.isFirstResponder) {
            self.roomTextField.resignFirstResponder()
        }
    }
    
     func logMessage(messageText: String) {
           var messageLabel = String()
           messageLabel = messageText
           print(messageLabel)
       }
       
       // Update our UI based upon if we are in a Room or not
       func showRoomUI(inRoom: Bool) {
           // self.connectButton.isHidden = inRoom
           self.roomTextField.isHidden = inRoom
           // self.roomLine.isHidden = inRoom
           //self.roomLabel.isHidden = inRoom
        //   self.speakerButton.isHidden = !inRoom
        //   self.disconnectButton.isHidden = !inRoom
           // self.navigationController?.setNavigationBarHidden(inRoom, animated: true)
           UIApplication.shared.isIdleTimerDisabled = inRoom
       }

    func prepareLocalMedia() {
        
        // We will share local audio and video when we connect to the Room.
        
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init(options: nil, enabled: true, name: "Microphone")
            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
        
        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            self.startPreview()
        }
    }
    
    // MARK: Private
    func startPreview() {
        // Preview our local camera track in the local video preview view.
        camera = TVICameraCapturer(source: .frontCamera, delegate: self)
        localVideoTrack = TVILocalVideoTrack.init(capturer: camera!, enabled: false, constraints: nil, name: "Camera")
        if (localVideoTrack == nil) {
            logMessage(messageText: "Failed to create video track")
        } else {
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            
            logMessage(messageText: "Video track created")
            
        }
    }
    
    @IBAction func speakerBtnTapped(_ sender: Any) {
        if mute {
            mute = false
            self.speakerButton.setImage(UIImage(named: "ic_loaud_selected"), for: UIControl.State.normal)
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
            self.speakerButton.setImage(UIImage(named: "ic_loaud"), for: UIControl.State.normal)
            let session = AVAudioSession.sharedInstance()
            var _: Error?
            try? session.setCategory(AVAudioSession.Category.playAndRecord)
            try? session.setMode(AVAudioSession.Mode.voiceChat)
            
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            
            try? session.setActive(true)
            
        }
    }
    
    @IBAction func disconnectCallBtnTapped(_ sender: Any) {
           
        self.room?.disconnect()
        player?.stop()
        performEndCallAction()
        //NotificationHandler.shared.callStatus = false
        logMessage(messageText: "Attempting to disconnect from room \(room?.name ?? "")")
        self.timer?.invalidate()
        
        if !(NotificationHandler.shared.callStatus ?? false)
        {
            self.dialerSendNotificationAPI()
        }
        else
        {
            self.recevierSendNotificationAPI()
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
    
    func performEndCallAction() {
        
        for call in self.cxCallController.callObserver.calls {
            
            let endCallAction = CXEndCallAction(call: call.uuid)
            let transaction = CXTransaction(action: endCallAction)
            
            cxCallController.request(transaction) { error in
                if let error = error {
                    NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
                    return
                }
                
                NSLog("EndCallAction transaction request successful")
                
            }
            
        }
    }
    
    func cleanupRemoteParticipant() {
        if ((self.remoteParticipant) != nil) {
            if ((self.remoteParticipant?.videoTracks.count)! > 0) {
                let remoteVideoTrack = self.remoteParticipant?.remoteVideoTracks[0].remoteTrack
                remoteVideoTrack?.removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        performEndCallAction()
        self.remoteParticipant = nil
        self.navigationController?.popViewController(animated: true)
    }
}


// MARK: TVIRoomDelegate
extension VideoCallVC : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        playSound()
        // At the moment, this example only supports rendering one Participant at a time.
        print(room.name,room.remoteParticipants.count,room.sid,room.state.rawValue)
        logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants[0]
            self.remoteParticipant?.delegate = self
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")
        
        player?.stop()
        self.cleanupRemoteParticipant()
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        player?.stop()
        logMessage(messageText: "Failed to connect to room with error")
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if (self.remoteParticipant == nil) {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
        }
        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        if (self.remoteParticipant == participant) {
            cleanupRemoteParticipant()
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIRemoteParticipantDelegate
extension VideoCallVC : TVIRemoteParticipantDelegate {
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedVideoTrack publication: TVIRemoteVideoTrackPublication) {
        
        // Remote Participant has offered to share the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) video track")
        print(participant.identity,publication.trackName)
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedVideoTrack publication: TVIRemoteVideoTrackPublication) {
        
        // Remote Participant has stopped sharing the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedAudioTrack publication: TVIRemoteAudioTrackPublication) {
        
        // Remote Participant has offered to share the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) audio track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedAudioTrack publication: TVIRemoteAudioTrackPublication) {
        
        // Remote Participant has stopped sharing the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }
    
    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's video frames now.
                
        if (self.remoteParticipant == participant) {
            remoteView.isHidden = true
            videoTrack.addRenderer(self.remoteView!)
        }
        
    }
    
    func unsubscribed(from videoTrack: TVIRemoteVideoTrack,
                      publication: TVIRemoteVideoTrackPublication,
                      for participant: TVIRemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        statusLbl.isHidden = true
        player?.stop()
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")
        
        if (self.remoteParticipant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }
    
    func subscribed(to audioTrack: TVIRemoteAudioTrack,
                    publication: TVIRemoteAudioTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.
        
       if !(NotificationHandler.shared.callStatus ?? false){
              
             print("Call Connected")
             self.callConnectionStatus = true
        }
        else
        {
            
//            let callLog = HKCallLogHandler.shared
//            callLog.name = self.name
//            callLog.number = self.otherUserIncomingNumber
//            callLog.callType = "incoming"
            
            self.addCallLogAPI()
        }
        
        //callerView.isHidden = true
        //Timer for call
        self.timerLbl.isHidden = false
        self.runTimer()
        statusLbl.isHidden = true
        player?.stop()
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        
        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        
        try? session.setActive(true)
        logMessage(messageText: "Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    func unsubscribed(from audioTrack: TVIRemoteAudioTrack,
                      publication: TVIRemoteAudioTrackPublication,
                      for participant: TVIRemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) audio track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) audio track")
    }
    
    func failedToSubscribe(toAudioTrack publication: TVIRemoteAudioTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }
    
    func failedToSubscribe(toVideoTrack publication: TVIRemoteVideoTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}

// MARK: TVIVideoViewDelegate
extension VideoCallVC : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension VideoCallVC : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        self.previewView.shouldMirror = (source == .frontCamera)
    }
}

extension VideoCallVC
{
    func addCallLogAPI()
    {
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "MMM/dd/yyyy HH:mm:ss a"
        let dateTime = formatter.string(from: yourDate ?? Date())
        
       let params = ["ReceiverId": NotificationHandler.shared.receiverId ?? "",
                  "CallConnectionId": NotificationHandler.shared.callStatusLogId ?? "",
                  "ReceiverStatus": "IC",
                  "CallReceivingTime" : dateTime,
                  "NotificationType"  : "CR"
        ] as [String:Any]?
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(addCallLogUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                
                print(json)
                
            }
        }
    }
    
    func recevierSendNotificationAPI(){
        
        let parameter = [
            "SenderMobileNumber" : NotificationHandler.shared.receiverNumber ?? "",
            "NotificationType" : "CE",
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
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func dialerSendNotificationAPI(){
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
            self.dismiss(animated: true, completion: nil)
        }
    }
}
