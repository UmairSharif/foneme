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


class SignUpVC: UIViewController,CountryDataDelegate {

    //IBOutlet and Variables
    @IBOutlet weak var nameTxt : UITextField!
    @IBOutlet weak var emailTxt : UITextField!
    @IBOutlet weak var phoneTxt : UITextField!
    @IBOutlet weak var passwordTxt : UITextField!
    @IBOutlet weak var textFieldFoneId : UITextField!
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var flagBtn : UIButton!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
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
    
    @IBAction func onPrivacyPolicyTapped(_ sender: UIButton) {
        let safariVC = SFSafariViewController(url: URL(string: "https://www.fone.me/privacy")!)
        present(safariVC, animated: true, completion: nil)
    }
    
    @IBAction func saveBtnTapped(_ sender: UIButton)
    {
        if isVerifiedFields()
        {
            // Registeration API Call
            self.registerAPI()
        }
    }
    
    @IBAction func loginBtnTapped(_ sender: UIButton)
    {
        //self.navigationController?.popViewController(animated: true)
        let vc = UIStoryboard().loadMobileVC()
        self.navigationController?.pushViewController(vc, animated: true)
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
        else if (textFieldFoneId.text?.isEmpty)!
        {
            self.errorAlert("Please enter your Fone Id!")
            return false
        }

        else if (phoneTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your phone number!")
            return false
        }
        return true
    }
}

extension SignUpVC
{
     func registerAPI()
     {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        
        var mobileNumber = codeLbl.text! + phoneTxt.text!
        mobileNumber.remove(at: mobileNumber.startIndex)
        let params = ["Name": nameTxt.text!,
                      "Email": emailTxt.text!,
                      "CNIC": textFieldFoneId.text!,
                      "PhoneNumber": mobileNumber,
                      "Password": "",
                      "CountryCode": codeLbl.text!,
                      "FatherName": "iOS",
                      "NumberWithOutCode": phoneTxt.text!] as [String:Any]
        // "CNIC": textFieldFoneId.text!,

        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(registerUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"
                {
                    
                    let userId = json["UserId"].string ?? ""
                    let number = self.codeLbl.text! + self.phoneTxt.text!
                    
                    let alertController = UIAlertController(title: "Success", message: "You are successfully registered now.", preferredStyle: .alert)
                    
                    let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                        
                        let vc = UIStoryboard().loadVerificationVC()
                        vc.userId = userId
                        vc.mobileNumber = number
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
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
     }
    
    func createUserInBrainTree(){
        
        let header  = ["Content-Type": "application/json"]
        APIManager.sharedManager.request(endCallUrl, method: Alamofire.HTTPMethod.post, parameters: nil, encoding:  JSONEncoding.default, headers: header)
                   .responseString {response in
                      // print(response.result,response.response as Any,response)
                       let url = response.description
                      print(url)
                      
                      print(header)
                   }
                   .responseJSON { response in
                       switch response.result {
                       case .success: break
                       case .failure(let error):
                           print("Error in API: \(error.localizedDescription)")
                       }
               }
        
    }
}
