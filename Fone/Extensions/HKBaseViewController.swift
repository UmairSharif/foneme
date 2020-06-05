//
//  HKBaseViewController.swift
//  Raven
//
//  Created by MindsLab on 05/10/2018.
//  Copyright © 2018 mindslab. All rights reserved.
//

import UIKit
import Photos

let MediaPickedNotification = "MediaPickedNotification"


class HKBaseViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //  MARK:- Image or Video Picker
    
    //  GALLERY and CAMERA Access Permissions
    func checkPermissionForMediaPickerController() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus
        {
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
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                self.showAlert("Missing camera", "You can't take photo, there is no camera.")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    func showMultiMediaPicker() {
        
        let mediaPicker = UIImagePickerController()
        
        let mediaSopurceAlert = UIAlertController.init(title: "Media Source", message: "Select Media Source", preferredStyle: .actionSheet)
        let cameraBtn = UIAlertAction.init(title: "Camera", style: .default, handler: { (camera) in
            mediaPicker.sourceType = .camera
            self.present(mediaPicker, animated: true, completion: nil)
            self.checkPermissionForMediaPickerController()
        })
        
        let galleryBtn = UIAlertAction.init(title: "Gallery", style: UIAlertAction.Style.default, handler: { (gallery) in
            mediaPicker.sourceType = .photoLibrary
            self.present(mediaPicker, animated: true, completion: nil)
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
            self.present(mediaSopurceAlert, animated: true, completion: nil)
        }
        
        let videoAction = UIAlertAction(title: "Videos", style: .default)
        { (action) in
            mediaPicker.delegate = self
            mediaPicker.mediaTypes = ["public.movie"]
            self.present(mediaSopurceAlert, animated: true, completion: nil)
        }
        alert.addAction(photosAction)
        alert.addAction(videoAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
}



extension HKBaseViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print(info)
        var mediaDict = [String : Any]()
        let mediaType = info["UIImagePickerControllerMediaType"] as! String
        switch mediaType
        {
        case "public.movie":
            print("Movie selected!")
            mediaDict = ["type" : "public.movie", "mediaInfo" : info] as [String : Any]
            picker.dismiss(animated: true, completion: nil)
            break
        case "public.image":
            print("Image selected!")
            mediaDict = ["type" : "public.image", "mediaInfo" : info] as [String : Any]
            picker.dismiss(animated: true, completion: nil)
            break
        default:
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: MediaPickedNotification), object: mediaDict)
        
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
