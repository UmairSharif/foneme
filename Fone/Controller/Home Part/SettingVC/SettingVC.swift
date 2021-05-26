//
//  SettingVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SendBirdSDK

class SettingVC: UIViewController {

    @IBOutlet weak var professionLabel: UILabel!
    //IBOutlet and Variables
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var statusLbl : UILabel!
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    
    @IBOutlet weak var lblAboutme: UILabel!
    
    @IBOutlet weak var subscriptionLbl : UILabel!
    @IBOutlet weak var subscriptionView : UIView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        userImage.layer.cornerRadius = userImage.frame.size.height / 2
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        
        
        if let  about = UserDefaults.standard.value(forKey: "about") as? String{
            lblAboutme.text = about
        }else{
            print("")
        }
        DispatchQueue.main.async {
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    self.nameLbl.text = user.name
//                    self.professionLabel.text = user.name
//                    self.lblAboutme.text = user.aboutme
                    
                    
                    self.getUserDetail(cnic: user.address ?? "", friend: "") { (userModel, success) in
                        if success {
                            debugPrint("USER",userModel?.aboutme)
                            self.lblAboutme.text = userModel?.aboutme
                        
                            UserDefaults.standard.setValue(userModel?.aboutme, forKey: "about")
                            UserDefaults.standard.setValue(userModel?.profession, forKey: "profession")
                         
                            

                            UserDefaults.standard.synchronize()
                            let profession =   UserDefaults.standard.value(forKey: "profession") as? String
                            self.professionLabel.text = profession ?? ""
                        }
                    }
                    
                    debugPrint("Aboutme",user.aboutme)
                    
                    if let url = URL(string: user.userImage ?? "") {
                        self.downloadImage(from: url)
                    }
                    if let _ = user.userImage{
                        SBDMain.updateCurrentUserInfo(withNickname: user.name, profileUrl: user.userImage) { (error) in
                            print(error ?? "not an error")
                        }
                    }
                }
            }
        }
        
        
    let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
     let   subscriptionPlan  = UserDefaults.standard.object(forKey: SubscriptionPlan) as? String ?? ""

       if subscription.lowercased() == "active" {
        subscriptionView.isHidden = false
        subscriptionLbl.text = "Unsubscribe for Fone-Out"
       //    subscriptionLbl.text = "Unsubscribe for plan \(subscriptionPlan)"
       } else {
        subscriptionView.isHidden = true
        
        }
    }
    @IBAction func btnAboutme(_ sender: Any) {
        
        
        let vc = UIStoryboard().loadaboutProfileVC()
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
//                userId = user.userId
                vc.Userid = user.userId ?? ""
            }
        }
       
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func profileBtnTapped(_ sender:UIButton)
    {
        let vc = UIStoryboard().loadEditProfileVC()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            
            DispatchQueue.main.async() {
                self.userImage.image = UIImage(data: data)
            }
        }
    }

    @IBAction func chatBtnTapped(_ sender:UIButton)
    {
        
    }
    
    @IBAction func notificationBtnTapped(_ sender:UIButton)
    {
        
    }
    
    @IBAction func helpBtnTapped(_ sender:UIButton)
    {
        let vc = UIStoryboard().loadHelpVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func shareBtnTapped(_ sender:UIButton)
    {
        //Set the default sharing message.
        let message = "Fone App"
        //Set the link to share.
        if let link = NSURL(string: "")
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func contactBtnTapped(_ sender:UIButton)
    {
        let email = "hello@fone.me"
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
        }
//        let vc = UIStoryboard().loadContactVC()
//        vc.hidesBottomBarWhenPushed = true
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func subscriptionBtnTapped(_ sender:UIButton){
        
        
        let alertController = UIAlertController(title: "Alert", message: "Are you sure you want to cancel this subscription?", preferredStyle: .alert)
             
             let action1 = UIAlertAction(title: "YES", style: .default) { (action:UIAlertAction) in
                 
                 //Call Logout API
                 self.cancelSubscription()
                 
             }
             let action2 = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
                 
             }
             
             alertController.addAction(action1)
             alertController.addAction(action2)
             self.present(alertController, animated: true, completion: nil)
    }
    
    func cancelSubscription(){
        
    
       let subscriptionId  = UserDefaults.standard.object(forKey: SubscriptionId) as? String ?? ""

    
    let paymentURL = URL(string: "\(cancelSubscription_Customer)\(subscriptionId)")!
    var request = URLRequest(url: paymentURL)
    request.httpBody = "".data(using: String.Encoding.utf8)
    
    request.httpMethod = "POST"
    
    URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
        guard let data = data else {
           // self?.show(message: error!.localizedDescription)
            print("error = \(error!.localizedDescription)")
            return
        }
        let str = String(decoding: data, as: UTF8.self)
        print("str = \(str)")
        let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let subscription = result?["result"] as? String ?? ""
        if subscription.isEmpty {
            let errormes = result?["errormessage"] as? String ?? "Subscription has already been canceled."
            self?.showSuccessMessage(message: errormes)
            DispatchQueue.main.async {
                      self?.subscriptionView.isHidden = true
                      }
        } else {
            let msg = result?["msg"] as? String ?? "Subscription cancelled succsessfully."
            self?.showSuccessMessage(message: msg)
            DispatchQueue.main.async {
            self?.subscriptionView.isHidden = true
            }

        }


       print("result = \(result)")

    }.resume()
}
    
    func showSuccessMessage(message:String){
           DispatchQueue.main.async {

           let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                  let actionCancel = UIAlertAction(title: "Ok", style: .cancel) { (action) in
                   self.dismiss(animated: true, completion: nil);
                  }
                  alert.addAction(actionCancel)
               self.present(alert, animated: true, completion: nil)
           }
       }

    @IBAction func logoutBtnTapped(_ sender:UIButton)
    {
        let alertController = UIAlertController(title: "Alert", message: "Do you want to SignOut?", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            
            //Call Logout API
            self.logoutAPI()
            
        }
        let action2 = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
            
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func logoutAPI() {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        var userId : String?
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = [ "UserId" : userId ?? ""
            ] as [String:Any]
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(logoutUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                
                print(json)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: key_User_Profile)
                UserDefaults.standard.synchronize()
                
                let vc = UIStoryboard().loadLoginNavVC()
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
                
            }
        }
    }
}
