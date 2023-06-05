//
//  MobileVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import CountryPickerView
import NVActivityIndicatorView
import SVProgressHUD
import Alamofire
import SwiftyJSON
import SendBirdSDK

class MobileVC: UIViewController,CountryDataDelegate {
  
  //IBOutlet and Variables
  @IBOutlet weak var codeLbl : UILabel!
  @IBOutlet weak var numberTxt : UITextField!
  @IBOutlet weak var flagBtn : UIImageView!
  @IBOutlet weak var signupBtn: UIButton!
  @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
  
  let network = NetworkManager.sharedInstance
  var netStatus : Bool?
  var isfromsignup = false
  var user: User?
  var isNewUser: Bool {
      if let url = user?.url, !url.isEmpty {
          return false
      }
      return true
  }
  
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
    
    print(UIDevice.current.identifierForVendor!.uuidString)
    
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
  
  private func setupDelegates() {
    numberTxt.delegate = self
  }
  
  private func setupAttributedTexts() {
    let attributedString = TextStyling.applyAttributedTextStyle(firstString: "Don't have an account", secondString: " SignUp?")
    signupBtn.setAttributedTitle(attributedString, for: .normal)
  }
  
  func selectedCountry(countryName: String, countryCode: String, flag: UIImage) {
    codeLbl.text = countryCode
    flagBtn.image = flag
  }
  
  func isVerifiedFields() -> Bool
  {
    if (numberTxt.text?.isEmpty)!
    {
      self.errorAlert("Please enter your number!")
      return false
    }
    
    guard let phoneNumber = numberTxt.text, (phoneNumber.count >= 6 && phoneNumber.count <= 10) else {
      self.errorAlert("Please enter valid phone number!")
      return false
    }
    
    return true
  }
}

// MARK: - IBActions

extension MobileVC {
  
  @IBAction func googleBtnTapped(_ sender: UIButton) {
    self.socialLogin(with: .google)
  }
  
  @IBAction func appleBtnTapped(_ sender: UIButton) {
    self.socialLogin(with: .apple)
  }
  
  @IBAction func facebookBtnTapped(_ sender: UIButton) {
    self.socialLogin(with: .facebook)
  }
  
  @IBAction func backBtnTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func termBtnTapped (_ sender: UIButton) {
    //let vc = UIStoryboard().loadPolicyVC()
    //vc.vcTitle = "Term & Conditions"
    //self.present(vc, animated: true, completion: nil)
  }
  
  @IBAction func policyBtnTapped (_ sender: UIButton) {
    // let vc = UIStoryboard().loadPolicyVC()
    // vc.vcTitle = "Privacy Policy"
    // self.present(vc, animated: true, completion: nil)
  }
  
  @IBAction func sendBtnTapped(_ sender: UIButton) {
    if isVerifiedFields() {
      // Send Mobile Number API
      self.mobileAPI()
    }
  }
  
  @IBAction func signUpBtnTapped(_ sender: UIButton) {
    if isfromsignup == false {
      let vc = UIStoryboard().loadSignUpVC()
      self.navigationController?.pushViewController(vc, animated: true)
    } else {
      self.navigationController?.popViewController(animated: true)}
  }
  
  @IBAction func flagBtnTapped(_ sender: UIButton) {
    let vc = UIStoryboard().loadCountryCodeVC()
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }
}

// MARK: - Social Login

extension MobileVC {
  
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
  
// MARK: - API Methods

extension MobileVC {
  
  func mobileAPI() {
    SVProgressHUD.show()
    
    let mobileNumber = codeLbl.text! + numberTxt.text!
      firebaseAuth(phone: numberTxt.text!, countryCode: codeLbl.text!) { status, err in
          if status {
              let vc = UIStoryboard().loadVerificationVC()
              vc.isfromsignup =  true  //self.isfromsignup
              vc.mobileNumber = mobileNumber
              self.navigationController?.pushViewController(vc, animated: true)
          } else {
              self.errorAlert("You are not a registered user, please SignUp first!")
          }
          
      }
  }
}

// Allow up to 10 digits only
extension MobileVC: UITextFieldDelegate {
  
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

extension MobileVC {
    
    private func loginWithSocial(_ account: SocialLoginUser, FromProvider provider: SocialLoginManager.Provider) {
        SVProgressHUD.show()
        let params = ["SocialId": account.id ?? "",
                      "SocialType" : provider.name,
                      "Email" : account.email ?? "",
                      "Name" : account.name ?? "",
                      "ProfileImg": account.profileImageURL ?? "",
                      "FirstName" : account.firstName ?? "",
                      "LastName" : account.lastName ?? "",
                      "AuthToken" : account.authToken ?? ""] as [String:Any]
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
                            self.user = user
                            if self.isNewUser {
                               self.errorAlert("This account does not exist. Please sign up first to continue.")
                                return
                            }
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
                        self.getAccessTokenAPI(socialId: account.id)
                    }
                }
                else
                {
                    self.errorAlert("Verification code not accepted. Please carefully check the code and submit again")
                }
            }
        }
    }
    
    func getAccessTokenAPI(socialId : String) {
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
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            switch(response.result) {
            case.success(let data):
                print("success")
                let json = JSON(data)
                let accessToken = json["access_token"].string ?? ""
                //Call Local Contacts Function
                if self.isNewUser {
//                    let vc = UIStoryboard().loadSingUpNameVC()
//                    vc.user = self.user
//                    vc.accessToken = accessToken
//                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.synchronize()
                    
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
}

extension MobileVC {
    //MARK: Mobile Number  Verification Code through Firebase
    func firebaseAuth(phone:String,countryCode:String,completion: @escaping ((Bool,Error?) -> Void) ){
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
