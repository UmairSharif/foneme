//
//  HKImagePickerHandler.swift
//  Collab
//
//  Created by MindsLab on 13/11/2018.
//  Copyright © 2018 mindslab. All rights reserved.
//

import UIKit
import Photos

 @objc protocol HKImagePickerHandlerDelegate {
    @objc optional func videoPickedWithInfo(_ info : [UIImagePickerController.InfoKey : Any], _ videoURL: String?)
    @objc optional func imagePickedWithInfo(_ info : [UIImagePickerController.InfoKey : Any], _ image: UIImage?)
}

class HKImagePickerHandler: NSObject {

    static let shared = HKImagePickerHandler()
    var delegate : HKImagePickerHandlerDelegate?
    
    //  MARK:- Image or Video Picker
    
    //  GALLERY and CAMERA Access Permissions
    func checkPermissionForMediaPickerController() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                print("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {
                    /* do stuff here */ print("success") }
            }
        case .restricted:
            print("User do not have access to photo album.")
        case .denied:
            print("User has denied the permission.")
        default: break

        }
    }
    
    
    //  Only IMAGES PICKER
    func showImagePicker() {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.image"]
        //imagePickerController.mediaTypes = ["public.image", "public.movie"]
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                topViewController()?.present(imagePickerController, animated: true, completion: nil)
            } else {
                topViewController()?.showAlert("Missing camera", "You can't take photo, there is no camera.")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            topViewController()?.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        topViewController()?.present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    func showMultiMediaPicker() {
        
        let mediaPicker = UIImagePickerController()
        
        let mediaSopurceAlert = UIAlertController.init(title: "Media Source", message: "Select Media Source", preferredStyle: .actionSheet)
        let cameraBtn = UIAlertAction.init(title: "Camera", style: .default, handler: { (camera) in
            mediaPicker.sourceType = .camera
            topViewController()?.present(mediaPicker, animated: true, completion: nil)
            self.checkPermissionForMediaPickerController()
        })
        
        let galleryBtn = UIAlertAction.init(title: "Gallery", style: UIAlertAction.Style.default, handler: { (gallery) in
            mediaPicker.sourceType = .photoLibrary
            topViewController()?.present(mediaPicker, animated: true, completion: nil)
            self.checkPermissionForMediaPickerController()
        })
        mediaSopurceAlert.addAction(cameraBtn)
        mediaSopurceAlert.addAction(galleryBtn)
        mediaSopurceAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Create and configure the alert controller.
        let alert = UIAlertController(title: "Media Type", message: "Select Media Type", preferredStyle: .actionSheet)
        // Create the action buttons for the alert.
        let photosAction = UIAlertAction(title: "Photos", style: .default)
        { (action) in
            // Respond to user selection of the action.
            mediaPicker.delegate = self
            mediaPicker.mediaTypes = ["public.image"]
            topViewController()?.present(mediaSopurceAlert, animated: true, completion: nil)
        }
        
        let videoAction = UIAlertAction(title: "Videos", style: .default)
        { (action) in
            mediaPicker.delegate = self
            mediaPicker.mediaTypes = ["public.movie"]
            topViewController()?.present(mediaSopurceAlert, animated: true, completion: nil)
        }
        alert.addAction(photosAction)
        alert.addAction(videoAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        topViewController()?.present(alert, animated: true, completion: nil)
        
    }
    
}


extension HKImagePickerHandler : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print(info)
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! String
        switch mediaType
        {
        case "public.movie":
            print("Movie selected!")
            self.delegate?.videoPickedWithInfo!(info, info[UIImagePickerController.InfoKey.mediaURL] as? String)
            break
        case "public.image":
            print("Image selected!")
            self.delegate?.imagePickedWithInfo!(info, info[UIImagePickerController.InfoKey.originalImage] as? UIImage)
            break
        default:
            break
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
