//
//  CallVC.swift
//  Fone
//
//  Created by Bester on 07/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
class CallVC: UIViewController,CountryDataDelegate,LocalContactDelegate {
    
    //IBOutlet and Variables
    @IBOutlet weak var codeLbl : UILabel!
    @IBOutlet weak var numberTxt : UITextField!
    @IBOutlet weak var flagBtn : UIButton!
    
    @IBOutlet weak var ActivityIndicatorView: NVActivityIndicatorView!
    var number : String?
    var selectedStatus : Bool?
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ActivityIndicatorView.stopAnimating()
        self.ActivityIndicatorView.isHidden = true
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
        
        if selectedStatus ?? false {
            self.numberTxt.text = number
        }
        
        getSubscriptionsForCustomer()
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
        //        self.ActivityIndicatorView.isHidden = false
        //        self.ActivityIndicatorView.startAnimating()
        //
        let   subscriptionStatus  = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
        let  daysInDiff  = UserDefaults.standard.object(forKey: SubscriptionDays) as? String ?? "0"
        let diffreance = Int(daysInDiff) ?? 0
        
        var mobilenumber = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                mobilenumber = user.mobile ?? ""
            }
        }
        
        if (numberTxt.text?.isEmpty)!
        {
            self.ActivityIndicatorView.stopAnimating()
            self.ActivityIndicatorView.isHidden = true
            self.errorAlert("Please enter your number.")
        }
        else {
            if mobilenumber == "+18888888888" {
                let number = self.codeLbl.text! + self.numberTxt.text!
                let vc = UIStoryboard().loadVoiceCallVC()
                vc.callTo = number
                self.present(vc, animated: true, completion: nil)
                return;
            }
            
            if ((subscriptionStatus.lowercased() != "active") && (diffreance <= 0)) || (subscriptionStatus.isEmpty) {
                self.openPlanListView()
                
            } else {
                
                let number = self.codeLbl.text! + self.numberTxt.text!
                let vc = UIStoryboard().loadVoiceCallVC()
                vc.callTo = number
                self.present(vc, animated: true, completion: nil)
            }
            
            
            
            /*  let fullscreenAdManager = FullScreenAdManager()
             fullscreenAdManager.createAndLoadInterstitial()
             fullscreenAdManager.onadLoaded = { [weak self] (loaded) in
             if let interstitialAd = fullscreenAdManager.interstitialAd, interstitialAd.isReady, let weakself = self {
             interstitialAd.present(fromRootViewController: weakself)
             }
             }
             fullscreenAdManager.onadDismissed = { [weak self] (loaded) in
             self?.ActivityIndicatorView.stopAnimating()
             self?.ActivityIndicatorView.isHidden = true
             if let weakself = self {
             let number = weakself.codeLbl.text! + weakself.numberTxt.text!
             let vc = UIStoryboard().loadVoiceCallVC()
             vc.callTo = number
             weakself.present(vc, animated: true, completion: nil)
             }
             }*/
        }
    }
    
    @IBAction func contactsBtnTapped(_ sender : UIButton)
    {
        let vc = UIStoryboard().loadLocalContactVC()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func getSubscriptionsForCustomer(){
        
        var mobilenumber = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                mobilenumber = user.mobile ?? ""
            }
        }
        if mobilenumber == "+18888888888" {
            return;
        }
        // mobilenumber = "9199876543"
        let header  = ["Content-Type": "application/json"]
        // APIManager.sharedManager.request(getBrainTreePlans, method: Alamofire.HTTPMethod.post, parameters: nil, encoding:  JSONEncoding.default,
        let apiURL = "\(getSubscriptions_Customer)\(mobilenumber)"
        
        ServerCall.makeCallWitoutFile(apiURL, params: nil, type: Method.POST, currentView: nil, header: header) { (response) in
            let isAvilabel = response?["response"] ?? false
            print(isAvilabel)
            print(response)
            if isAvilabel == true {
                let subscriptionArr = response?["subscriptions"].arrayObject
                let subscritpionobject = subscriptionArr?.last as? [String:Any]
                let subDateobject = subscritpionobject?["lastdate"] as? [String:Any]
                let dateExpiry = subDateobject?["date"] as? String ?? ""
                print("dateExpiry = \(dateExpiry)")
                let dateObj = Utility.sharedInstance.getDateFromString(dateExpiry, "yyyy-MM-dd HH:mm:ss") ?? Date()
                let diffreance = Utility.sharedInstance.diffranceBetweenDays(formatedStartDate: dateObj)
                print("diffreance = \(diffreance)")
                
                let subscriptionStatus = subscritpionobject?[SubscriptionStatus] as? String  ?? ""
                let subscriptionId = subscritpionobject?[SubscriptionId] as? String  ?? ""
                let subscriptionPlan = subscritpionobject?[SubscriptionPlan] as? String
                UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)
                UserDefaults.standard.set(subscriptionPlan, forKey: SubscriptionPlan)
                UserDefaults.standard.set(subscriptionId, forKey: SubscriptionId)
                UserDefaults.standard.set("\(diffreance)", forKey: SubscriptionDays)
                
                if (subscriptionStatus.lowercased() != "active") && (diffreance < 0) {
                    //self.openPlanListView()
                }
                
            }else {
                UserDefaults.standard.set("", forKey: SubscriptionStatus)
                UserDefaults.standard.set("", forKey: SubscriptionPlan)
                UserDefaults.standard.set("0", forKey: SubscriptionDays)
                
                // self.openPlanListView()
            }
            
            
        }
        
    }
    
    func openPlanListView() {
        let desiredVC = UIStoryboard().loadPlanVC()
        desiredVC.modalPresentationStyle = .fullScreen
        topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
        
    }
    
}
