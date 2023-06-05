//
//  LoginVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {

    //IBOutlet and Variables
    @IBOutlet weak var emailTxt : UITextField!
    @IBOutlet weak var passwordTxt : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
       
        
    }
  

    @IBAction func loginBtnTapped(_ sender: UIButton)
    {
        //self.performSegue(withIdentifier: "GoToHome", sender: self)
    }
    
    @IBAction func mobileBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadMobileVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func signUpBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadSignUpVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func forogtPassBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadForgotPasswordVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
