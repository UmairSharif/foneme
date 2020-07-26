//
//  EditProfileVC.swift
//  Fone
//
//  Created by Bester on 07/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import Photos
import CountryPickerView
import NVActivityIndicatorView
import SendBirdSDK

class EditProfileVC: UIViewController,CountryDataDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    //IBOutlet and Variables
    @IBOutlet weak var nameTxt : UITextField!
    @IBOutlet weak var emailTxt : UITextField!
    @IBOutlet weak var addressTxt : UITextField!
    @IBOutlet weak var numberTxt : UITextField!
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var flagBtn : UIButton!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    var imagePicker = UIImagePickerController()
    var userId : String?
    var imageName : String?
    let cpv = CountryPickerView()
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        DispatchQueue.main.async {
                  
                  if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                      print(userProfileData)
                      if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                          self.userId = user.userId
                          self.nameTxt.text = user.name
                          self.emailTxt.text = user.email
                          self.addressTxt.text = user.address
                          self.numberTxt.text = user.numberWithOutCode
                          self.codeLbl.text = user.coutryCode
                          
                          for country in self.cpv.countries
                          {
                              if country.phoneCode == user.coutryCode
                              {
                                  self.flagBtn.setImage(country.flag, for: .normal)
                              }
                          }
                        if let _ = user.userImage{
                              let url = URL(string: user.userImage ?? "")!
                              self.downloadImage(from: url)
                        }
                      }
                  }
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


    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            
            DispatchQueue.main.async() {
                self.userImage.image = UIImage(data: data)
            }
        }
    }

    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func codeBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadCountryCodeVC()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    
    func selectedCountry(countryName: String, countryCode: String, flag: UIImage) {
        codeLbl.text = countryCode
        flagBtn.setImage(flag, for: .normal)
    }

    @IBAction func photoBtnTapped(_ sender : UIButton)
    {
        let alert:UIAlertController=UIAlertController(title: "Choose File", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openCamera(UIImagePickerController.SourceType.camera)
        }
        let gallaryAction = UIAlertAction(title: "Gallery", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openCamera(UIImagePickerController.SourceType.photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
        }
        
        // Add the actions
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        alert.addAction(cameraAction)
        alert.addAction(gallaryAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func saveBtnTapped(_ sender : UIButton)
    {
        if isVerifiedFields()
        {
            //Update Profile API
            self.updateProfileAPI()
        }
        
    }
    
    func openCamera(_ sourceType: UIImagePickerController.SourceType) {
        imagePicker.sourceType = sourceType
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if #available(iOS 11.0, *) {
            if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                let assetResources = PHAssetResource.assetResources(for: asset)
                imageName = assetResources.first!.originalFilename
            }
        } else {
            // Fallback on earlier versions
        }
        
        userImage.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func isVerifiedFields() -> Bool
    {
        if (nameTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your name!")
            return false
        }
        else if (emailTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your email!")
            return false
        }
        else if !Utility.sharedInstance.isValidEmail(emailTxt.text!) {
            self.errorAlert("Please enter a valid email!")
            return false
        }
        else if (numberTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your phone number!")
            return false
        }
        return true
    }
    
    func updateProfileAPI()
    {
        
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        let image : UIImage? = userImage.image
        //let imageData = image!.jpegData(compressionQuality: 1)
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let phoneNumber = codeLbl.text! + numberTxt.text!
        
        let parameters = [
            "Name" : nameTxt.text!,
            "UserId" : userId ?? "",
            "PhoneNumber" : phoneNumber,
            "Email" : emailTxt.text!,
            "Address" : addressTxt.text ?? "",
            "FatherName": "iOS",
            ] as [String : Any]

        var headers = [String:String]()
        let boundary = "---------------------------14737809831466499882746641449"
//        headers = ["Content-type": "multipart/form-data; boundary=\(boundary)",
//                   "Authorization": "bearer " + loginToken!]
        headers = ["Content-type": "application/json",
                   "Authorization": "bearer " + loginToken!]

        var imageParams : [String : OMFile]?
        if image != nil {
            let imageFile = OMFile(image: image!, of: CGSize(width: 210, height: 210))
            
            imageParams = ["UserImage" : imageFile]
        }else {
            imageParams = [:]
        }

        ServerCall.makeCallWithFile(updateProfileUrl, params: parameters as [String : Any], files: imageParams, type: Method.POST, currentView: self.view, header: headers) { (response) in
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true

            if let json  = response {

                print(json)
                
                if json["StatusCode"].string == "200" {
                  let userInfo = json["UserProfileData"].dictionary
                   
                   let user = User()
                   
                   if let userId = userInfo?["UserId"]?.string
                   {
                       user.userId = userId
                   }
                   
                   if let name = userInfo?["Name"]?.string {
                       user.name = name
                   }
                   
                   if let email = userInfo?["Email"]?.string {
                       user.email = email
                   }
                   
                   if let address = userInfo?["Address"]?.string {
                       user.address = address
                   }
                   
                   if let mobileNumber = userInfo?["PhoneNumber"]?.string {
                       user.mobile = mobileNumber
                   }

                   if let userImage = userInfo?["ImageUrl"]?.string {
                       user.userImage = userImage
                        SBDMain.updateCurrentUserInfo(withNickname: user.name, profileUrl: user.userImage) { (error) in
                            print(error ?? "not an error")
                    }
                   }
                   
                   if let withOutCodeNumber = userInfo?["MobileNumberWithoutCode"]?.string {
                       user.numberWithOutCode = withOutCodeNumber
                   }
                   
                   if let countryCode = userInfo?["CountryCode"]?.string {
                       user.coutryCode = countryCode
                   }
                   
                   if let userProfileData = try? PropertyListEncoder().encode(user) {
                       UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                       UserDefaults.standard.synchronize()
                   }
                   
                   let alertController = UIAlertController(title: "Success", message: "You have successfully updated your profile.", preferredStyle: .alert)
                   
                   let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                       
                       self.navigationController?.popViewController(animated: true)
                   }
                   
                   alertController.addAction(action1)
                   self.present(alertController, animated: true, completion: nil)
                    
                }else {
                    let alertController = UIAlertController(title: "Error", message: "Please enter unique fone id", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    }
                    
                    alertController.addAction(action1)
                    self.present(alertController, animated: true, completion: nil)

                }
                
            }
        }
    }
}
