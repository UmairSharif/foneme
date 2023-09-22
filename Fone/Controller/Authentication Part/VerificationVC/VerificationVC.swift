//
//  VerificationVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import NVActivityIndicatorView
import SendBirdSDK
import SVProgressHUD

class VerificationVC: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var lablVerification: UILabel!
    @IBOutlet weak var lablPlzEnterCode: UILabel!
    @IBOutlet weak var lablSecond: UILabel!
    @IBOutlet weak var lablEnterCode: UILabel!
    
    @IBOutlet var labelTimer: UILabel!
    @IBOutlet var tfCode: UITextField!
    @IBOutlet var btnResend: UIButton!
    @IBOutlet var btnSubmit: UIButton!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    
    var phone:String = ""
    var time = 120
    var timer = Timer()
    var verificationId = ""
    var mobileNumber : String?
    var email : String?
    var userId : String?
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    var testSMSCode = ""
    var isfromsignup = false
    var isnewuseer = false
    var user = User()
    
    var mobileRegistrationInformaton:[String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnResend.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(action), userInfo: nil, repeats: true)
        
        tfCode.delegate = self
        
        if let mobileNumber , !mobileNumber.isEmpty
        {
            self.lablEnterCode.text = "Please enter the code\nsent to " + mobileNumber
        }
        else
        {
            self.lablEnterCode.text = "Please enter the code\nsent to " + (email ?? "")
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
                 
                   let alertController = UIAlertController(title: "No Internet!", message: "Please connect your device to the internet.", preferredStyle: .alert)
                           
                   let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                       
                   }

                   alertController.addAction(action1)
                   self.present(alertController, animated: true, completion: nil)
                   
                   }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.resignFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        
        tfCode.becomeFirstResponder()
        timer.invalidate()
        time = 120
        labelTimer.text = String(time)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(action), userInfo: nil, repeats: true)
    }
    
    @IBAction func backTapped(_ sender: UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resendBtnTapped(_ sender : UIButton)
    {
        //Resend Pincode API
        time = 120
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(action), userInfo: nil, repeats: true)
        btnResend.isHidden = true
        btnSubmit.isHidden = false

        self.resendPincodeAPI()
    }
    
    // MARK: - TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        return true
    }
    
    //MARK: - Functions
    @objc func checkTF(textField: UITextField)
    {
       
    }
    
    @objc func action()
    {
        time -= 1
        if time == 0
        {
            btnResend.isHidden = false
            btnSubmit.isHidden = true
            timer.invalidate()
        }
        labelTimer.text = String(time)
    }
    
    func isVerifiedFields() -> Bool
    {
        if (tfCode.text?.isEmpty)!
        {
            self.errorAlert("Please enter your pincode!")
            return false
        }
        return true
    }
    
    @IBAction func sendBtnTapped(_ sender: UIButton)
    {
        if isVerifiedFields()
        {
            verify()
        }
    }
    
    func ABoutmeOpen() {
        
    }
    func verify()
    {
        if let mobileNumber , !mobileNumber.isEmpty
        {
            guard let smsOtp = tfCode.text else {
                self.showAlert("Please enter a verifcation code first.")
                return
            }
            if !smsOtp.isEmpty {
                PhoneAuthManager.shared.verifyCode(otp: smsOtp) { [weak self] status,error in
                    guard let `self`  = self else { return }
                    if status {
                        //push to home screen
                        if !self.isnewuseer{
                            self.getAccessTokenAPI(mobileNumber : self.mobileNumber ?? "",user_id: "")
                        }else{
                            self.registerUserForPhoneNumber(firebaseSMSOtp: smsOtp)
                        }
                        
                    }else{
                        print("Wrong OTP or check server")
                        self.showAlert("Please enter a valid verifcation code.")
                    }
                }
            }else{
                self.showAlert("Please enter a verifcation code first.")
            }
        }
        else
        {
            verifyEmailApi()
        }
    }
    
    func verifyEmailApi()
    {
        SVProgressHUD.show()
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        let voipToken = UserDefaults.standard.string(forKey: "VoipToken")
        let code = tfCode.text!
        let pinCode = code
        let testUser = false
       
//        let params = ["email": email ?? "",
//                      "code" : pinCode,
//                      "UserId" : userId ?? "",
//                      "DeviceToken" : deviceToken ?? "",
//                      "IsUserTesting": testUser ,
//                      "VOIPDeviceToken" : voipToken ?? ""] as [String:Any]
        
        let params = [
                      "code" : pinCode] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(VerificationCode2Url, params: params, type: Method.GET, currentView: nil, header: headers) { (response) in
            SVProgressHUD.dismiss()
            
            if let json = response {
                let statusCode = json["StatusCode"].string ?? ""
                let IsSuccess = json["IsSuccess"].bool ?? false
                
                if statusCode == "200" || statusCode == "201" || IsSuccess == true
                {
                    let isUserVerified = json["IsUserVerified"].bool ?? false
                    
//                    if isUserVerified
//                    {
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
                            
                            CurrentSession.shared.user = user
                            if let userProfileData = try? PropertyListEncoder().encode(user) {
                                UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                                UserDefaults.standard.synchronize()
                                
                                var USER_ID : String?
                                var USER_NAME : String?
                                
                                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                                    print(userProfileData)
                                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                                        USER_ID = user.mobile
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
                            
                            self.getAccessTokenAPI(mobileNumber :  user.mobile ?? "" , user_id: user.userId ?? "")
                            
                        }
                        
                        // Get Access Token API
                       // self.getAccessTokenAPI(mobileNumber : self.mobileNumber ?? "")
                    //}
                }
                else
                {
                    self.errorAlert("Verification code not accepted. Please carefully check the code and submit again")
                    
                    //SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    func registerUserForPhoneNumber(firebaseSMSOtp:String){
        SVProgressHUD.show()
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        mobileRegistrationInformaton?["Code"]  =  firebaseSMSOtp
//        if !isnewuseer {
//            self.verifyPincodeAPI()
//            return
//        }
        if let info =  mobileRegistrationInformaton {
            
            ServerCall.makeCallWitoutFile(registerUrl, params: info, type: Method.POST, currentView: nil, header: headers) { (response) in
                SVProgressHUD.dismiss()
                if let json = response {
                    print(json)
                    SVProgressHUD.dismiss()
                    let statusCode = json["StatusCode"].string ?? ""
                    if statusCode == "200" || statusCode == "201" {
                        let userId = json["UserId"].string ?? ""
                        self.userId = userId
//                        self.verifyPincodeAPI()
                    self.getAccessTokenAPI(mobileNumber : self.mobileNumber ?? "",user_id: userId )
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
                else {
                    SVProgressHUD.dismiss()
                    self.errorAlert("Something went wrong. Please try again later.")
                }
            }
        }
    }
    
    
    func verifyPincodeAPI() {
        self.getAccessTokenAPI(mobileNumber : self.mobileNumber ?? "",user_id: userId ?? "")
    }
    
    func getAccessTokenAPI(mobileNumber : String,user_id:String) {
        SVProgressHUD.show()
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let parameters : [String : Any] = [
            "username": mobileNumber,
            "password" : "123456",
            "client_id" : ClientId,
            "grant_type" : "password"
        ]
        
        print("parameters = \(parameters) \n getAccessTokenUrl = \(getAccessTokenUrl)")

        
        Alamofire.request(getAccessTokenUrl, method: .post, parameters: parameters, encoding:  URLEncoding.httpBody, headers: headers).responseJSON { (response:DataResponse<Any>) in
            SVProgressHUD.dismiss()
            
            switch(response.result) {
            case.success(let data):
                print("success")
                let json = JSON(data)
                let accessToken = json["access_token"].string ?? ""
                //Call Local Contacts Function
                
                UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                
                if self.email == "" || self.email == nil {
                    let user = User()
                    user.userId = user_id
                    user.name = self.mobileRegistrationInformaton?["Name"] as? String
                    user.numberWithOutCode = self.mobileRegistrationInformaton?["NumberWithOutCode"] as? String
                    user.coutryCode = self.mobileRegistrationInformaton?["CountryCode"] as? String
                    user.mobile = self.mobileRegistrationInformaton?["PhoneNumber"] as? String
                    if let userProfileData = try? PropertyListEncoder().encode(user) {
                        UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                        UserDefaults.standard.synchronize()
                    }
                }
                
  
                if self.isnewuseer == true
                {
                //AboutMeVC
                let vc = UIStoryboard().loadAboutVC()
                vc.user_id = user_id
                vc.mobileNumber = mobileNumber
                    FirebaseChatManager.shared.setUserInFirebase()
                self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    if mobileNumber != "+00" && mobileNumber.count > 8 {
                        self.getProfileWithPhone(mobileNumber: mobileNumber)
                    }else {
                      LocalContactHandler.instance.getContacts()
                      let tabBarVC = UIStoryboard().loadTabBarController()
                      appDeleg.window?.rootViewController = tabBarVC
                      appDeleg.window?.makeKeyAndVisible()
                    }
                    
                }
           
            case.failure(let error):
                print("Not Success",error)
                self.errorAlert("\(error)")
            }
        }
    }
    
    func getProfileWithPhone(mobileNumber:String){
        
        self.getUserDetailPhone(cnic:mobileNumber , friend: "" ) { (user, success) in
            if success {
                    let userInfo = User()
                userInfo.userId = user?.userId
                userInfo.name = user?.name
                userInfo.email = user?.email
                userInfo.mobile = user?.phoneNumber

                    
                userInfo.numberWithOutCode = user?.mobileNumberWithoutCode
                    
                userInfo.coutryCode = user?.countryCode
                userInfo.aboutme = user?.aboutme
                userInfo.profession = user?.profession
                userInfo.address = user?.cnic
                userInfo.url = user?.cnic
                if let userProfileData = try? PropertyListEncoder().encode(userInfo) {
                    UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                    UserDefaults.standard.synchronize()
                }
            
                LocalContactHandler.instance.getContacts()
                FirebaseChatManager.shared.setUserInFirebase()
                let tabBarVC = UIStoryboard().loadTabBarController()
                appDeleg.window?.rootViewController = tabBarVC
                appDeleg.window?.makeKeyAndVisible()
            }else{
                print("get profile error",success)
            }
        }
    }
    
    
    func apiUpdateProfilePreference() {
        guard let info =  mobileRegistrationInformaton else { return }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let headers = ["Content-type": "application/json",
                   "Authorization": "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(updateProfilePreference, params: info, type: .POST, currentView: nil, header: headers) { response in
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
                    CurrentSession.shared.user = user
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
        }
    }
    

    func resendPincodeAPI()
    {
        SVProgressHUD.show()
        
        PhoneAuthManager.shared.startAuth(phoneNumber: mobileNumber ?? "") { status , error in
            if !status  {
                self.errorAlert("You are not a registered user, please SignUp first!")
            }
            SVProgressHUD.dismiss()
        }
    }
}
extension VerificationVC {
    //MARK: Mobile Number  Verification Code through Firebase
    func firebaseAuth(phone:String,countryCode:String,completion: @escaping ((Bool,Error?) -> Void) ){
        SVProgressHUD.dismiss()
        if !phone.isEmpty && !countryCode.isEmpty {
            print("Country Code : \(countryCode) & Phone Number \(phone)")
            let mobileNumber = "\(countryCode)\(phone)"
            PhoneAuthManager.shared.startAuth(phoneNumber: mobileNumber) { status , error in
                if status  {
                    completion(true,nil)
                } else{
                    completion(false,error)
                }
            }
        }else{
            self.showAlert("Phone number or Country Code is missing.")
        }
    }
}
