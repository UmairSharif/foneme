//
//  PolicyVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class PolicyVC: UIViewController {

    //IBOutlet and Variables
    @IBOutlet weak var titleLbl : UILabel!
    @IBOutlet weak var policyTextView : UITextView!
    
    var vcTitle : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.titleLbl.text = vcTitle
    }
    
    @IBAction func crossBtnTapped(_ sender : UIButton)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
