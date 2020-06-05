//
//  HelpVC.swift
//  Fone
//
//  Created by Bester on 05/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class HelpVC: UIViewController {

    //IBOutlet and Variables
    @IBOutlet weak var helpTxtView : UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }
    

    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
}
