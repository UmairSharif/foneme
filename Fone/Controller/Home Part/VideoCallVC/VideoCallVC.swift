//
//  ViewController.swift
//  VideoQuickStart
//
//  Copyright © 2016-2019 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVideo
import SwiftyJSON
import CallKit
import AVFoundation
import UserNotifications
import PushKit
import Alamofire

class VideoCallVC: UIViewController {
    
    // MARK:- View Controller Members
    
    var accessToken = ""
    var maxAudioBitrate = UInt()
    var maxVideoBitrate = UInt()
    
    @IBOutlet weak var stackCall: UIStackView!
    // Configure remote URL to fetch token from
    
    // Video SDK components
    var room: Room?
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */
    var audioDevice: DefaultAudioDevice = DefaultAudioDevice()
    var camera: CameraSource?
    var localVideoTrack: LocalVideoTrack?
    var localAudioTrack: LocalAudioTrack?
    var remoteParticipant: RemoteParticipant?
    
    // CallKit components
    var callKitProvider: CXProvider!
    var callKitCallController: CXCallController!
    var callKitCompletionHandler: ((Bool)->Swift.Void?)? = nil
    var userInitiatedDisconnect: Bool = false
    var isIncommingCall = false
    var roomUUID = ""
    var roomFCMToken = ""
    var roomVOIPToken = ""
    var isDeclinedCall = false
    var isCallStarted = false
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
    var userDetails : UserDetailModel?
    var isVideo: Bool = false
    
    // MARK:- UI Element Outlets and handles
    @IBOutlet weak var foneLogo: UIImageView!

    @IBOutlet weak var previewView: VideoView!
    @IBOutlet weak var btnHoldCall: UIButton!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var timerLbl : UILabel!
    @IBOutlet weak var callerImage: UIImageView!
    @IBOutlet weak var UserNameLbl: UILabel!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var previewCallingView: VideoView!
    @IBOutlet weak var remoteCallingView: VideoView!
    @IBOutlet weak var btnAddFriend: UIButton!
    let panGesture = UIPanGestureRecognizer()
    // MARK:- UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        previewCallingView.frame = CGRect(x: 16, y: 100, width: previewCallingView.bounds.width, height: previewCallingView.bounds.height)
        panGesture.addTarget(self, action: #selector(self.panView))
        self.previewCallingView.isUserInteractionEnabled = true
        self.previewCallingView.addGestureRecognizer(panGesture)
        
        callerImage.layer.cornerRadius = callerImage.frame.size.height / 2
        callerImage.clipsToBounds = true
        UserNameLbl.text = self.name
        previewView.contentMode = .scaleAspectFill
        previewCallingView.contentMode = .scaleAspectFill
        self.remoteCallingView.contentMode = .scaleAspectFill

        previewView.backgroundColor = .black
        previewCallingView.backgroundColor = .black
        self.roomVOIPToken = userDetails?.contactVT ?? ""
        if isVideo == true {
            previewCallingView.isHidden = false
            previewView.isHidden = false
            self.btnHoldCall.isHidden = false
           
        }else {
            previewCallingView.isHidden = true
            previewView.isHidden = true
            self.btnHoldCall.isHidden = true
        }
        
        
        let configuration = CXProviderConfiguration(localizedName: "Fone")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        configuration.supportedHandleTypes = [.generic]
        configuration.iconTemplateImageData = UIImage(named: "iconMask80")!.pngData()

//        if let callKitIcon = UIImage(named: "iconMask80") {
//            configuration.iconTemplateImageData = callKitIcon.pngData()
//        }
        configuration.ringtoneSound = "iphone-original.caf"
        
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
        callKitProvider.setDelegate(self, queue: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startPreview()
        }
        
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
            self.showLogAlert(message: "Please connect your device to the internet.") { (alert) in
                self.dismiss(animated: true, completion: nil)
                return
            }
            
        }
        
    }
    
    
    
    @IBAction func panView(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)
        
        if let viewToDrag = sender.view {
            viewToDrag.center = CGPoint(x: viewToDrag.center.x + translation.x,
                                        y: viewToDrag.center.y + translation.y)
            sender.setTranslation(CGPoint(x: 0, y: 0), in: viewToDrag)
        }
    }
    
    func setupCall(){
        if NotificationHandler.shared.callType != nil {
            if NotificationHandler.shared.callType == "VD" {
                self.isVideo = true
            }else{
                self.isVideo = false
            }
            if self.isVideo {
                self.previewView.contentMode = .scaleAspectFill
                self.previewCallingView.contentMode = .scaleAspectFill
                self.remoteCallingView.contentMode = .scaleAspectFill
                self.previewCallingView.isHidden = true
                self.previewView.isHidden = false
                self.remoteCallingView.isHidden = false
                self.foneLogo.isHidden = false
            }else{
                self.previewCallingView.isHidden = true
                self.previewView.isHidden = true
                self.remoteCallingView.isHidden = true
                self.foneLogo.isHidden = true

            }
        }else{
            if self.isVideo {
                self.previewView.contentMode = .scaleAspectFill
                self.previewCallingView.contentMode = .scaleAspectFill
                self.remoteCallingView.contentMode = .scaleAspectFill
                self.previewCallingView.isHidden = true
                self.previewView.isHidden = false
                self.remoteCallingView.isHidden = false
                self.foneLogo.isHidden = false

            }else{
                self.previewCallingView.isHidden = true
                self.previewView.isHidden = true
                self.remoteCallingView.isHidden = true
                self.foneLogo.isHidden = true

            }
        }
        self.remoteCallingView.backgroundColor = .black
        if NotificationHandler.shared.isReceived == false {
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
            
            
            self.performStartCallAction(uuid: UUID(), roomName: self.roomName)
        }else{
            self.roomName = NotificationHandler.shared.dialerNumber ?? ""
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if NotificationHandler.shared.currentCallStatus == CurrentCallStatus.Incoming {
            statusLbl.text = "ringing to fone.me/\(NotificationHandler.shared.dialerFoneId ?? "")"
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
        
        DispatchQueue.main.async {
            self.callerImage.layer.cornerRadius = self.callerImage.bounds.size.width/2.0
            self.callerImage.layer.masksToBounds = true
        }
        
        
        self.timerLbl.isHidden = true
        self.seconds = 86400
        self.setupCall()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
        self.player?.stop()
    }
    
    func getTokenAPI(completion : @escaping (_ success : Bool) -> Void)
    {
        var userId : String?
        
        
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
                self.accessToken = token
                if !(NotificationHandler.shared.callStatus ?? false)
                {
                    //Send call Notification
                    self.sendCallNotificationAPI()
                    
                }
                completion(true)
                //                self.configureSetup(token : token)
            }
            else{
                completion(false)
                print(response?.error?.localizedDescription)
            }
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
                      "CallStatusType": "APPTOAPP",

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
    
    
    func playSound(withFileName:String = "telephone") {
        DispatchQueue.main.async {
            guard let url = Bundle.main.url(forResource:withFileName , withExtension: "mp3") else { return }
            
            do {
               // try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                print("playSound URL \(url)");
                try AVAudioSession.sharedInstance().setActive(true)
                
                
                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                
                /* iOS 10 and earlier require the following line:
                 player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
                
                guard let player = self.player else { return }
                //player.prepareToPlay()
                player.numberOfLoops = -1
                player.play()
                
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func speakerBtnTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            let session = AVAudioSession.sharedInstance()
            var _: Error?
            try? session.setCategory(AVAudioSession.Category.playAndRecord)
            try? session.setMode(AVAudioSession.Mode.voiceChat)
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try? session.setActive(true)
        }else{
            let session = AVAudioSession.sharedInstance()
            var _: Error?
            try? session.setCategory(AVAudioSession.Category.playAndRecord)
            try? session.setMode(AVAudioSession.Mode.voiceChat)
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try? session.setActive(true)
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return self.room != nil
    }
    
    @IBAction func btnBackAction(_ sender : UIButton){
        self.dismiss(animated: true) {
            self.disconnect(sender: sender)
        }
    }
    
    @IBAction func btnHoldAction(_ sender : UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            localVideoTrack?.isEnabled = false
        }else{
            localVideoTrack?.isEnabled = true
        }
    }
    
    
    func setupRemoteVideoView() {
        // Creating `VideoView` programmatically
        //  self.remoteView = VideoView(frame: CGRect(x: 0, y: 0, width: self.remoteCallingView.frame.width, height: self.remoteCallingView.frame.height), delegate: self)
        //    self.remoteView?.contentMode = .scaleToFill
        //    self.remoteCallingView.insertSubview(self.remoteView!, at: 0)
        self.remoteCallingView.isUserInteractionEnabled = true
        self.previewCallingView.isHidden = false
        self.previewView.isHidden = true
        self.remoteCallingView.isHidden = false
        self.foneLogo.isHidden = false

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.flipCamera))
        self.remoteCallingView?.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    // MARK:- IBActions
    @IBAction func btnFlipCamera(sender: AnyObject) {
        self.flipCamera()
    }
    
    @IBAction func disconnect(sender: UIButton) {
        if self.isIncommingCall {
            self.recevierSendNotificationAPI("CE")
        }else{
            self.dialerSendNotificationAPI()
        }
        self.stackCall.alpha = 0.5

        if let room = room, let uuid = room.uuid {
            userInitiatedDisconnect = true
            let endCallAction = CXEndCallAction(call: uuid)
            let transaction = CXTransaction(action: endCallAction)
            room.disconnect()
            self.camera?.stopCapture()
            self.camera = nil
            self.localAudioTrack = nil
            self.localVideoTrack = nil
            self.remoteParticipant = nil
            self.room = nil
            player?.stop()
            //NotificationHandler.shared.callStatus = false
            //logMessage(messageText: "Attempting to disconnect from room \(room?.name ?? "")")
            self.timer?.invalidate()
            self.timer = nil
            callKitCallController.request(transaction) { error in
                if let error = error {
                    print("EndCallAction transaction request failed: \(error.localizedDescription).")
                    self.callKitProvider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
                    
                }
                
                print("EndCallAction transaction request successful")
                self.callKitProvider.invalidate()
                DispatchQueue.main.async {
                    self.dismiss(animated: true
                        , completion: nil)
                }
            }
            
        }else{
            DispatchQueue.main.async {
                self.stackCall.alpha = 0.5
                sleep(2)
                
                self.dismiss(animated: true
                    , completion: nil)
            }
        }
    }
    
    
    
    @IBAction func toggleMic(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if let localAudioTrack = self.localAudioTrack {
              localAudioTrack.isEnabled = !sender.isSelected
        }

    }
    
    func muteAudio(isMuted: Bool) {
        if let localAudioTrack = self.localAudioTrack {
            localAudioTrack.isEnabled = !isMuted
            
            // Update the button title
            if (!isMuted) {
                self.micButton.setTitle("Mute", for: .normal)
            } else {
                self.micButton.setTitle("Unmute", for: .normal)
            }
        }
    }
    
    @IBAction func AddFriendaction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    // MARK:- Private
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }
        
        let frontCamera = CameraSource.captureDevice(position: .front)
        let backCamera = CameraSource.captureDevice(position: .back)
        self.loadViewIfNeeded()
        
        if (frontCamera != nil || backCamera != nil) {
            // Preview our local camera track in the local video preview view.
            camera = CameraSource(delegate: self)
            localVideoTrack = LocalVideoTrack(source: camera!, enabled: true, name: "Camera")
            
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            localVideoTrack!.addRenderer(self.previewCallingView)
            logMessage(messageText: "Video track created")
            speakerButton.isSelected = true
            if (frontCamera != nil && backCamera != nil) {
                // We will flip camera on tap.
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.flipCamera))
                tapGestureRecognizer.numberOfTapsRequired = 1
                self.previewView.isUserInteractionEnabled = true
                self.previewView.addGestureRecognizer(tapGestureRecognizer)
            }
            
            camera!.startCapture(device: frontCamera != nil ? frontCamera! : backCamera!) { (captureDevice, videoFormat, error) in
                if let error = error {
                    self.logMessage(messageText: "Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                } else {
                    self.previewView.shouldMirror = (captureDevice.position == .front)
                    self.previewCallingView.shouldMirror = (captureDevice.position == .front)
                }
            }
        }
        else {
            self.logMessage(messageText:"No front or back capture device found!")
        }
    }
    
    @objc func flipCamera() {
        var newDevice: AVCaptureDevice?
        
        if let camera = self.camera, let captureDevice = camera.device {
            if captureDevice.position == .front {
                newDevice = CameraSource.captureDevice(position: .back)
            } else {
                newDevice = CameraSource.captureDevice(position: .front)
            }
            
            if let newDevice = newDevice {
                camera.selectCaptureDevice(newDevice) { (captureDevice, videoFormat, error) in
                    if let error = error {
                        self.logMessage(messageText: "Error selecting capture device.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self.previewView.shouldMirror = (captureDevice.position == .front)
                        self.previewCallingView.shouldMirror = (captureDevice.position == .front)
                    }
                }
            }
        }
    }
    
    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.
        
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = LocalAudioTrack()
            
            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
        
        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            if self.isVideo {
                self.startPreview()
            }
        }
    }
    
    
    func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        // This example renders the first subscribed RemoteVideoTrack from the RemoteParticipant.
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteVideoView()
                subscribedVideoTrack.addRenderer(self.remoteCallingView!)
                self.remoteParticipant = participant
                self.view.layoutSubviews()
                return true
            }
        }
        return false
    }
    
    func renderRemoteParticipants(participants : Array<RemoteParticipant>) {
        for participant in participants {
            // Find the first renderable track.
            if participant.remoteVideoTracks.count > 0,
                renderRemoteParticipant(participant: participant) {
                break
            }
        }
    }
    
    func logMessage(messageText: String) {
        print(messageText)
    }
    
    func holdCall(onHold: Bool) {
        localAudioTrack?.isEnabled = !onHold
        if self.isVideo {
            localVideoTrack?.isEnabled = !onHold
        }
    }
    
}
