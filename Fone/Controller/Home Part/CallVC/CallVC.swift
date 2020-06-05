//
//  CallVC.swift
//  Fone
//
//  Created by Bester on 07/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class CallVC: UIViewController,CountryDataDelegate,LocalContactDelegate {
    
    //IBOutlet and Variables
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var numberTxt : UITextField!
    @IBOutlet weak var flagBtn : UIButton!
    var number : String?
    var selectedStatus : Bool?
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if selectedStatus ?? false
        {
            self.numberTxt.text = number
        }
    }
    

    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func sendNumber(number: String?) {
        
        self.numberTxt.text = number
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
    
    @IBAction func callBtnTapped(_ sender : UIButton)
    {
        if (numberTxt.text?.isEmpty)!
        {
            self.errorAlert("Please enter your number.")
        }
        else
        {
            let number = codeLbl.text! + numberTxt.text!
            let vc = UIStoryboard().loadVoiceCallVC()
            vc.callTo = number
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func contactsBtnTapped(_ sender : UIButton)
    {
        let vc = UIStoryboard().loadLocalContactVC()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
