//
//  AboutMeVC.swift
//  Fone
//
//  Created by Manish Chaudhary on 08/02/21.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit
import CoreLocation
import NVActivityIndicatorView
import SendBirdSDK
import SVProgressHUD

class AboutMeVC: UIViewController,UITextViewDelegate,UITextFieldDelegate {
    
    @IBOutlet weak var lblcount: UILabel!
    @IBOutlet weak var txtaboutme: UITextView!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    @IBOutlet weak var imgyconst: NSLayoutConstraint!
    @IBOutlet weak var txtProfession: UITextField!
    @IBOutlet weak var imageTake: UIImageView!
    
    private var pickerController = UIImagePickerController()
    private var locationtext = ""
    private var isupdtval = true
    var user: User?
    var user_id = ""
    var mobileNumber = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtaboutme.delegate = self
        lblcount.text =  "0/180"
        if appDelegateShareInst.isLocationPermissionGranted{
            appDelegateShareInst.getLocationAccess()
            
            let location = CLLocation(latitude: GLBLatitude, longitude: GLBLongitude)
            location.placemark { [self] placemark, error in
                guard let placemark = placemark else {
                    print("Error:", error ?? "nil")
                    return
                }
                self.locationtext = placemark.postalAddressFormatted ?? (placemark.name ?? "Unknwon")
                
                var locattext = ""
                if let city = placemark.city {
                    locattext = locattext + "" + city
                }
                if let state = placemark.state {
                    locattext = locattext + ", " + state
                }
                if let state = placemark.country{
                    locattext = locattext + ", " + state
                }
                self.locationtext = locattext
            }
        } else{
            locationstatus()
        }
        
        if let imageUrl = CurrentSession.shared.user?.userImage, let url = URL(string: imageUrl) {
          self.downloadImage(from: url)
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isupdtval = false
        if imgyconst.constant != 100 {
            imgyconst.constant = 100
            self.view.layoutIfNeeded()
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        isupdtval = true
    }
    
    func locationstatus()
    {
        if appDelegateShareInst.isUserDeniedLocation {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: nil, message: "Turn on Location Services to Allow Fone Messenger to Determine Your Location", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (action) in
                    DispatchQueue.main.async {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) , UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                        }
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            appDelegateShareInst.getLocationAccess()
        }
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Tell us about yourself" {
            textView.text = ""
        }
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text == "" {
            textView.text = "Tell us about yourself"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        lblcount.text = String(numberOfChars) + "/180"
        
        if newText == "Tell us about yourself" {
            lblcount.text = "0/180"
        }
        
        return numberOfChars < 180    // 10 Limit Value
    }
    
    //MARK:- API CALL FOR ABOUT US
    
    func updateUserProfile() {
        guard let currentUser = CurrentSession.shared.user, let currentUserID = currentUser.userId else {
            return
        }

        let parameters: [String : Any] = [
            "Name" : currentUser.name ?? "",
            "UserId" : currentUserID,
            "PhoneNumber" : (currentUser.coutryCode ?? "") + (currentUser.numberWithOutCode ?? ""),
            "Email" : currentUser.email ?? "",
            "Address" : currentUser.address ?? currentUser.url ?? "",
            "FatherName" : "iOS",
        ]
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        var headers = [String:String]()
        headers = ["Content-type": "application/json",
                   "Authorization": "bearer " + loginToken!]
        
        var imageParams : [String : OMFile] =  [:]
        if imageTake.image != nil {
            let imageFile = OMFile(image: imageTake.image!, of: CGSize(width: 210, height: 210))
            
            imageParams = ["UserImage" : imageFile]
        }
        
        print("parameters = \(parameters) \n updateSocialUrl = \(updateProfileUrl)")
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                CurrentSession.shared.user = user
            }
        }
        ServerCall.makeCallWithFile(updateProfileUrl, params: parameters as [String : Any], files: imageParams, type: .POST, currentView: nil, header: headers) { (response) in
            SVProgressHUD.dismiss()
            if let json  = response {
                
                print(json)
                
                let statusCode = json["StatusCode"].string ?? ""
                if statusCode == "200" || statusCode == "201" {
                    if let userInfo = json["UserProfileData"].dictionary {
                        let user = User()
                        if let userId = userInfo["UserId"]?.string {
                            user.userId = userId
                        }
                        if let name = userInfo["Name"]?.string {
                            user.name = name
                        }
                        
                        if let email = userInfo["Email"]?.string {
                            user.email = email
                        }
                        
                        if let address = userInfo["Address"]?.string {
                            user.address = address
                        }
                        
                        if let url = userInfo["Url"]?.string {
                            user.url = url
                        }
                        
                        if let mobileNumber = userInfo["PhoneNumber"]?.string {
                            user.mobile = mobileNumber
                        }
                        
                        if let userImage = userInfo["ImageUrl"]?.string {
                            user.userImage = userImage
                            SBDMain.updateCurrentUserInfo(withNickname: user.name, profileUrl: user.userImage) { (error) in
                                debugPrint(error ?? "not an error")
                            }
                        }
                        
                        if let withOutCodeNumber = userInfo["MobileNumberWithoutCode"]?.string {
                            user.numberWithOutCode = withOutCodeNumber
                        }
                        
                        if let countryCode = userInfo["CountryCode"]?.string {
                            user.coutryCode = countryCode
                        }
                        
                        if let aboutMe = userInfo["AboutMe"]?.dictionary {
                            if let profession = aboutMe["Profession"]?.string {
                                user.profession = profession
                            }
                            
                            if let about = aboutMe["AboutMe"]?.string {
                                user.aboutme = about
                            }
                        }
                        CurrentSession.shared.user = user
                        if let userProfileData = try? PropertyListEncoder().encode(user) {
                            UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                            UserDefaults.standard.synchronize()
                        }
                    }
                }
            }
            self.callTABBAR()
        }
    }
    
    func downloadImage(from url: URL) {

        func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
            URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
        }
        
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }

            guard let response  = response as? HTTPURLResponse, response.statusCode != 403 else {
                return
            }
            DispatchQueue.main.async() {
                self.imageTake.image = UIImage(data: data)
            }
        }
    }
    
    func callAPIAbout() {
        let current = UIDevice.modelName
        SVProgressHUD.show()
        let param : [String: Any] = ["UserID":user_id,"Address":locationtext,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":txtaboutme.text ?? "Tell us about yourself.", "Profession": txtProfession.text ?? ""]
        
        var headers = [String:String]()
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        headers = ["Content-type": "application/json",
                   "Authorization": "Bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(updateAboutme, params: param, type: .POST, currentView: nil, header: headers) { response in
            if let json = response {
                
                SVProgressHUD.dismiss()
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                        print(userProfileData)
                        if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                            CurrentSession.shared.user = user
                        }
                    }
                    UserDefaults.standard.setValue(self.txtaboutme.text, forKey: "about")
                    UserDefaults.standard.synchronize()
                    self.updateUserProfile()
                }
                else
                {
                    if let message = json["Message"].string
                    {
                        print(message)
                        self.errorAlert("\(message)")
                        self.callTABBAR()
                    }
                    
                    SVProgressHUD.dismiss()
                }
            }
        }
        
    }
    
    func callTABBAR()
    {
        /*
        let vc = UIStoryboard().loadAddPhotosVC()
        vc.user_id = self.user_id
        self.navigationController?.pushViewController(vc, animated: true)
         anish removed this
        */
        let vc = UIStoryboard().loadEnterBirthDayVC()
        vc.user_id = self.user_id
        self.navigationController?.pushViewController(vc, animated: true)
//        LocalContactHandler.instance.getContacts()
//        let tabBarVC = UIStoryboard().loadTabBarController()
//        appDeleg.window?.rootViewController = tabBarVC
//        appDeleg.window?.makeKeyAndVisible()
    }
    
    @IBAction func Done(_ sender: Any) {
        
        callAPIAbout()
        
    }
    
    
    
    /*
     "UserID": "c46dfd1a-898c-4504-8t12-966e91a2790c", "Location":"",
     "PhoneModel":"Note 4",
     "PhoneBrand":"Samsung",
     "AboutMe":"Software Developer"
     */
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension AboutMeVC : UINavigationControllerDelegate, UIImagePickerControllerDelegate
{
    //MARK: - Take image
    @IBAction func takePhoto(_ sender: UIButton)
    {
        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default, handler: { (alert) in
            self.openCamera()
        })
        let gallery = UIAlertAction(title: "Gallery", style: .default) { (alert) in
            self.openGallary()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            pickerController.delegate = self
            self.pickerController.sourceType = UIImagePickerController.SourceType.camera
            pickerController.allowsEditing = true
            self .present(self.pickerController, animated: true, completion: nil)
        }
        else {
            let alertWarning = UIAlertView(title:"Warning", message: "You don't have camera", delegate:nil, cancelButtonTitle:"OK", otherButtonTitles:"")
            alertWarning.show()
        }
    }
    
    func openGallary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        pickerController.dismiss(animated: true, completion: nil)
        imageTake.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imageTake.layer.cornerRadius = imageTake.frame.size.width / 2.0
        
    }
}
