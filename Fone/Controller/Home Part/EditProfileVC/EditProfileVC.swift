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
import SVProgressHUD
import Alamofire
import SDWebImage

class EditProfileVC: UIViewController,CountryDataDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    //IBOutlet and Variables
    @IBOutlet weak var nameTxt : UITextField!
    @IBOutlet weak var lastTxt : UITextField!
    var emailUser : String = ""
    @IBOutlet weak var emailTxt : UITextField!
    @IBOutlet weak var addressTxt : UITextField!
    @IBOutlet weak var numberTxt : UITextField!
    @IBOutlet weak var abtProfTxt : UITextField!
    @IBOutlet weak var abtYouselfTxt : UITextView!
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var flagImg : UIImageView!
    
    @IBOutlet weak var linkNameView : UIView!
    @IBOutlet weak var phoneNumberView : UIView!
    @IBOutlet weak var professionView : UIView!
    @IBOutlet weak var aboutYourSelfView : UIView!
    
    @IBOutlet weak var btnDeletePhoto1: UIButton!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var btnAddPhoto1: UIButton!
    
    
    @IBOutlet weak var btnDeletePhoto2: UIButton!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var btnAddPhoto2: UIButton!
    
    
    @IBOutlet weak var btnDeletePhoto3: UIButton!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var btnAddPhoto3: UIButton!
    
    
    @IBOutlet weak var btnDeletePhoto4: UIButton!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var btnAddPhoto4: UIButton!
    
  
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    
    var imagePicker = UIImagePickerController()
    var userId : String?
    var imageName : String?
    let cpv = CountryPickerView()
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    var city = ""
    var arrayImage = [String]()
    var tag:Int?
    var arrPic = [String]()
    let idealMatchData = ["Group 651","Group 650","Group 649","Group 647","Group 648","Figuring out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getProfilePreference()
        imagePicker.delegate = self
        
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
                    
                    self.userId = user.userId ?? ""
                    self.nameTxt.text = user.name ?? ""
                    self.emailUser = user.email ?? ""
                    //self.emailTxt.text = user.email ?? ""
                    self.addressTxt.text = user.address ?? user.url ?? ""
                    self.numberTxt.text = user.numberWithOutCode ?? ""
                    self.codeLbl.text = user.coutryCode ?? ""
                    self.abtProfTxt.text = user.profession ?? ""
                    self.abtYouselfTxt.text = user.aboutme ?? ""
                    
                    self.abtProfTxt.text =  UserDefaults.standard.value(forKey: "about") as? String ?? ""
                    self.abtProfTxt.text =  UserDefaults.standard.value(forKey: "profession") as? String ?? ""
                    
                    for country in self.cpv.countries
                    {
                        if country.phoneCode == user.coutryCode
                        {
                            self.flagImg.image = country.flag
                        }
                    }
                    
                    if let _ = user.userImage {
                          let url = URL(string: user.userImage ?? "")!
                          self.downloadImage(from: url)
                    }
                    
                    self.getUserDetail(cnic: user.address ?? user.url ?? "", friend: "") { (userModel, success) in
                        if success {
                            self.abtProfTxt.text = userModel?.profession
                            self.abtYouselfTxt.text = userModel?.aboutme
                            if let _ = userModel?.imageUrl{
                                let url = URL(string: userModel?.imageUrl ?? "")!
                                print(url)
                                self.downloadImage(from: url)
                            }
                        } else {
                            self.showAlert("Error"," Can't get user information. Please try again.")
                        }
                        SVProgressHUD.dismiss()
                    }
                    
                }
            }
            
            //self.callUserprofileAPi()
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
        
        if appDelegateShareInst.isLocationPermissionGranted{
        appDelegateShareInst.getLocationAccess()
            
            let location = CLLocation(latitude: GLBLatitude, longitude: GLBLongitude)
            location.placemark { [self] placemark, error in
                guard let placemark = placemark else {
                    print("Error:", error ?? "nil")
                    return
                }
                
                debugPrint("Location",placemark.areasOfInterest,placemark.city,placemark.name,placemark.postalAddress,placemark.postalAddressFormatted)
                
                var locattext = ""
                if let city = placemark.city
                {
                    locattext = locattext + " " + city
                }
               if let state = placemark.state{
                locattext = locattext + ", " + state
                }
                
                if let state = placemark.country{
                    locattext = locattext + ", " + state
                 }
                 
    //            location = placemark
                self.city = locattext //placemark.postalAddressFormatted ?? (placemark.name ?? "Unknwon")
//                print(placemark.postalAddressFormatted ?? "")
            }
            
        }
        
        self.linkNameView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.linkNameView.layer.borderWidth = 1.0
        self.linkNameView.layer.cornerRadius = 12.0
        self.linkNameView.backgroundColor = .clear
        
        self.phoneNumberView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.phoneNumberView.layer.borderWidth = 1.0
        self.phoneNumberView.layer.cornerRadius = 12.0
        self.phoneNumberView.backgroundColor = .clear
        
        self.professionView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.professionView.layer.borderWidth = 1.0
        self.professionView.layer.cornerRadius = 12.0
        self.professionView.backgroundColor = .clear
        
        self.aboutYourSelfView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.aboutYourSelfView.layer.borderWidth = 1.0
        self.aboutYourSelfView.layer.cornerRadius = 12.0
        self.aboutYourSelfView.backgroundColor = .clear
        
        self.userImage.layer.cornerRadius = self.userImage.frame.size.width / 2.0
    }

    func setUpUI(){
        
        if self.image1.image == UIImage(named: "") {
            self.btnAddPhoto1.isHidden = false
            self.btnDeletePhoto1.isHidden = true
        }else{
            self.btnAddPhoto1.isHidden = true
            self.btnDeletePhoto1.isHidden = false
        }
        
        if self.image2.image == nil {
            self.btnAddPhoto2.isHidden = false
            self.btnDeletePhoto2.isHidden = true
        }else{
            self.btnAddPhoto2.isHidden = true
            self.btnDeletePhoto2.isHidden = false
        }
        
        if self.image3.image == nil {
            self.btnAddPhoto3.isHidden = false
            self.btnDeletePhoto3.isHidden = true
        }else{
            self.btnAddPhoto3.isHidden = true
            self.btnDeletePhoto3.isHidden = false
        }
        
        if self.image4.image == nil {
            self.btnAddPhoto4.isHidden = false
            self.btnDeletePhoto4.isHidden = true
        }else{
            self.btnAddPhoto4.isHidden = true
            self.btnDeletePhoto4.isHidden = false
        }
    }

    
     @IBAction func deletephotoBtn1Tapped(_ sender: UIButton) {
         self.image1.image = UIImage(named: "")
         self.btnDeletePhoto1.isHidden = true
         self.btnAddPhoto1.isHidden = false
         self.btnAddPhoto1.setImage(UIImage(named: "Add Icon"), for: .normal)
     }
  
     @IBAction func addPhotsBtn1Tapped(_ sender: UIButton) {
         self.tag = sender.tag
         self.alert(sender:sender)
     }
     

     
     @IBAction func deletephotoBtn2Tapped(_ sender: UIButton) {
         self.image2.image = UIImage(named: "")
         self.btnDeletePhoto2.isHidden = true
         self.btnAddPhoto2.isHidden = false
         self.btnAddPhoto2.setImage(UIImage(named: "Add Icon"), for: .normal)
     }

     @IBAction func addPhotsBtn2Tapped(_ sender: UIButton) {
         self.tag = sender.tag
         self.alert(sender:sender)
     }
     
   
     
     @IBAction func deletephotoBtn3Tapped(_ sender: UIButton) {
         self.image3.image = UIImage(named: "")
         self.btnDeletePhoto3.isHidden = true
         self.btnAddPhoto3.isHidden = false
         self.btnAddPhoto3.setImage(UIImage(named: "Add Icon"), for: .normal)
     }
     
     @IBAction func addPhotsBtn3Tapped(_ sender: UIButton) {
         self.tag = sender.tag
         self.alert(sender:sender)
     }
     
     
     
     @IBAction func deletephotoBtn4Tapped(_ sender: UIButton) {
         self.image4.image = UIImage(named: "")
         self.btnDeletePhoto4.isHidden = true
         self.btnAddPhoto4.isHidden = false
         self.btnAddPhoto1.setImage(UIImage(named: "Add Icon"), for: .normal)
     }

     @IBAction func addPhotsBtn4Tapped(_ sender: UIButton) {
         self.tag = sender.tag
         self.alert(sender:sender)
     }
     
    func getProfilePreference() {
        
        let userID = self.userId
        let url = "\(getProfilePic)?UserId=\(userID ?? "")"
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default)
                .responseJSON { response in

                    switch response.result {

                    case .success(let json):
                        print(json)
                       
                        let data = json as! [String:Any]
                        let profileData = data["UserProfileData"] as? [String:Any]
                        self.arrPic = profileData?["Urls"] as? [String] ?? []
                        
                        if self.arrPic.count > 0 {
                            self.image1.sd_setImage(with: URL(string: self.arrPic[0]))
                            self.btnAddPhoto1.isHidden = true
                            self.btnDeletePhoto1.isHidden = false
                            
                            self.btnAddPhoto2.isHidden = false
                            self.btnDeletePhoto2.isHidden = true
                            
                            self.btnAddPhoto3.isHidden = false
                            self.btnDeletePhoto3.isHidden = true
                            
                            self.btnAddPhoto4.isHidden = false
                            self.btnDeletePhoto4.isHidden = true
                            
                           
                        }
                        if self.arrPic.count > 1 {
                            self.image2.sd_setImage(with: URL(string: self.arrPic[1]))
                            self.btnAddPhoto2.isHidden = true
                            self.btnDeletePhoto2.isHidden = false
                            
                            self.btnAddPhoto3.isHidden = false
                            self.btnDeletePhoto3.isHidden = true
                            
                            self.btnAddPhoto4.isHidden = false
                            self.btnDeletePhoto4.isHidden = true
                            
                        }
                        if self.arrPic.count > 2 {
                            self.image3.sd_setImage(with: URL(string: self.arrPic[2]))
                            self.btnAddPhoto3.isHidden = true
                            self.btnDeletePhoto3.isHidden = false
                            
                            self.btnAddPhoto4.isHidden = false
                            self.btnDeletePhoto4.isHidden = true
                            
                           
                        }
                        if self.arrPic.count > 3 {
                            self.image4.sd_setImage(with: URL(string: self.arrPic[3]))
                            self.btnAddPhoto4.isHidden = true
                            self.btnDeletePhoto4.isHidden = false
                        }
                        
                        if self.arrPic.count == 0 {
                            self.image1.image = UIImage(named: "")
                            self.image2.image = UIImage(named: "")
                            self.image3.image = UIImage(named: "")
                            self.image4.image = UIImage(named: "")
                            self.btnAddPhoto1.isHidden = false
                            self.btnDeletePhoto1.isHidden = true
                            self.btnAddPhoto2.isHidden = false
                            self.btnDeletePhoto2.isHidden = true
                            self.btnAddPhoto3.isHidden = false
                            self.btnDeletePhoto3.isHidden = true
                            self.btnAddPhoto4.isHidden = false
                            self.btnDeletePhoto4.isHidden = true
                           
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
            }
    }
    
    
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            guard let response  = response as? HTTPURLResponse, response.statusCode != 403 else {
                return
            }
            debugPrint(response.statusCode)
            
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
        flagImg.image = flag
    }

    @IBAction func photoBtnTapped(_ sender : UIButton) {
        self.tag = sender.tag
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
        imagePicker.allowsEditing = true
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
        
//OLD
//        userImage.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
//
        
        
//   ImagePIcker New
            
        
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            if self.tag == 0{
            self.userImage.image = pickedImage
            }else if self.tag == 1{
                image1.autoresizingMask = [.flexibleWidth,.flexibleHeight,.flexibleBottomMargin,.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin]
             image1.contentMode = .scaleToFill
             image1.clipsToBounds = true
             image1.image = pickedImage
             self.btnAddPhoto1.isHidden = true
             self.btnDeletePhoto1.isHidden = false
         }else if self.tag == 2{
             image2.autoresizingMask = [.flexibleWidth,.flexibleHeight,.flexibleBottomMargin,.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin]
             image2.contentMode = .scaleToFill
             image2.clipsToBounds = true
             image2.image = pickedImage
             self.btnAddPhoto2.isHidden = true
             self.btnDeletePhoto2.isHidden = false
         }else if self.tag == 3{
             image3.autoresizingMask = [.flexibleWidth,.flexibleHeight,.flexibleBottomMargin,.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin]
             image3.contentMode = .scaleToFill
             image3.clipsToBounds = true
             image3.image = pickedImage
             self.btnAddPhoto3.isHidden = true
             self.btnDeletePhoto3.isHidden = false
         }else if self.tag == 4{
             image4.contentMode = .scaleToFill
             image4.autoresizingMask = [.flexibleWidth,.flexibleHeight,.flexibleBottomMargin,.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin]
             image4.clipsToBounds = true
             image4.image = pickedImage
             self.btnAddPhoto4.isHidden = true
             self.btnDeletePhoto4.isHidden = false
         }

            self.tag = nil
           
        }
        
//
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
//        else if (emailTxt.text?.isEmpty)!
//        {
//            self.errorAlert("Please enter your email!")
//            return false
//        }
//        else if !Utility.sharedInstance.isValidEmail(emailTxt.text!) {
//            self.errorAlert("Please enter a valid email!")
//            return false
//        }
        else if (numberTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your phone number!")
            return false
        }
        return true
    }
    
    func updateProfileAPI()
    {
        
        SVProgressHUD.show()
        let image : UIImage? = userImage.image
        //let imageData = image!.jpegData(compressionQuality: 1)
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let phoneNumber = codeLbl.text! + numberTxt.text!
        
        let paramDic: NSMutableDictionary = [:]
        paramDic.setValue(self.city, forKey: "FoneMe")
        
        let parameters = [
            "Name" : nameTxt.text!,
            "UserId" : userId ?? "",
            "PhoneNumber" : phoneNumber,
            "Email" : emailUser,
            "Address" : self.addressTxt.text ?? "",
            "FatherName" : "",
            ] as [String : Any]

        var headers = [String:String]()
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
                    
                    if let url = userInfo?["Url"]?.string {
                        user.url = url
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
                   
                    if let aboutMe = userInfo?["AboutMe"]?.dictionary
                    {
                        if let profession = aboutMe["Profession"]?.string {
                            user.profession = profession
                        }
                        
                        if let about = aboutMe["AboutMe"]?.string {
                            user.aboutme = about
                        }
                    }
                    
                    
//                    self.callAPIAbout()
                    
                   if let userProfileData = try? PropertyListEncoder().encode(user) {
                       UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                       UserDefaults.standard.synchronize()
                   }
                    
                }else {
                    let alertController = UIAlertController(title: "Error", message: "Please enter unique fone id", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                    }
                    
                    alertController.addAction(action1)
                    self.present(alertController, animated: true, completion: nil)

                }
            }
            self.SignUpAddPhotosAPI()
        }
    }
    
    func callAPIAbout()
    {
        let current = UIDevice.modelName
        SVProgressHUD.show()
        let param : [String: Any] = ["UserID":userId ?? "","Address": self.city ,"PhoneModel":current,"PhoneBrand":"iPhone","AboutMe":abtYouselfTxt.text ?? "Hey there! I am using Fone Messenger.","Profession": abtProfTxt.text ?? ""]
        
        print(param)
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        debugPrint("PARAM", param)
        ServerCall.makeCallWitoutFile(updateAboutme, params: param, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            SVProgressHUD.dismiss()
            
            if let json = response {

                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    UserDefaults.standard.setValue(self.abtProfTxt.text, forKey: "about")
                    UserDefaults.standard.setValue(self.abtYouselfTxt.text, forKey: "profession")

                    UserDefaults.standard.synchronize()
//                    self.callTABBAR()
                    //self.navigationController?.popViewController(animated: true)
                    
                    let alertController = UIAlertController(title: "Success", message: "You have successfully updated your profile.", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                        
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    alertController.addAction(action1)
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                else
                {
                    if let message = json["Message"].string
                    {
                        print(message)
                        self.errorAlert("\(message)")
//                        self.callTABBAR()
                    }
                    
                    SVProgressHUD.dismiss()
                }
            }
        }
        
    }
    
   func callUserprofileAPi()
   {
       SVProgressHUD.show()
        self.getUserProfile(cnic: userProfile.address ?? "", friend: "") { (user, success) in
            SVProgressHUD.dismiss()
            if success {
            
                userProfile.name = user?.name
                userProfile.email = user?.email
                
                self.userId = user?.userId ?? ""
                self.nameTxt.text = user?.name ?? ""
                self.emailUser = user?.email ?? ""
                //self.emailTxt.text = user.email ?? ""
                self.numberTxt.text = user?.mobileNumberWithoutCode ?? ""
                self.codeLbl.text = user?.countryCode ?? ""
                self.abtProfTxt.text = user?.profession ?? ""
                self.abtYouselfTxt.text = user?.aboutme ?? ""
                
                
                 if let userProfileData = try? PropertyListEncoder().encode(user) {
                     UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                     UserDefaults.standard.synchronize()
                 }
            }

            }
   }
    
//   ImagePIcker New

func alert(sender:UIButton){
    let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
        self.openCamera()
    }))
    
    alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
        self.openGallary()
    }))
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    switch UIDevice.current.userInterfaceIdiom {
    case .pad:
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        alert.popoverPresentationController?.permittedArrowDirections = .up
    default:
        break
    }
    self.present(alert, animated: true, completion: nil)
}


func openCamera()
    {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func openGallary(){
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }

// New AddPhotsAPI

func SignUpAddPhotosAPI() {
    
    SVProgressHUD.show()
    
    let image1 : UIImage? = self.image1.image
    let image2 : UIImage? = self.image2.image
    let image3 : UIImage? = self.image3.image
    let image4 : UIImage? = self.image4.image
    
    //let imageData = image!.jpegData(compressionQuality: 1)
    let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
//        var imageParams : [String : [OMFile]]?
    var imageParams:[[String:OMFile]] = []
    
    if image1 != nil {
        let imageFile1 = OMFile(image: image1!, of: CGSize(width: 210, height: 210))
        var imageParam1 = ["Userimgs1" : imageFile1]
        imageParams.append(imageParam1)
    }
    if image2 != nil {
        let imageFile2 = OMFile(image: image2!, of: CGSize(width: 210, height: 210))
        var imageParam2 = ["Userimgs2" : imageFile2]
        imageParams.append(imageParam2)
    }
    if image3 != nil {
        let imageFile3 = OMFile(image: image3!, of: CGSize(width: 210, height: 210))
        let imageParam3 = ["Userimgs3" : imageFile3]
        imageParams.append(imageParam3)
    }
    if image4 != nil {
        let imageFile4 = OMFile(image: image4!, of: CGSize(width: 210, height: 210))
        let imageParam4 = ["Userimgs4" : imageFile4]
        imageParams.append(imageParam4)
    }
    
    
    let parameters = [
        "UserId" : self.userId ?? "" ,
        "Dob" : "1997-04-26",
        "GenderId" : "1",
        "IdealMatchId" : "2" ,
        "IsNewImg" : "True",
        "PreviousImgUrls" : "",
        "ProfessionalInterestId" : ""
        ] as [String : Any]
    
     print(parameters)
     print(imageParams)

     var headers = [String:String]()
     headers = ["Content-Type": "application/json"]
     print(headers)
                  
    if imageParams.count == 0 {
        
         let imageParams = [[:]]
    }

    ServerCall.makeCallWithMultipleFile(UpdateSingnUpProfile, params: parameters as [String : Any], files: imageParams, type: Method.POST, currentView: self.view, header: headers) { (response) in

        if let json  = response {
            print(json)
            
            if json["StatusCode"].string == "200" {
            print("success")
                let photosData = json["UserPreference"]["Urls"]
            }else {
                let alertController = UIAlertController(title: "Error", message: "Please enter unique fone id", preferredStyle: .alert)
                
                let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                }
                
                alertController.addAction(action1)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        self.callAPIAbout()
        SVProgressHUD.dismiss()
        
    }
  }
}

extension EditProfileVC : UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.idealMatchData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? IdealMatchEditProfileCell {
            cell.imgView.image = UIImage(named: self.idealMatchData[indexPath.row])
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3.0 - 8, height: 130.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
     print("did select ideal match collectionView")
    }
}
