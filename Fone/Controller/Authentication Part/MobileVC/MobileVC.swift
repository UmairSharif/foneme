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

class MobileVC: UIViewController,CountryDataDelegate {
    
    //IBOutlet and Variables
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var numberTxt : UITextField!
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
    

    @IBAction func sendBtnTapped(_ sender: UIButton)
    {
        if isVerifiedFields()
        {
            // Send Mobile Number API
            self.mobileAPI()
        }
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton)
    {
//        let vc = UIStoryboard().loadSignUpVC()
//        self.navigationController?.pushViewController(vc, animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func flagBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadCountryCodeVC()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func selectedCountry(countryName: String, countryCode: String, flag: UIImage) {
        codeLbl.text = countryCode
        flagBtn.setImage(flag, for: .normal)
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func termBtnTapped (_ sender : UIButton)
    {
//        let vc = UIStoryboard().loadPolicyVC()
//        vc.vcTitle = "Term & Conditions"
//        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func policyBtnTapped (_ sender : UIButton)
    {
//        let vc = UIStoryboard().loadPolicyVC()
//        vc.vcTitle = "Privacy Policy"
//        self.present(vc, animated: true, completion: nil)
    }
    
    func isVerifiedFields() -> Bool
    {
        if (numberTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your number!")
            return false
        }
        return true
    }
}

extension MobileVC
{
    func mobileAPI()
    {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        
        let mobileNumber = codeLbl.text! + numberTxt.text!
        let params = ["PhoneNumber": mobileNumber] as [String:Any]
        
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
                    let userId = json["UserId"].string ?? ""
                    _ = json["IsUserVerified"].bool ?? false
                    
                    let vc = UIStoryboard().loadVerificationVC()
                    vc.userId = userId
                    vc.mobileNumber = mobileNumber
//                    SBUGlobals.CurrentUser = SBUUser(userId: userId, nickname: "nickname")
//                               SBUMain.connect { user, error in
//                    
//                                   if let user = user {
//                                       UserDefaults.standard.set(userId, forKey: "user_id")
//                                       UserDefaults.standard.set("nickname", forKey: "nickname")
//                                       
//                                       print("SBUMain.connect: \(user)")
//                                }
//                    }
                    self.navigationController?.pushViewController(vc, animated: true)
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
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
}
