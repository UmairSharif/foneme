//
//  ChooseYourLink.swift
//  Fone
//
//  Created by Ali Raza on 05/02/2022.
//  Copyright © 2022 Fone.Me. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView
import SVProgressHUD

class ChooseYourLink : UIViewController
{
    @IBOutlet weak var textFieldFoneId: UITextField!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    
    var phoneCode : String = ""
    var phoneNumber : String = ""
    var email : String = ""
    var name : String = ""
    var lastName : String = ""
    
    var user: User?
    var accessToken: String = ""
    var idGender: Int = 0
    var idealMatchId: Int = 0
    var selectedDate: String?
    var isfromSocialLogin: Bool {
        return user != nil
    }
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func next()
    {
        if isVerifiedFields()
        {
            self.textFieldFoneId.resignFirstResponder()
            if isfromSocialLogin {
                self.updateLink()
            } else
            {
                self.registerAPI()
            }
        }
    }
    
    func isVerifiedFields() -> Bool
    {
        if textFieldFoneId.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your Fone Id!")
            return false
        }
        
        if let foneId = textFieldFoneId.text,
           !foneId.isValidFoneId {
            if (foneId.contains(" ")) {
                self.errorAlert("No blank spaces are allowed")
                return false
            }
            self.errorAlert("Please enter your valid Fone id!")
            return false
        }
        
        return true
    }
    
    @IBAction func back()
    {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ChooseYourLink : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Prevent blank space
        if string == " " {
            return false
        }
        return true
    }
}

extension ChooseYourLink
{
    func registerAPI() {
        
        
        var mobileNumber = phoneCode + phoneNumber
        if !mobileNumber.isEmpty
        {
            mobileNumber.remove(at: mobileNumber.startIndex)
        }
        
        let params = ["UserName": "",
                      "Id" : "\(Int.random(in: 1...10000))",
                      "Name": name + " " + lastName,
                      "CNIC": textFieldFoneId.text!,
                      "PhoneNumber": mobileNumber.isEmpty ? "00" : mobileNumber,
                      "Password": "",
                      "CountryCode": phoneCode.isEmpty ? "00" : phoneCode,
                      "FatherName": "iOS",
                      "Dob": selectedDate ?? "",
                      "GenderId": idGender,
                      "IdealMatchId": idealMatchId,
                      "NumberWithOutCode": phoneNumber.isEmpty ? "00" : phoneNumber,"Email" : email,
                      "RoleName" : ""] as [String: Any]
        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        if !phoneNumber.isEmpty &&  !phoneCode.isEmpty {
            firebaseAuth(phone: phoneNumber, countryCode: phoneCode) { status, error in
                if status {
                    //go to verification screen , first register and then verify
                    let number = self.phoneCode + self.phoneNumber
                    //make Firebase call
                    let vc = UIStoryboard().loadVerificationVC()
                    vc.mobileNumber = number
                    vc.isnewuseer = true
                    vc.mobileRegistrationInformaton = params
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                }else{
                    self.errorAlert("Please check your mobile number: \(error.debugDescription)")
                }
            }
        }else {
            
            SVProgressHUD.show()
            ServerCall.makeCallWitoutFile(registerUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
                if let json = response {
                    print(json)
                    SVProgressHUD.dismiss()
                    let statusCode = json["StatusCode"].string ?? ""
                    if statusCode == "200" || statusCode == "201" {
                        
                        let userId = json["UserId"].string ?? ""
                        if self.phoneNumber.isEmpty
                        {
                            self.Signup2API(user_id: userId)
                        }
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
    
    func Signup2API(user_id:String) {
        SVProgressHUD.show()
        
        //        let params = ["Name": name + " " + lastName,
        //            "CNIC": textFieldFoneId.text!,
        //                      "email": email ,
        //            "Password": "",
        //            "CountryCode": "",
        //            "FatherName": "iOS",
        //            "NumberWithOutCode": phoneNumber] as [String: Any]
        
        let params = ["email": email ] as [String: Any]
        // "CNIC": textFieldFoneId.text!,
        
        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(Signup2Url, params: params, type: Method.GET, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                SVProgressHUD.dismiss()
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201" {
                    
                    let alertController = UIAlertController(title: "Success", message: "You are successfully registered now.", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                        
                        let vc = UIStoryboard().loadVerificationVC()
                        vc.userId = user_id
                        vc.email = self.email
                        vc.isnewuseer = true
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
            
            else {
                SVProgressHUD.dismiss()
                self.errorAlert("Something went wrong. Please try again later.")
            }
        }
    }
    
    func updateLink() {
        guard let userId = user?.userId else {
            self.errorAlert("User id is missing.")
            return
        }
        
        SVProgressHUD.show()
        let params = ["Name": name + " " + lastName,
                      "Url": textFieldFoneId.text!,
                      "FirstName": name,
                      "LastName": lastName,
                      "UserId": userId,
                      "FatherName": "iOS"]
        print("parameters = \(params) \n updateSocialUrl = \(updateSocialUrl)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(updateSocialUrl, params: params, type: Method.POST, currentView: nil, header: headers) { [weak self]  (response) in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            
            if let json = response {
                print(json)
                
                let statusCode = json["StatusCode"].string ?? ""
                if statusCode == "200" || statusCode == "201" {
                    
                    if let user = self.user {
                        user.name = self.name + " " + self.lastName
                        user.url = self.textFieldFoneId.text!
                        user.address = self.textFieldFoneId.text!
                        if let userProfileData = try? PropertyListEncoder().encode(user) {
                            
                            UserDefaults.standard.set(self.accessToken, forKey: "AccessToken")
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            
                            UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                            UserDefaults.standard.synchronize()
                        }
                        let vc = UIStoryboard().loadAboutVC()
                        vc.user_id = self.user?.userId ?? ""
                        vc.user = user
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                } else {
                    if let message = json["Message"].string {
                        print(message)
                        self.errorAlert("\(message)")
                    }
                    
                    SVProgressHUD.dismiss()
                }
            } else {
                SVProgressHUD.dismiss()
                self.errorAlert("Something went wrong. Please try again later.")
            }
        }
    }
}




extension ChooseYourLink {
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
