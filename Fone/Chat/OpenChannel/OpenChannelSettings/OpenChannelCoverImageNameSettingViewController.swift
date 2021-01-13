//
//  OpenChannelCoverImageNameSettingViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/1/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import AlamofireImage
import Photos
import MobileCoreServices

class OpenChannelCoverImageNameSettingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {
    weak var delegate: OpenChannelCoverImageNameSettingDelegate?
    var channel: SBDOpenChannel?
    var groupInfoDic = [String:Any]();

    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var coverImageContainerView: UIView!
    @IBOutlet weak var singleCoverImageContainerView: UIView!
    @IBOutlet weak var singleCoverImageView: UIImageView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    var channelCoverImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        getGroupInfo();
        // Do any additional setup after loading the view.
        self.title = "Cover Image & Name"
        self.navigationItem.largeTitleDisplayMode = .never

        let barButtonItemDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(OpenChannelCoverImageNameSettingViewController.clickDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = barButtonItemDone
        
        self.channelCoverImage = nil
        self.hideLoadingIndicatorView()
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        
        guard let channel = self.channel else { return }
        self.channelNameTextField.text = channel.name
        self.channelNameTextField.attributedPlaceholder = NSAttributedString(string: "Public Chat Name", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
            ])
        self.coverImageContainerView.isUserInteractionEnabled = true
        let tapCoverImageGesture = UITapGestureRecognizer(target: self, action: #selector(OpenChannelCoverImageNameSettingViewController.clickCoverImage))
        self.coverImageContainerView.addGestureRecognizer(tapCoverImageGesture)
        self.singleCoverImageContainerView.isHidden = false
        if let url = URL(string: channel.coverUrl!) {
            self.singleCoverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "ic_profile"))
        }
        else {
            self.singleCoverImageView.image = UIImage(named: "ic_profile")
        }
    }

    
     func getGroupInfo(){
         
         var userId = ""
         if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
             print(userProfileData)
             if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                 userId = user.userId!
             }
         }

         let groupID = self.channel?.channelUrl
         
         let params = ["GroupID":groupID!,
                       "UserID": userId] as [String:Any]
         // "CNIC": textFieldFoneId.text!,
         
         print("params: \(params)")
         var headers = [String:String]()
         headers = ["Content-Type": "application/json"]
         
         ServerCall.makeCallWitoutFile(getSingleGroupDetails, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
             
             if let json = response {
                 print(json)
                 //                    self.activityIndicator.stopAnimating()
                 //                    self.activityIndicator.isHidden = true
                 
                 let statusCode = json["StatusCode"].string ?? ""
                 
                 if statusCode == "200" || statusCode == "201"{
                    if let groupInfo = json["GroupData"].array {
                     for items in groupInfo {
                     self.groupInfoDic  = items.dictionaryObject ?? [String:Any]()
                        }
                    }
                    
                    print(self.groupInfoDic)

                    
                 } else {
                     if let message = json["Message"].string
                     {
                         print(message)
                       //  self.errorAlert("\(message)")
                     }
                     
                     //                        self.activityIndicator.stopAnimating()
                     //                        self.activityIndicator.isHidden = true
                 }

             }
         }
     }
     
    
    @objc func clickDoneButton(_ sender: AnyObject) {
        self.updateChannelInfo()
    }
    
    func cropImage(_ imageData: Data) {
        let image = UIImage(data: imageData)
        let imageCropVC = RSKImageCropViewController(image: image!)
        imageCropVC.delegate = self
        imageCropVC.cropMode = .square
        self.present(imageCropVC, animated: false, completion: nil)
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        guard let navigationController = self.navigationController else { return }
        navigationController.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        picker.dismiss(animated: true) {
            if CFStringCompare(mediaType, kUTTypeImage, []) == .compareEqualTo {
                if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    if let imageData = originalImage.jpegData(compressionQuality: 1.0) {
                        self.cropImage(imageData)
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
        self.channelCoverImage = croppedImage
        
        self.singleCoverImageView.image = croppedImage
        self.singleCoverImageContainerView.isHidden = false
        
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
    
    @objc func clickCoverImage() {
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
                                             frame: CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0),
                                             viewController: self
        )
    }
    
    func updateChannelInfo() {
        let imageData = self.channelCoverImage?.jpegData(compressionQuality: 0.5)
        
        self.loadingIndicatorView.superViewSize = self.view.frame.size
        self.loadingIndicatorView.updateFrame()
        self.showLoadingIndicatorView()
        
        guard let channel = self.channel else { return }
        channel.update(withName: self.channelNameTextField.text, coverImage: imageData, coverImageName: "image.jpg", data: nil, operatorUserIds: nil, customType: nil, progressHandler: nil) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(OpenChannelCoverImageNameSettingDelegate.didUpdateOpenChannel)) {
                    delegate.didUpdateOpenChannel!()
                }
                
                guard let navigationController = self.navigationController else { return }
                navigationController.popViewController(animated: true)
            }
        }
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
