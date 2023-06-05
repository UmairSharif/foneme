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
    var userId : String?
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    var testSMSCode = ""
    var isfromsignup = false
    var isnewuseer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnResend.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(action), userInfo: nil, repeats: true)
        
        tfCode.delegate = self
        
        self.lablEnterCode.text = "Please enter the code\nsent to " + mobileNumber!
        
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
            // Verify Pincode API
            self.verifyPincodeAPI()
        }
    }
    
    
    
    
    
    func ABoutmeOpen()
    {
        
    }
    
    func verifyPincodeAPI()
    {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        let deviceToken = UserDefaults.standard.string(forKey: Key_FCM_token)
        let voipToken = UserDefaults.standard.string(forKey: "VoipToken")
        let code = tfCode.text!
        var pinCode = code
        var testUser = false
        if mobileNumber == "+18888888888" {
           // testUser = true
           pinCode =  self.testSMSCode
        } else {
            testUser = false
        }
        
        let params = ["PhoneNumber": mobileNumber ?? "",
                      "SMSCode" : pinCode,
                      "UserId" : userId ?? "",
                      "DeviceToken" : deviceToken ?? "",
                      "IsUserTesting": testUser ,
                      "VOIPDeviceToken" : voipToken ?? ""] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(verifyPincodeUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    let isUserVerified = json["IsUserVerified"].bool ?? false
                    
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
                            
                            user.userId = self.userId
                            
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
                        }
                        
                        // Get Access Token API
                        self.getAccessTokenAPI(mobileNumber : self.mobileNumber ?? "")
                    }
                }
                else
                {
                    self.errorAlert("Verification code not accepted. Please carefully check the code and submit again")
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
    
    func getAccessTokenAPI(mobileNumber : String) {
        
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
            
            switch(response.result) {
            case.success(let data):
                print("success")
                let json = JSON(data)
                let accessToken = json["access_token"].string ?? ""
                //Call Local Contacts Function
                
                UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                
                
                if self.isnewuseer == true
                {
                //AboutMeVC
                let vc = UIStoryboard().loadAboutVC()
                vc.Userid = self.userId ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    LocalContactHandler.instance.getContacts()
                    let tabBarVC = UIStoryboard().loadTabBarController()
                    appDeleg.window?.rootViewController = tabBarVC
                    appDeleg.window?.makeKeyAndVisible()
                }
           
            case.failure(let error):
                print("Not Success",error)
                self.errorAlert("\(error)")
            }
        }
    }
    
    func resendPincodeAPI()
    {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        
        let params = ["PhoneNumber": mobileNumber ?? ""] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(getSMSCodeUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                let statusCode = json["StatusCode"].string ?? ""
                let isUserRegistered = json["IsUserRegistered"].bool ?? false
                
                if isUserRegistered
                {
                    self.testSMSCode = json["SMSCode"].string ?? ""

                    let isUserVerified = json["IsUserVerified"].bool ?? false
                    
                    if isUserVerified
                    {
                        
                    }
                    else
                    {
                        self.showAlert("New pincode is resent to your numnber.")
                    }
                }
                else
                {
                    if statusCode == "409"
                    {
                        self.errorAlert("You are not a registered user, please SignUp first!")
                    }
                    else
                    {
                        if let message = json["Message"].string
                        {
                            self.errorAlert("\(message)")
                        }
                    }
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
}
