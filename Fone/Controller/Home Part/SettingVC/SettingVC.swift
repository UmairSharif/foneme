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
import SVProgressHUD

class SettingVC: UIViewController {

    @IBOutlet weak var professionLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    //IBOutlet and Variables
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!

    @IBOutlet weak var lblAboutme: UILabel!

    @IBOutlet weak var subscriptionLbl: UILabel!
    @IBOutlet weak var subscriptionView: UIView!
    var user_Id:String?

    private var userModel: UserDetailModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        userImage.layer.cornerRadius = userImage.frame.size.height / 2
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
        self.professionLabel.text = ""
        self.lblAboutme.text = ""
        
        if let child = self.view.viewWithTag(101)
        {
            child.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
            child.layer.borderWidth = 1.0
            child.layer.cornerRadius = 12.0
        }
        
        if let child = self.view.viewWithTag(102)
        {
            child.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
            child.layer.borderWidth = 1.0
            child.layer.cornerRadius = 12.0
        }
        
        if let child = self.view.viewWithTag(103)
        {
            child.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
            child.layer.borderWidth = 1.0
            child.layer.cornerRadius = 12.0
        }
        
        if let child = self.view.viewWithTag(104)
        {
            child.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
            child.layer.borderWidth = 1.0
            child.layer.cornerRadius = 12.0
        }
        
        if let child = self.lblAboutme.superview
        {
            child.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
            child.layer.borderWidth = 1.0
            child.layer.cornerRadius = 12.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if let about = UserDefaults.standard.value(forKey: "about") as? String {
            lblAboutme.text = about
        }
        
        self.setCacheData { [weak self] in
            guard let self = self else { return }
            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
               let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                self.lblAboutme.text = user.name
                self.bindData(user: user)
                if let url = URL(string: user.userImage ?? "") {
                  self.downloadImage(from: url)
                }
            }
        }
        
        let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
        ///let subscriptionPlan = UserDefaults.standard.object(forKey: SubscriptionPlan) as? String ?? ""
        
        if subscription.lowercased() == "active" {
            subscriptionView.isHidden = false
            subscriptionLbl.text = "Unsubscribe for Fone-Out"
            //    subscriptionLbl.text = "Unsubscribe for plan \(subscriptionPlan)"
        } else {
            subscriptionView.isHidden = true
            
        }
    }
    
    func bindData(user: User) {
        SVProgressHUD.show()
        self.nameLbl.text = user.name
        self.professionLabel.text = user.profession
        self.lblAboutme.text = user.aboutme
        self.linkLabel.text = ""
        
        self.lblAboutme.text =  UserDefaults.standard.value(forKey: "about") as? String ?? ""
        self.professionLabel.text =  UserDefaults.standard.value(forKey: "profession") as? String ?? ""
        
        self.getUserDetail(cnic: user.address ?? user.userId ?? "", friend: "") { (userModel, success) in
            SVProgressHUD.dismiss()
            if success {
                self.userModel = userModel
                if let url = URL(string: userModel?.imageUrl ?? "") {
                  self.downloadImage(from: url)
                }
                self.user_Id = userModel?.userId
                self.professionLabel.text = userModel?.profession
                self.lblAboutme.text = userModel?.aboutme
                self.linkLabel.text = userModel?.location
                UserDefaults.standard.setValue(userModel?.aboutme, forKey: "about")
                UserDefaults.standard.setValue(userModel?.profession, forKey: "profession")
                UserDefaults.standard.synchronize()
                let profession = UserDefaults.standard.value(forKey: "profession") as? String
                self.professionLabel.text = profession ?? ""
                
                self.checkOpenSocialLinksIfNeeded()
            } else {
                self.showAlert("Error"," Can't get user information. Please try again.")
            }
        }
        
//        if let url = URL(string: user.userImage ?? "") {
//          self.downloadImage(from: url)
//        }
        
        if let _ = user.userImage {
          SBDMain.updateCurrentUserInfo(withNickname: user.name, profileUrl: user.userImage) { (error) in
            print(error ?? "not an error")
          }
        }
    }
    
    @IBAction func btnAboutme(_ sender: Any) {
        let vc = UIStoryboard().loadaboutProfileVC()
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
//                userId = user.userId
                vc.Userid = self.user_Id ?? ""
            }
        }

        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)

    }

    @IBAction func profileBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadEditProfileVC()
        vc.userId = self.user_Id ?? ""
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func downloadImage(from url: URL) {

        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }

            guard let response  = response as? HTTPURLResponse, response.statusCode != 403 else {
                return
            }
            DispatchQueue.main.async() {
                self.userImage.image = UIImage(data: data)
            }
        }
    }

    private func checkOpenSocialLinksIfNeeded() {
        if !UserDefaults.standard.bool(forKey: KEY_OPEN_PROFILE_SOCIAL_LINKS) {
            openSocialLinks()
            UserDefaults.standard.setValue(true, forKey: KEY_OPEN_PROFILE_SOCIAL_LINKS)
            UserDefaults.standard.synchronize()
        }
    }

    @IBAction func chatBtnTapped(_ sender: UIButton)
    {

    }

    @IBAction func notificationBtnTapped(_ sender: UIButton)
    {
    }

    @IBAction func helpBtnTapped(_ sender: UIButton)
    {
        let vc = UIStoryboard().loadHelpVC()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func shareBtnTapped(_ sender: UIButton)
    {
        //Set the default sharing message.
        let message = "Fone App"
        //Set the link to share.
        if let link = NSURL(string: "")
        {
            let objectsToShare = [message, link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    @IBAction func contactBtnTapped(_ sender: UIButton)
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

    @IBAction func subscriptionBtnTapped(_ sender: UIButton) {


        let alertController = UIAlertController(title: "Alert", message: "Are you sure you want to cancel this subscription?", preferredStyle: .alert)

        let action1 = UIAlertAction(title: "YES", style: .default) { (action: UIAlertAction) in

            //Call Logout API
            self.cancelSubscription()

        }
        let action2 = UIAlertAction(title: "NO", style: .cancel) { (action: UIAlertAction) in

        }

        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func btnSocialLinksTapped(_ sender: Any) {
        openSocialLinks()
    }

    @IBAction func deleteAccountPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account?", preferredStyle: .alert)

        let action1 = UIAlertAction(title: "Delete", style: .destructive) { (action: UIAlertAction) in

            //Call Logout API
            self.deleteAccountApi()

        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) in

        }

        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)

    }
    
    private func openSocialLinks() {
        if let user = self.userModel {
            let vc = UIStoryboard().socialLinksVC()
            vc.user = user
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.showAlert("", "Oops!! Can't get user detail. Please try again later!")
        }
    }

    func cancelSubscription() {


        let subscriptionId = UserDefaults.standard.object(forKey: SubscriptionId) as? String ?? ""


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

    func showSuccessMessage(message: String) {
        DispatchQueue.main.async {

            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Ok", style: .cancel) { (action) in
                self.dismiss(animated: true, completion: nil);
            }
            alert.addAction(actionCancel)
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func logoutBtnTapped(_ sender: UIButton)
    {
        let alertController = UIAlertController(title: "Alert", message: "Do you want to SignOut?", preferredStyle: .alert)

        let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in

            //Call Logout API
            self.logoutAPI()

        }
        let action2 = UIAlertAction(title: "NO", style: .cancel) { (action: UIAlertAction) in

        }

        alertController.addAction(action1)
        alertController.addAction(action2)
        self.present(alertController, animated: true, completion: nil)
    }


    func logoutAPI() {
        SVProgressHUD.show()
        var userId: String?

        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["UserId": userId ?? ""
        ] as [String: Any]

        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]

        ServerCall.makeCallWitoutFile(logoutUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in

            if let json = response {

                print(json)
                SVProgressHUD.dismiss()

                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.removeObject(forKey: key_User_Profile)
                UserDefaults.standard.synchronize()
                CurrentSession.shared.clearData()
                let vc = UIStoryboard().loadLoginNavVC()
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)

            }
        }
    }
    
    func deleteAccountApi() {
        SVProgressHUD.show()
        var userId: String?

        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        let params = ["UserId": userId ?? ""
        ] as [String: Any]

        print("params: \(params)")
        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]

        ServerCall.makeCallWitoutFile(deleteProfileUrl, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in

            if let json = response {

                print(json)
                SVProgressHUD.dismiss()

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
