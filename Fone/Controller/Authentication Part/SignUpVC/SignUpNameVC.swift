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
    var email : String = ""
    var user: User?
    var accessToken: String = ""
    
    override func viewDidLoad() {
        loadUserInfo()
    }
    
    @IBAction func next()
    {
        if isVerifiedFields()
        {
            let vc = UIStoryboard().loadChooseYourLinkVC()
            vc.email = email
            vc.phoneNumber = phoneNumber
            vc.phoneCode = phoneCode
            vc.name = self.nameTxt.text!
            vc.lastName = self.lastNameTxt.text!
            user?.coutryCode = phoneCode
            user?.mobile = phoneNumber
            user?.email = email
            vc.user = user
            vc.accessToken = accessToken
            self.navigationController?.pushViewController(vc, animated: true)
//            let vc = UIStoryboard().loadChooseYourLinkVC()
//            vc.email = email
//            vc.phoneNumber = phoneNumber
//            vc.phoneCode = phoneCode
//            vc.name = self.nameTxt.text!
//            vc.lastName = self.lastNameTxt.text!
//            vc.user = user
//            vc.accessToken = accessToken
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func back()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func isVerifiedFields() -> Bool
    {
        if nameTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your first name!")
            return false
        }

        if lastNameTxt.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
            self.errorAlert("Please enter your last name!")
            return false
        }
        
        if nameTxt.text?.hasDigits() ?? false {
            self.errorAlert("No digits in first name please!")
            return false
        }

        if lastNameTxt.text?.hasDigits() ?? false {
            self.errorAlert("No digits in last name please!")
            return false
        }
        return true
    }
}

extension SignUpNameVC {
    
    func loadUserInfo() {
        if let user = user, let arr = user.name?.components(separatedBy: " ") {
            if arr.count > 1 {
                nameTxt.text = arr.first ?? ""
                lastNameTxt.text = arr.last ?? ""
            } else {
                nameTxt.text = user.name
            }
        }
    }
}

extension SignUpNameVC : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    // Allow up to 20 characters only
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let charsLimit = 20
        
        let startingLength = textField.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        let newLength = (startingLength + lengthToAdd - lengthToReplace)

        return newLength <= charsLimit
    }
}

