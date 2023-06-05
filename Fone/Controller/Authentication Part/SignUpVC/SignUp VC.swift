//
//  SignUp VC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SafariServices
import SwiftyJSON
import Alamofire
import SVProgressHUD
import SendBirdSDK

class SignUpVC: UIViewController, CountryDataDelegate {
    
    //IBOutlet and Variables
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var phoneTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var textFieldFoneId: UITextField!
    @IBOutlet weak var codeLbl: UILabel!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var flagBtn: UIImageView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    let network = NetworkManager.sharedInstance
    var netStatus: Bool?
    var user: User?
    
    var isSocailProfileCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        setupDelegates()
        setupAttributedTexts()
        
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
            
            let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                
            }
            
            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)
            
        }
    }
    
    private func setupDelegates() {
        phoneTxt.delegate = self
    }
    
    private func setupAttributedTexts() {
        let attributedString = TextStyling.applyAttributedTextStyle(firstString: "Already user have an account?", secondString: " Login")
        loginBtn.setAttributedTitle(attributedString, for: .normal)
    }
    
    @IBAction func onPrivacyPolicyTapped(_ sender: UIButton) {
        let safariVC = SFSafariViewController(url: URL(string: "https://www.fone.me/privacy")!)
        present(safariVC, animated: true, completion: nil)
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton)
    {
        if isVerifiedFields()
        {
            //            let vc = UIStoryboard().loadAboutVC()
            //            vc.Userid = ""
            //            self.navigationController?.pushViewController(vc, animated: true)
            //            return
            let vc = UIStoryboard().loadSingUpNameVC()
            vc.phoneCode = self.codeLbl.text!
            vc.phoneNumber = self.phoneTxt.text!
            self.navigationController?.pushViewController(vc, animated: true)
            
            // Registeration API Call
            //self.registerAPI()
        }
    }
    
    @IBAction func loginBtnTapped(_ sender: UIButton)
    {
        //self.navigationController?.popViewController(animated: true)
        //        let vc = UIStoryboard().loadMobileVC()
        //        vc.isfromsignup = true
        //        self.navigationController?.pushViewController(vc, animated: true)
        
        let phone = PhoneEmailVC(nibName: "PhoneEmailVC", bundle: nil)
        self.navigationController?.pushViewController(phone, animated: true)
        
        //        let storyboard = UIStoryboard(name: "GroupChannel", bundle: nil)
        //        let vc1 = storyboard.instantiateViewController(withIdentifier: "TestingVC")
        //        self.navigationController?.pushViewController(vc1, animated: true)
    }
    
    @IBAction func codeBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadCountryCodeVC()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func phone_email_action(_ sender: UIButton) {
        let phone = PhoneEmailVC(nibName: "PhoneEmailVC", bundle: nil)
        phone.from_sign_up = true
        self.navigationController?.pushViewController(phone, animated: true)
    }
    
    @IBAction func googleBtnTapped(_ sender: UIButton) {
        self.socialLogin(with: .google)
    }
    
    @IBAction func appleBtnTapped(_ sender: UIButton) {
        self.socialLogin(with: .apple)
    }
    
    @IBAction func facebookBtnTapped(_ sender: UIButton) {
        self.socialLogin(with: .facebook)
    }
    
    func selectedCountry(countryName: String, countryCode: String, flag: UIImage) {
        codeLbl.text = countryCode
        flagBtn.image = flag
    }
    
    func isVerifiedFields() -> Bool
    {
        /*if nameTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
         self.errorAlert("Please enter your name!")
         return false
         }
         
         if nameTxt.text?.hasDigits() ?? false {
         self.errorAlert("No digits in name please!")
         return false
         }
         
         if textFieldFoneId.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
         self.errorAlert("Please enter your Fone Id!")
         return false
         }
         
         if let foneId = textFieldFoneId.text,
         !foneId.isValidFoneId {
         self.errorAlert("Please enter your a valid Fone Id!")
         return false
         }*/
        
        if phoneTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your phone number!")
            return false
        }
        
        guard let phoneNumber = phoneTxt.text, (phoneNumber.count >= 6 && phoneNumber.count <= 10) else {
            self.errorAlert("Please enter valid phone number!")
            return false
        }
        
        return true
    }
}

extension SignUpVC
{
    func registerAPI() {
        
        SVProgressHUD.show()
        
        var mobileNumber = codeLbl.text! + phoneTxt.text!
        mobileNumber.remove(at: mobileNumber.startIndex)
        let params = ["Name": nameTxt.text!,
                      "CNIC": textFieldFoneId.text!,
                      "PhoneNumber": mobileNumber,
                      "Password": "",
                      "CountryCode": codeLbl.text!,
                      "FatherName": "iOS",
                      "NumberWithOutCode": phoneTxt.text!] as [String: Any]
        // "CNIC": textFieldFoneId.text!,
        
        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(registerUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                SVProgressHUD.dismiss()
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201" {
                    
                    let userId = json["UserId"].string ?? ""
                    let number = self.codeLbl.text! + self.phoneTxt.text!
                    
                    let alertController = UIAlertController(title: "Success", message: "You are successfully registered now.", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                        
                        let vc = UIStoryboard().loadVerificationVC()
                        vc.userId = userId
                        vc.mobileNumber = number
                        vc.isnewuseer = true
                        //                        SBUGlobals.CurrentUser = SBUUser(userId: userId, nickname: self.nameTxt.text!)
                        //                                         SBUMain.connect { user, error in
                        //
                        //                                             if let user = user {
                        //                                                 UserDefaults.standard.set(userId, forKey: "user_id")
                        //                                                UserDefaults.standard.set(self.nameTxt.text!, forKey: "nickname")
                        //
                        //                                                 print("SBUMain.connect: \(user)")
                        //                                            }
                        //                        }
                        self.navigationController?.pushViewController(vc, animated: true)
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
                    }
                    
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
}

// Allow up to 10 digits only
extension SignUpVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Prevent "0" characters as the first characters. (i.e.: There should not be values like "003" "01" "000012" etc.)
        if textField.text?.count == 0 && string == "0" {
            return false
        }
        
        let charsLimit = 10
        
        let startingLength = textField.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        let newLength = (startingLength + lengthToAdd - lengthToReplace)
        
        return newLength <= charsLimit
    }
}

// MARK: - Social Login

extension SignUpVC {
    
    private func socialLogin(with socialAccount: SocialLoginManager.Provider) {
        
        SocialLoginManager
            .shared
            .logOut(with: socialAccount)
        
        SocialLoginManager
            .shared
            .login(
                with: socialAccount,
                presenter: self
            ) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.loginWithSocial(user, FromProvider: socialAccount)
                    break
                case .failure(let error):
                    self?.errorAlert(error.localizedDescription)
                }
            }
    }
}

extension SignUpVC {
    
    private func loginWithSocial(_ account: SocialLoginUser, FromProvider provider: SocialLoginManager.Provider) {
        SVProgressHUD.show()
        let params = ["SocialId": account.id ?? "",
                      "SocialType" : provider.name,
                      "Email" : account.email ?? "",
                      "Name" : account.name ?? "",
                      "ProfileImg": account.profileImageURL ?? "",
                      "FirstName" : account.firstName ?? "",
                      "LastName" : account.lastName ?? ""] as [String:Any]
        
        print("params: \(params)")
        let headers = [
            "Content-Type": "application/json",
            "api-key": "#56#$FDSR#$%B^"
        ]
        
        ServerCall.makeCallWitoutFile(socialLoginUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            SVProgressHUD.dismiss()
            
            if let json = response {
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    let isUserVerified = json["IsUserVerified"].bool ?? false
                    self.isSocailProfileCompleted = json["IsProfileCompleted"].bool ?? false
                    
                    if isUserVerified
                    {
                        if let userInfo = json["UserInfo"].dictionary
                        {
                            let user = User()
                            
                            if let name = userInfo["Name"]?.string {
                                user.name = name
                            }
                            
                            if let email = userInfo["Email"]?.string {
                                user.email = email
                            }
                            
                            if let address = userInfo["Address"]?.string {
                                user.address = address
                            }
                            
                            if let userImage = userInfo["ImageUrl"]?.string {
                                user.userImage = userImage
                            }
                            
                            if let withOutCodeNumber = userInfo["PhoneNumberWithoutCode"]?.string {
                                user.numberWithOutCode = withOutCodeNumber
                            }
                            
                            if let countryCode = userInfo["CountryCode"]?.string {
                                user.coutryCode = countryCode
                            }
                            
                            if let mobileNumber = userInfo["PhoneNumber"]?.string {
                                user.mobile = mobileNumber
                            }
                            if let userId = userInfo["UserId"]?.string {
                                user.userId = userId
                            }
                            if let url = userInfo["Url"]?.string, !url.isEmpty {
                                user.url = url
                                user.address = url
                            }
                            user.isSocialLogin = true
                            self.user = user
                            if let userProfileData = try? PropertyListEncoder().encode(user) {
                                UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                                UserDefaults.standard.synchronize()
                                
                                var USER_ID : String?
                                var USER_NAME : String?
                                
                                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                                    print(userProfileData)
                                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                                        USER_ID = user.email
                                        USER_NAME = user.name
                                        
                                        let userDefault = UserDefaults.standard
                                        userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
                                        userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
                                        
                                        ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { sbuser, error in
                                            guard error == nil else {
                                                if let _ = user.userImage{
                                                    SBDMain.updateCurrentUserInfo(withNickname: user.name, profileUrl: user.userImage) { (error) in
                                                        print(error ?? "not an error")
                                                    }
                                                }
                                                return
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // Get Access Token API
                        if provider.name == "Apple" {
                            self.getAccessTokenAPI(socialId: account.id, email: account.email ?? "")
                        }else {
                            self.getAccessTokenAPI(socialId:"", email: account.email ?? "")
                        }
                    }
                }
                else
                {
                    self.errorAlert("Email is already registered !")
                }
            }
        }
    }
    
    func getAccessTokenAPI(socialId : String,email:String) {
        SVProgressHUD.show()
        let headers = [
            "Content-Type": "application/json",
            "api-key": "#56#$FDSR#$%B^"
        ]
        let parameters : [String : Any] = [
            "username": socialId,
            "password": "",
            "client_id": ClientId,
            "grant_type": "password"
        ]
        
        print("parameters = \(parameters) \n getAccessTokenUrl = \(socialAccessTokenUrl)")
        
        
        Alamofire.request(socialAccessTokenUrl, method: .post, parameters: parameters, encoding:  URLEncoding.httpBody, headers: headers).responseJSON { [weak self] (response:DataResponse<Any>) in
           
            guard let self = self else { return }
            switch(response.result) {
            case.success(let data):
                print("success")
                let json = JSON(data)
                let accessToken = json["access_token"].string ?? ""
                //Call Local Contacts Function
                if !self.isSocailProfileCompleted {
                    SVProgressHUD.dismiss()
                    let vc = UIStoryboard().loadSingUpNameVC()
                    vc.user = self.user
                    vc.accessToken = accessToken
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self.socialLoginToProfile(email: email, socialId: socialId, accessToken: accessToken)
                }
                
            case.failure(let error):
                print("Not Success",error)
                self.errorAlert("\(error)")
            }
        }
    }
    
    
    func socialLoginToProfile(email:String,socialId:String,accessToken:String){
        let params = ["Email":email,"SocialId":socialId]
        
        Alamofire.request("https://test.zwilio.com/api/account/v1/socialLoginToProfile?Email=\(email)&SocialId=\(socialId)",method: .post,parameters: params,encoding:URLEncoding.httpBody).responseJSON { response in
            if response.result.isSuccess {
                let value:JSON = JSON(response.result.value!)
                print(value)
                let statusCode = value["StatusCode"].string ?? ""
                if statusCode == "409" {
                    SVProgressHUD.dismiss()
                    let vc = UIStoryboard().loadSingUpNameVC()
                    vc.user = self.user
                    vc.accessToken = accessToken
                    self.navigationController?.pushViewController(vc, animated: true)
                }else if statusCode == "200" {
                    let profileData = value["UserProfileData"]
                    let userModel = UserDetailModel(fromJson: profileData)
                    UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.synchronize()
                    let userInfo = User()
                    userInfo.userId = userModel.userId
                    userInfo.name = userModel.name
                    userInfo.email = userModel.email
                    userInfo.mobile = userModel.phoneNumber
                    userInfo.numberWithOutCode = userModel.mobileNumberWithoutCode
                    userInfo.coutryCode = userModel.countryCode
                    userInfo.aboutme = userModel.aboutme
                    userInfo.profession = userModel.profession
                    userInfo.address = userModel.cnic
                    userInfo.url = userModel.cnic
                    
                    if let userProfileData = try? PropertyListEncoder().encode(userInfo) {
                        UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                        UserDefaults.standard.synchronize()
                    }
                    
                    SVProgressHUD.dismiss()
                    LocalContactHandler.instance.getContacts()
                    let tabBarVC = UIStoryboard().loadTabBarController()
                    appDeleg.window?.rootViewController = tabBarVC
                    appDeleg.window?.makeKeyAndVisible()
                }
            }else {
                print("Error in socialLoginToProfile api \(response.result.error!.localizedDescription)")
            }
        }
    }
}

