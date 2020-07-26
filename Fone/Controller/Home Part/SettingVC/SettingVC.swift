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

    //IBOutlet and Variables
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var statusLbl : UILabel!
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    
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
        
        DispatchQueue.main.async {
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                print(userProfileData)
                if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                    self.nameLbl.text = user.name
                    
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
    
    
    func logoutAPI()
    {
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
