//
//  SignUpNameVC.swift
//  Fone
//
//  Created by Ali Raza on 05/02/2022.
//  Copyright © 2022 Fone.Me. All rights reserved.
//

import Foundation
import UIKit

class SignUpNameVC : UIViewController
{
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var lastNameTxt: UITextField!
    
    var phoneCode : String = ""
    var phoneNumber : String = ""
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func next()
    {
        if isVerifiedFields()
        {
            let vc = UIStoryboard().loadChooseYourLinkVC()
            vc.phoneCode = phoneCode
            vc.phoneNumber = phoneNumber
            vc.name = self.nameTxt.text!
            vc.lastName = self.lastNameTxt.text!
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func back()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func isVerifiedFields() -> Bool
    {
        if nameTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your name!")
            return false
        }

        if lastNameTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your last name!")
            return false
        }
        
        if nameTxt.text?.hasDigits() ?? false {
            self.errorAlert("No digits in name please!")
            return false
        }

        if lastNameTxt.text?.hasDigits() ?? false {
            self.errorAlert("No digits in last name please!")
            return false
        }
        return true
    }
}

extension SignUpNameVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
