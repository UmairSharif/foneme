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

class ChooseYourLink : UIViewController
{
    @IBOutlet weak var textFieldFoneId: UITextField!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    
    var phoneCode : String = ""
    var phoneNumber : String = ""
    var name : String = ""
    var lastName : String = ""
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func next()
    {
        if isVerifiedFields()
        {
            self.textFieldFoneId.resignFirstResponder()
            self.registerAPI()
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
            self.errorAlert("Please enter your a valid Fone Id!")
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
}

extension ChooseYourLink
{
    func registerAPI() {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false

        var mobileNumber = phoneCode + phoneNumber
        mobileNumber.remove(at: mobileNumber.startIndex)
        let params = ["Name": name + " " + lastName,
            "CNIC": textFieldFoneId.text!,
            "PhoneNumber": mobileNumber,
            "Password": "",
            "CountryCode": phoneCode,
            "FatherName": "iOS",
            "NumberWithOutCode": phoneNumber] as [String: Any]
        // "CNIC": textFieldFoneId.text!,

        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(registerUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in

            if let json = response {
                print(json)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true

                let statusCode = json["StatusCode"].string ?? ""

                if statusCode == "200" || statusCode == "201" {

                    let userId = json["UserId"].string ?? ""
                    let number = self.phoneCode + self.phoneNumber

                    let alertController = UIAlertController(title: "Success", message: "You are successfully registered now.", preferredStyle: .alert)

                    let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in

                        let vc = UIStoryboard().loadVerificationVC()
                        vc.userId = userId
                        vc.mobileNumber = number
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

                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
}


