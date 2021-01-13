//
//  CreateGroupChannelViewControllerB.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/15/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import AlamofireImage
import MobileCoreServices
import Photos
import Branch

class CreateGroupChannelViewControllerB: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {
    var members: [SBDUser] = []
    
    @IBOutlet weak var profileImageView: ProfileImageView!
    
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    var coverImageData: Data?
    var createButtonItem: UIBarButtonItem?
    var isLinkViewOpen = false
    var createdChannel:SBDGroupChannel?
    var publicGroupLink = ""
    
    @IBOutlet weak var publicImage: UIImageView?
    @IBOutlet weak var privateImage: UIImageView?
    @IBOutlet weak var inviteURLField: UITextField?
    @IBOutlet weak var privateGroupLbl: UILabel?
    @IBOutlet weak var decriptionTextView: UITextView?
    @IBOutlet weak var publickLinkStatusLbl: UILabel?

    @IBOutlet weak var topView: UIView?
    @IBOutlet weak var topViewCover: UIButton?
    
    @IBOutlet weak var bottomView: UIView?
    @IBOutlet weak var privateGroupView: UIView?
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    var isPublicGroup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        publickLinkStatusLbl?.isHidden = true;
        self.title = "Create Private Chats"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.createButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(CreateGroupChannelViewControllerB.clickCreateGroupChannel(_ :)))
        self.createButtonItem?.tintColor = UIColor.white
        
        self.navigationItem.rightBarButtonItem = self.createButtonItem
        
        self.coverImageData = nil
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        self.loadingIndicatorView.isHidden = true
        
        var memberNicknames: [String] = []
        var memberCount: Int = 0
        for user in self.members {
            memberNicknames.append(user.nickname!)
            memberCount += 1
            if memberCount == 4 {
                break
            }
        }
        
        let channelNamePlaceholder = memberNicknames.joined(separator: ", ")
        self.channelNameTextField.attributedPlaceholder = NSAttributedString(string: channelNamePlaceholder, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
        ])
        self.profileImageView.isUserInteractionEnabled = true
        let tapCoverImageGesture = UITapGestureRecognizer(target: self, action: #selector(CreateGroupChannelViewControllerB.clickCoverImage(_ :)))
        self.profileImageView.addGestureRecognizer(tapCoverImageGesture)
        
        self.profileImageView.users = members
        self.profileImageView.makeCircularWithSpacing(spacing: 1)
        topViewCover?.isHidden = true;
        bottomViewHeight.constant = 130
    }
    
    @IBAction func publicChannelBtnClicked() {
        if inviteURLField?.text?.isEmpty ?? true {
            Utils.showAlertController(title: "", message: "Please enter public link name.", viewController: self)
            return;
        }
        if let channel = self.createdChannel{
            self.openCreateLinkView(channel);
        }
    }
    
    @IBAction func channelTypeBtnClicked(_ sender: AnyObject) {
        
        let tagValue = sender.tag
        
        self.privateImage?.image = UIImage(named: "img_list_unchecked")
        self.publicImage?.image = UIImage(named: "img_list_unchecked")
        
        
        if tagValue == 1 {
            self.publicImage?.image = UIImage(named: "img_list_checked")
            isPublicGroup = true;
            self.privateGroupView?.isHidden = true
        }
        else {
            self.privateGroupView?.isHidden = false
            
            self.privateImage?.image = UIImage(named: "img_list_checked")
            isPublicGroup = false;
            
        }
        if let channel = self.createdChannel{
            self.openCreateLinkView(channel);
        }
        
        
    }
    
    @objc func clickCoverImage(_ sender: AnyObject) {
        
        let actionPhoto = UIAlertAction(title: "Take Photo...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.camera
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionLibrary = UIAlertAction(title: "Choose from Library...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.photoLibrary
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        
        Utils.showAlertControllerWithActions([actionPhoto, actionLibrary, actionCancel],
                                             title: nil,
                                             frame: CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0),
                                             viewController: self)
        
    }
    
    
    func saveGroupInfo(){
        //            self.activityIndicator.startAnimating()
        //            self.activityIndicator.isHidden = false
        
        var userId = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId!
            }
        }
        let channelName = self.channelNameTextField.text != "" ? self.channelNameTextField.text : self.channelNameTextField.placeholder

        
        var groupLink = "";
        var publicGroupLink = "";
        if self.isPublicGroup {
            publicGroupLink = self.inviteURLField?.text ?? ""
        } else {
            groupLink = self.privateGroupLbl?.text ?? ""
        }
        
        let groupID = self.createdChannel?.channelUrl
        
        let params = ["GroupID":groupID!,
                      "UserID": userId,
                      "GroupName":channelName!,
                      "GroupDescription":decriptionTextView!.text!,
                      "GroupLink":groupLink,
                      "IsPublic":isPublicGroup ? "1" : "0",
                      "IsGroup":"1",
                    "PublicGroupLink":publicGroupLink] as [String:Any]
        // "CNIC": textFieldFoneId.text!,
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(createGroupChannel, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                //                    self.activityIndicator.stopAnimating()
                //                    self.activityIndicator.isHidden = true
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {}
                else
                {
                    if let message = json["Message"].string
                    {
                        print(message)
                        self.errorAlert("\(message)")
                    }
                    
                    //                        self.activityIndicator.stopAnimating()
                    //                        self.activityIndicator.isHidden = true
                }
            }
        }
    }
    
    
    @objc func clickCreateGroupChannel(_ sender: AnyObject) {
        
        
        if  self.isLinkViewOpen {
            if self.isPublicGroup && self.publicGroupLink.isEmpty {
                self.publicChannelBtnClicked();
                 return;
            }
            
            self.saveGroupInfo();
            self.navigationController?.dismiss(animated: true, completion: nil)
            
        } else {
            
            
            
            self.showLoadingIndicatorView()
            
            let channelName = self.channelNameTextField.text != "" ? self.channelNameTextField.text : self.channelNameTextField.placeholder
            
            let params = SBDGroupChannelParams()
            params.coverImage = self.coverImageData
            params.add(self.members)
            params.name = channelName
            params.data = decriptionTextView?.text ?? ""
            params.isPublic = true

            SBDGroupChannel.createChannel(with: params) { (channel, error) in
                self.hideLoadingIndicatorView()
                
                if let error = error {
                    let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                    let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                    alertController.addAction(actionCancel)
                    DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                    return
                }
                self.isLinkViewOpen = true;
                self.createdChannel = channel!
                self.openCreateLinkView(channel!)
                
                if let navigationController = self.navigationController as? CreateGroupChannelNavigationController{
                    if (navigationController.channelCreationDelegate?.responds(to: #selector(CreateGroupChannelNavigationController.didChangeValue(forKey:))))! {
                        navigationController.channelCreationDelegate?.didCreateGroupChannel(channel!)
                    }
                }
            }
            
        }
    }
    
    func openCreateLinkView(_ channel: SBDGroupChannel){
        self.view.endEditing(true)
        topViewCover?.isHidden = false;
        bottomView?.isHidden = false;
        bottomViewHeight.constant = 10
        
        let buo = BranchUniversalObject.init(canonicalIdentifier: "content/\(channel.channelUrl)")
        buo.title = channel.name
        buo.contentDescription = channel.description
        buo.imageUrl = channel.coverUrl
        
        let linkProperties: BranchLinkProperties = BranchLinkProperties()
        linkProperties.channel = channel.channelUrl
        linkProperties.feature = "sharing"
        
        if isPublicGroup {
            if inviteURLField?.text?.isEmpty ?? true {
                return;
            }
            buo.publiclyIndex = true
            buo.locallyIndex = true
            linkProperties.alias = inviteURLField?.text;
        } else {
            buo.publiclyIndex = false
            buo.locallyIndex = false
            if !(privateGroupLbl?.text?.isEmpty ?? true) {
                return;
            }
        }
        
        
        
        buo.getShortUrl(with: linkProperties) { (url, error) in
            if (error == nil) {
                print("Got my Branch link to share: \(url)")
                DispatchQueue.main.async {

                if self.isPublicGroup {
                    // self.channelNameTextField.text
                    self.publicGroupLink = url ?? "";
                    self.publickLinkStatusLbl?.isHidden = false;

                } else {
                        self.privateGroupLbl?.text = url;
                    }
                }
                
            } else {
                Utils.showAlertController(title: "Error", message: "\(String(describing: error?.localizedDescription))", viewController: self)
                print(String(format: "Branch error : %@", error! as CVarArg))
            }
            
        }
        
    }
    
    func cropImage(_ imageData: Data) {
        if let image = UIImage(data: imageData) {
            let imageCropVC = RSKImageCropViewController(image: image)
            imageCropVC.delegate = self
            imageCropVC.cropMode = .square
            self.present(imageCropVC, animated: false, completion: nil)
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.navigationController?.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        weak var weakSelf: CreateGroupChannelViewControllerB? = self
        picker.dismiss(animated: true) {
            let strongSelf = weakSelf
            if CFStringCompare(mediaType, kUTTypeImage, []) == .compareEqualTo {
                if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    if let imageData = originalImage.jpegData(compressionQuality: 1.0) {
                        strongSelf?.cropImage(imageData)
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - RSKImageCropViewControllerDelegate
    // Crop image has been canceled.
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image has been cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        self.coverImageData = croppedImage.jpegData(compressionQuality: 0.5)
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
    
    // MARK: - Utilities
    private func showLoadingIndicatorView() {
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
        }
    }
    
    private func hideLoadingIndicatorView() {
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = true
            self.loadingIndicatorView.stopAnimating()
        }
    }
}
