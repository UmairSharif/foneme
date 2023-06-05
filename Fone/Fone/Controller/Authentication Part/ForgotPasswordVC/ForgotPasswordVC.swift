//
//  ForgotPasswordVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class ForgotPasswordVC: UIViewController {

    //IBOutlet and Variabes
    @IBOutlet weak var emailTxt : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }
    

    @IBAction func sendBtnTapped(_ sender : UIButton)
    {
        
    }

    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
}
