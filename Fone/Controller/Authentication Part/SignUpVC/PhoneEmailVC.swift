//
//  PhoneEmailVC.swift
//  Fone
//
//  Created by varun on 16/03/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import SafariServices
import SVProgressHUD


class PhoneEmailVC: UIViewController {

    var from_sign_up = false
    @IBOutlet var phone_view : UIView!
    @IBOutlet var email_view : UIView!
    @IBOutlet var phone_placeholder_lbl : UILabel!
    @IBOutlet var email_placeholder_lbl : UILabel!
    @IBOutlet var sign_up_in_placeholder : UILabel!
    @IBOutlet var phone_line_lbl : UILabel!
    @IBOutlet var email_line_lbl : UILabel!
    @IBOutlet var codeLbl: UILabel!
    @IBOutlet var flagImg: UIImageView!
    @IBOutlet var phone_txt: UITextField!
    @IBOutlet var email_txt: UITextField!
    @IBOutlet var account_btn: UIButton!
    @IBOutlet var termstxt: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phone_view.isHidden = false
        email_view.isHidden = true
        codeLbl.adjustsFontSizeToFitWidth = true
        
        if from_sign_up
        {
            let attributedString = TextStyling.applyAttributedTextStyle(firstString: "Already have an account?", secondString: " Login")
            account_btn.setAttributedTitle(attributedString, for: .normal)
            sign_up_in_placeholder.text = "Sign up"
            termstxt.isHidden = false
            termstxt.textContainer.lineFragmentPadding  = 0.0
            termstxt.textContainerInset = .zero
            
            setterms()
        }
        else
        {
            termstxt.isHidden = true
            let attributedString = TextStyling.applyAttributedTextStyle(firstString: "Don't have an account?", secondString: " Sign up")
            account_btn.setAttributedTitle(attributedString, for: .normal)
            sign_up_in_placeholder.text = "Sign in"
        }
        
        phone_txt.delegate = self
    }
    
    func setterms()
    {
     
        let attributedString = TextStyling.applyAttributedTextStyle(firstString: "By continuing, you agree to FoneMe's", secondString: " Terms of Service and Privacy Policy")
        termstxt.attributedText = attributedString
    }
    
@IBAction func phone_action()
    {
        phone_placeholder_lbl.textColor = UIColor.black
        email_placeholder_lbl.textColor = UIColor.lightGray
        phone_line_lbl.backgroundColor = UIColor.black
        email_line_lbl.backgroundColor = UIColor.lightGray
        
        phone_view.isHidden = false
        email_view.isHidden = true
        email_txt.resignFirstResponder()
        
        email_txt.text = ""
    }
    @IBAction func email_action()
        {
            phone_placeholder_lbl.textColor = UIColor.lightGray
            email_placeholder_lbl.textColor = UIColor.black
            phone_line_lbl.backgroundColor = UIColor.lightGray
            email_line_lbl.backgroundColor = UIColor.black
            phone_view.isHidden = true
            email_view.isHidden = false
            
            phone_txt.resignFirstResponder()
            
            phone_txt.text = ""
        }
    @IBAction func country_action()
    {
        let vc = UIStoryboard().loadCountryCodeVC()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    @IBAction func next_action()
    {
        if isVerifiedFields()
        {
            if from_sign_up
            {
                signup_flow()
            }
            else
            {
                login_flow()
            }
        }
    }
    
    func signup_flow()
    {
        
        if !phone_view.isHidden
        {
//            var mobileNumber = codeLbl.text! + self.phone_txt.text!
//            if !mobileNumber.isEmpty
//            {
//                mobileNumber.remove(at: mobileNumber.startIndex)
//            }
//            SVProgressHUD.show()
//            var headers = [String:String]()
//            headers = ["AuthKey": "#phone@me!Us+O0"]
//            headers = ["Content-Type": "application/json"]
//            ServerCall.makeCallWitoutFile(checkCICN  + "/\(mobileNumber)", params: [:], type: Method.GET, currentView: nil, header: headers) { (response) in
//
//                if let json = response, !(json.rawString() == "null") {
//                    print(json)
//                    SVProgressHUD.dismiss()
//                    self.errorAlert("Account has been registered. Please log in")
//                } else {
//                    SVProgressHUD.dismiss()
//                    let vc = UIStoryboard().loadSingUpNameVC()
//                    vc.phoneCode = self.codeLbl.text!
//                    vc.phoneNumber = self.phone_txt.text!
//                    self.navigationController?.pushViewController(vc, animated: true)
//
//                }
//            }
            
            //Note: make firebase api call here only and validate that number is correct or not!
            let vc = UIStoryboard().loadSingUpNameVC()
            vc.phoneCode = self.codeLbl.text!
            vc.phoneNumber = self.phone_txt.text!
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else
        {
            existinguserAPI()
        }
    }
    
    
    
    func login_flow()
    {
        if !phone_view.isHidden
        {
            mobileAPI()
        }
        else
        {
            existinguserAPI()
        }
    }
    @IBAction func account_action()
    {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onPrivacyPolicyTapped(_ sender: UITapGestureRecognizer) {
        let tapped = taptext(tap: sender, text: " Terms of Service and Privacy Policy")
        if tapped.isSelected
        {
         let safariVC = SFSafariViewController(url: URL(string: "https://www.fone.me/privacy")!)
         present(safariVC, animated: true, completion: nil)
        }
    }
    
    func taptext(tap:UITapGestureRecognizer,text:String) -> (isSelected:Bool,characterIndex:Int)
    {
        let textView = tap.view as! UITextView
        textView.selectedRange = NSRange(location: 0, length: 0)
        let nsstring = textView.text as NSString
        let tapLocation = tap.location(in: textView)
        let characterIndex = textView.layoutManager.characterIndex(for: tapLocation, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let range = nsstring.range(of: text,options: NSString.CompareOptions.init(rawValue: 0),range: NSRange(location: 0, length: nsstring.length))

        if range.location != NSNotFound
        {
           return (true , characterIndex)
        }
        return (false,characterIndex)
    }
    
    
    func isVerifiedFields() -> Bool
    {
        if !phone_view.isHidden
        {
            if phone_txt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
                self.errorAlert("Please enter your phone number!")
                return false
            }
            
            guard let phoneNumber = phone_txt.text, (phoneNumber.count >= 6 && phoneNumber.count <= 10) else {
                self.errorAlert("Please enter valid phone number!")
                return false
            }
        }
        else
        {
            let email = (email_txt.text ?? "").trim
            if   !email.isValidEmail()
            {
                self.errorAlert("Please enter valid email")
                return false
            }
        }
        return true
    }
}
extension PhoneEmailVC {
  
    func existinguserAPI() {
      SVProgressHUD.show()
      
      let params = ["Cnic": email_txt.text ?? ""] as [String:Any]
      
      print("params: \(params)")
      var headers = [String:String]()
      headers = ["Content-Type": "application/json"]
      
      ServerCall.makeCallWitoutFile(getuserdetail, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
        
        if let json = response {
          print(json["UserProfileData"]["UserId"])
          SVProgressHUD.dismiss()
          
          let statusCode = json["StatusCode"].string ?? ""
          let isUserRegistered = json["IsUserRegistered"].bool ?? false
          
          if statusCode == "200" {
            let userId = json["UserProfileData"]["UserId"].string ?? ""
            _ = json["IsUserVerified"].bool ?? false
            
              if self.from_sign_up
              {
                  self.errorAlert("Email Already exist, please SignIn")
              }
              else
              {
                  self.Signup2API(user_id: userId)
              }
           
          }
          else {
            if statusCode == "409" {
                if self.from_sign_up
                {
                    let vc = UIStoryboard().loadSingUpNameVC()
                    vc.email = self.email_txt.text!
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                else
                {
                    self.errorAlert("You are not a registered user, please SignUp first!")
                }
              
            } else {
              if let message = json["Message"].string
              {
                self.errorAlert("\(message)")
              }
            }
            if statusCode == "410"
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
            
            SVProgressHUD.dismiss()
          }
        }
      }
    }
    
    func Signup2API(user_id:String) {
        SVProgressHUD.show()

        let params = ["email": email_txt.text!] as [String: Any]
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
                    
                    let vc = UIStoryboard().loadVerificationVC()
                    vc.userId = user_id
                    vc.testSMSCode = json["Code"].string ?? ""
                    vc.isfromsignup =  true  //self.isfromsignup
                    vc.email = self.email_txt.text ?? ""
                    self.navigationController?.pushViewController(vc, animated: true)
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
    
  func mobileAPI() {
    SVProgressHUD.show()
    
    let mobileNumber = codeLbl.text! + phone_txt.text!
//      firebaseAuth(phone: phone_txt.text!, countryCode: codeLbl.text!) { status, error in
//          SVProgressHUD.dismiss()
//          if status {
//              let vc = UIStoryboard().loadVerificationVC()
//              vc.mobileNumber = mobileNumber
//              vc.isnewuseer = false
//              self.navigationController?.pushViewController(vc, animated: true)
//          } else {
//              self.errorAlert("You are not a registered user, please SignUp first!")
//          }
//      }
      
      
      let params = ["PhoneNumber": mobileNumber] as [String:Any]
      
      print("params: \(params)")
      var headers = [String:String]()
      headers = ["Content-Type": "application/json"]
      
      if !(phone_txt.text?.isEmpty ?? true){
          firebaseAuth(phone: phone_txt.text!, countryCode: codeLbl.text!) { status, error in
              if status {
                  //go to verification screen , first register and then verify
                  let number = self.codeLbl.text! + self.phone_txt.text!
                  //make Firebase call
                  let vc = UIStoryboard().loadVerificationVC()
                  vc.mobileNumber = number
                  vc.isnewuseer = false
                  vc.mobileRegistrationInformaton = params
                  self.navigationController?.pushViewController(vc, animated: true)
              
              }else{
                  self.errorAlert("Please check your mobile number: \(error.debugDescription)")
              }
              SVProgressHUD.dismiss()
          }
      }
      
      
      
      
      
  }
}
extension PhoneEmailVC : CountryDataDelegate
{
    func selectedCountry(countryName: String, countryCode: String, flag: UIImage) {
        codeLbl.text = countryCode
        flagImg.image = flag
    }
    
    
}
class CustomUITextView: UITextView {
   override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
   }
}
extension PhoneEmailVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phone_txt
        {
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
        return true
    }
    
}
extension PhoneEmailVC {
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
