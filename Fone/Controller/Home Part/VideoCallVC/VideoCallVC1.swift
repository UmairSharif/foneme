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

class VideoCallVC1: UIViewController {

    //IBOutlet and Variables
    @IBOutlet weak var remoteView: VideoView!
    @IBOutlet weak var previewView: VideoView!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var timerLbl : UILabel!
    @IBOutlet weak var callerImage: UIImageView!
    @IBOutlet weak var UserNameLbl: UILabel!
    var room: Room?
    var camera: CameraSource?
    var localVideoTrack: LocalVideoTrack?
    var localAudioTrack: LocalAudioTrack?
    var remoteParticipant: RemoteParticipant?
    var roomName = String()
    var channelName : String?
    var otherVoideUserNumber : String?
    var otherUserIncomingNumber = ""
    var player: AVAudioPlayer?
    var name = ""
    var mute = false
    var recieverNumber : String?
    var DialerFoneID = ""
    var userImage : String?
    var timer: Timer?
    var seconds = Int()
    var callConnectionStatus : Bool = false
    var cxCallController = CXCallController()
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    
    var isVideo: Bool?
    
    deinit {
        // We are done with camera
        if let camera = self.camera {
            camera.stopCapture()
            self.camera = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callerImage.layer.cornerRadius = callerImage.frame.size.height / 2
        callerImage.clipsToBounds = true
        UserNameLbl.text = self.name
        
        // Hide Remote and Previews
        
        if isVideo == true {
            remoteView.isHidden = false
            previewView.isHidden = false
        }else {
            remoteView.isHidden = true
            previewView.isHidden = true
        }
        
        previewView.contentMode = .scaleAspectFill
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
        if NotificationHandler.shared.currentCallStatus == CurrentCallStatus.Incoming {
            statusLbl.text = "calling to fone.me/\(NotificationHandler.shared.dialerFoneId ?? "")"
        }else {
            statusLbl.text = "calling to fone.me/\(DialerFoneID)"
        }
        if !(NotificationHandler.shared.callStatus ?? false)
        {
            _ = NotificationHandler.shared.dialerImageUrl
            self.callerImage.sd_setImage(with: URL(string: userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        else
        {
            self.callerImage.sd_setImage(with: URL(string: userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        //callerImage.layer.cornerRadius = callerImage.bounds.size.width/2.0
        callerImage.layer.masksToBounds = true
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
        var type = "AD"
        if self.isVideo == true {
            type = "VD"
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["DialerNumber": dialerNumber ?? "",
                      "ReceiverNumber": recieverNumber ?? "",
                      "Status": "OG",
                      "CallType" : type,
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
               builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [LocalVideoTrack]()
               
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

               // Use the preferred signaling region
               if let signalingRegion = Settings.shared.signalingRegion {
                   builder.region = signalingRegion
               }
            
            builder.bandwidthProfileOptions = bandwidthProfileOptions
            
               // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
               // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
               builder.roomName = self.roomTextField.text
           }
           
           // Connect to the Room using the options we provided.
           room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)
//           logMessage(messageText: "Attempting to connect to room \(String(describing: self.roomTextField.text))")
           
           self.showRoomUI(inRoom: true)
           self.dismissKeyboard()
       }
    
    func dismissKeyboard() {
        if (self.roomTextField.isFirstResponder) {
            self.roomTextField.resignFirstResponder()
        }
    }
    
//     func logMessage(messageText: String) {
//           var messageLabel = String()
//           messageLabel = messageText
//           print(messageLabel)
//       }
    
    func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        // This example renders the first subscribed RemoteVideoTrack from the RemoteParticipant.
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteVideoView()
                subscribedVideoTrack.addRenderer(self.remoteView!)
                self.remoteParticipant = participant
                return true
            }
        }
        return false
    }
    
    func setupRemoteVideoView() {
        if isVideo == true {
            self.remoteView.isHidden = false
        }else {
            self.remoteView.isHidden = true
        }
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
            localAudioTrack = LocalAudioTrack.init(options: nil, enabled: true, name: "Microphone")
            if (localAudioTrack == nil) {
                //logMessage(messageText: "Failed to create audio track")
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
        
        let frontCamera = CameraSource.captureDevice(position: .front)
        let backCamera = CameraSource.captureDevice(position: .back)

        if (frontCamera != nil || backCamera != nil) {

            let options = CameraSourceOptions { (builder) in
                // To support building with Xcode 10.x.
                #if XCODE_1100
                if #available(iOS 13.0, *) {
                    // Track UIWindowScene events for the key window's scene.
                    // The example app disables multi-window support in the .plist (see UIApplicationSceneManifestKey).
                    builder.orientationTracker = UserInterfaceTracker(scene: UIApplication.shared.keyWindow!.windowScene!)
                }
                #endif
            }
            camera = CameraSource(options: options, delegate: self)
            localVideoTrack = LocalVideoTrack(source: camera!, enabled: true, name: "Camera")
            
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            var preferredFormat: VideoFormat?

            if let frontCamera = frontCamera {
                
                let formats = CameraSource.supportedFormats(captureDevice: frontCamera)

                // We match 640x480 directly, since it is known to be supported by all devices.
                for format in formats {
                    let theFormat = format as! VideoFormat
                    print("theFormat.dimensions.width")
                    print(theFormat.dimensions.width)
                    print("theFormat.dimensions.height")
                    print(theFormat.dimensions.height)
                    if theFormat.dimensions.width == 1920,
                        theFormat.dimensions.height == 1080 {
                        preferredFormat = theFormat
                    }
                }
                
                print("ending here")
            }
            
            if let preferredFormat = preferredFormat {
                camera!.startCapture(device: frontCamera != nil ? frontCamera! : backCamera!,format: preferredFormat) { (captureDevice, videoFormat, error) in
                    if let error = error {
                        //self.logMessage(messageText: "Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self.previewView.shouldMirror = (captureDevice.position == .front)
                    }
                }
            }else {
                camera!.startCapture(device: frontCamera != nil ? frontCamera! : backCamera!) { (captureDevice, videoFormat, error) in
                    if let error = error {
                        //self.logMessage(messageText: "Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self.previewView.shouldMirror = (captureDevice.position == .front)
                    }
                }
            }
        }
        
        if (localVideoTrack == nil) {
            //logMessage(messageText: "Failed to create video track")
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
          
        if ((self.remoteParticipant) != nil) {
             if ((self.remoteParticipant?.videoTracks.count)! > 0) {
                 let remoteVideoTrack = self.remoteParticipant?.remoteVideoTracks[0].remoteTrack
                 remoteVideoTrack?.removeRenderer(self.remoteView!)
                 self.remoteView?.removeFromSuperview()
                 self.remoteView = nil
             }
         }
         self.room?.delegate = nil
         self.remoteParticipant?.delegate = nil
         self.remoteParticipant = nil
        self.room?.disconnect()
        player?.stop()
        //NotificationHandler.shared.callStatus = false
        //logMessage(messageText: "Attempting to disconnect from room \(room?.name ?? "")")
        self.timer?.invalidate()
        
        if !(NotificationHandler.shared.callStatus ?? false)
        {
            self.dialerSendNotificationAPI()
        }
        else
        {
            self.recevierSendNotificationAPI()
        }
        performsEndCallAction()
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
    
//    func performEndCallAction() {
//
//        if let uuid = NotificationHandler.shared.currentCallUUID {
//               let endCallAction = CXEndCallAction(call: uuid)
//               let transaction = CXTransaction(action: endCallAction)
//
//               callController.request(transaction) { error in
//                   if let error = error {
//                       NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
//                   } else {
//                       NSLog("EndCallAction transaction request successful")
//                   }
//               }
//           }
//        for call in self.cxCallController.callObserver.calls {
//
//            let endCallAction = CXEndCallAction(call: call.uuid)
//            let transaction = CXTransaction(action: endCallAction)
//
//            cxCallController.request(transaction) { error in
//                if let error = error {
//                    NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
//                    return
//                }
//
//                NSLog("EndCallAction transaction request successful")
//
//            }
//
//        }
//    }
    
    func cleanupRemoteParticipant() {
        if ((self.remoteParticipant) != nil) {
            if ((self.remoteParticipant?.videoTracks.count)! > 0) {
                let remoteVideoTrack = self.remoteParticipant?.remoteVideoTracks[0].remoteTrack
                remoteVideoTrack?.removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        performsEndCallAction()
        self.room?.delegate = nil
        self.remoteParticipant?.delegate = nil
        self.remoteParticipant = nil
        self.navigationController?.popViewController(animated: true)
    }
}


// MARK: TVIRoomDelegate
extension VideoCallVC1 : RoomDelegate {
    func roomDidConnect(room: Room) {
        if NotificationHandler.shared.currentCallStatus == CurrentCallStatus.Incoming {
            statusLbl.text = "ringing to fone.me/\(NotificationHandler.shared.dialerFoneId ?? "")"
        }else {
            statusLbl.text = "ringing to fone.me/\(DialerFoneID)"
        }
        playSound()
        // At the moment, this example only supports rendering one Participant at a time.
        //print(room.name,room.remoteParticipants.count,room.sid,room.state.rawValue)
        //logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants[0]
            self.remoteParticipant?.delegate = self
        }
    }
    
    func roomDidDisconnect(room: Room, error: Error?) {
        //logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")
        
        player?.stop()
        self.cleanupRemoteParticipant()
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func roomDidFailToConnect(room: Room, error: Error) {
        player?.stop()
        //logMessage(messageText: "Failed to connect to room with error")
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func participantDidConnect(room: Room, participant: RemoteParticipant) {
        if (self.remoteParticipant == nil) {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
        }
        //logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        if (self.remoteParticipant == participant) {
            cleanupRemoteParticipant()
        }
        //logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIRemoteParticipantDelegate
extension VideoCallVC1 : RemoteParticipantDelegate {
    
    func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has offered to share the video Track.
        
//        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) video track")
    }

    func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has stopped sharing the video Track.

//        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }

    func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has offered to share the audio Track.

//        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) audio track")
    }

    func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has stopped sharing the audio Track.

//        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }

    func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's video frames now.
        
//        logMessage(messageText: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")
        
        if (self.remoteParticipant == participant) {
                _ = renderRemoteParticipant(participant: participant)
        }
    }
    
    func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
                
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        //statusLbl.isHidden = true
        player?.stop()
        
//        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")
        if (self.remoteParticipant == participant) {
            if let remoteView = remoteView {
                videoTrack.removeRenderer(remoteView)
                remoteView.removeFromSuperview()
                self.remoteView = nil
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
            
//            let callLog = HKCallLogHandler.shared
//            callLog.name = self.name
//            callLog.number = self.otherUserIncomingNumber
//            callLog.callType = "incoming"
            
            self.addCallLogAPI()
        }
        
        //callerView.isHidden = true
        //Timer for call
        if NotificationHandler.shared.currentCallStatus == CurrentCallStatus.Incoming {
            statusLbl.text = "fone.me/\(NotificationHandler.shared.dialerFoneId ?? "")"
        }else {
            
        }
        self.timerLbl.isHidden = false
        self.runTimer()
        //statusLbl.isHidden = true
        player?.stop()
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        
        try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        
        try? session.setActive(true)
//        logMessage(messageText: "Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
//        logMessage(messageText: "Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
}

// MARK: TVIVideoViewDelegate
extension VideoCallVC1 : VideoViewDelegate {
    func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

extension VideoCallVC1
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
//                    let alert = UIAlertController(title: "Dismissed from receiver send notification", message: "asdfsf", preferredStyle: .alert)
//                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
//
//                    })
                    return
                }
            }
        }
        self.dismiss(animated: true, completion: {
        })

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
//            let alert = UIAlertController(title: "Dismissed from dialer send notification", message: "asdfsf", preferredStyle: .alert)
//            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: {
//                
//            })
            return
        }
        self.dismiss(animated: true, completion: {
        })
    }
}
// MARK:- CameraSourceDelegate
extension VideoCallVC1: CameraSourceDelegate {
    func cameraSourceDidFail(source: CameraSource, error: Error) {
//        logMessage(messageText: "Camera source failed with error: \(error.localizedDescription)")
    }
}
