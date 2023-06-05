//
//  UserDetailsVC.swift
//  Fone
//
//  Created by PC on 01/07/20.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import SendBirdSDK
import SwiftyJSON
import Branch
import NVActivityIndicatorView
import SVProgressHUD

// @rackuka: introduce isFriendAdded - app specific property designating if button should let add friend OR depict that the friend is added
class UIFriendButton: UIButton {
    var isFriendAdded: Bool = false {
        didSet {
            self.isSelected = isFriendAdded
            self.isUserInteractionEnabled = !isFriendAdded
        }
    }
}
class UserDetailsVC: UIViewController {

    //MARK:-Outlets

    @IBOutlet weak var lblVideoCall: UILabel!
    @IBOutlet weak var lblChat: UILabel!
    @IBOutlet weak var lblVoiceCall: UILabel!
    @IBOutlet weak var btnVideoCall: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    @IBOutlet weak var btnFriend: UIFriendButton!
    @IBOutlet weak var btnFonemeID: UIButton!
    @IBOutlet weak var LbluserName: UILabel!
    @IBOutlet weak var lblAdress: UILabel!
    @IBOutlet weak var UserImage: UIImageView!
    @IBOutlet weak var lblAboutme: UILabel!
    @IBOutlet weak var lblprofession: UILabel!
    @IBOutlet weak var viewLoc: UIView!
    @IBOutlet weak var viewDes: UIView!
    @IBOutlet weak var viewLinks: UIView!
    @IBOutlet weak var lbLinks: UILabel!
    var userDetails: UserDetailModel?
    var userListQuery: SBDApplicationUserListQuery?
    var isSearch = false
    var isFromLink = false
    var FoneID = ""
    var activityIndicatorView: NVActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewDes.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        viewDes.layer.borderWidth = 1.0
        viewDes.layer.cornerRadius = 12.0
        
        viewLinks.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        viewLinks.layer.borderWidth = 1.0
        viewLinks.layer.cornerRadius = 12.0
        
    }
    override func viewWillAppear(_ animated: Bool) {
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect.init(x: self.view.center.x - 30, y: self.view.center.y - 30, width: 60, height: 60), type: .ballPulse, color: .blue)
        self.view.addSubview(activityIndicatorView!)
        if isFromLink == true {
            activityIndicatorView?.startAnimating()
            isFromLink = false

            self.getUserDetail(cnic: FoneID, friend: "") { (userModel, success) in
                if success {
                    self.activityIndicatorView?.stopAnimating()
                    self.userDetails = userModel
                    self.UpdateDetails()
                } else {
                    self.showAlert("Error"," Can't get user information. Please try again.")
                }
            }
        }
        else {
            self.UpdateDetails()
        }

    }

    //MARK:- Update Details
    func UpdateDetails() {
        var isContactAdded = false
        if let number = userDetails?.phoneNumber {
            if CurrentSession.shared.friends.first(where: {number.comparePhoneNumber(number: $0.number)}) != nil {
                isContactAdded = true
            }
        }
        
        self.btnFriend.isFriendAdded = isContactAdded
        UserImage.layer.cornerRadius = UserImage.frame.size.height / 2
        UserImage.contentMode = .scaleAspectFill
        self.UserImage.sd_setImage(with: URL(string: userDetails?.imageUrl ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        self.LbluserName.text = userDetails?.name ?? ""
        self.btnFonemeID.setTitle(userDetails?.cnic?.cnicToLink, for: .normal)
        self.lblAboutme.text = self.userDetails?.aboutme ?? "Hey there! I am using Fone Messenger."
        self.lblprofession.text = self.userDetails?.profession ?? ""
        //viewLoc.isHidden = true

        self.lblAdress.text = ""
        if self.userDetails?.location != "" && self.userDetails?.location != nil && self.userDetails?.location != "null"
        {
            //viewLoc.isHidden = false
            self.lblAdress.text = self.userDetails?.location ?? ""
        }
        if let name = userDetails?.name {
            lbLinks.text = "\(name)'s Links"
        }
    }

    @IBAction func btnClickBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func btnCopyBranchLink(_ sender: UIButton) {
        UIPasteboard.general.string = sender.titleLabel?.text ?? ""
        self.showToast(controller: self, message: "Fone id copied", seconds: 1)
    }

    @IBAction func btnLinksTapped(_ sender: Any) {
        if let user = self.userDetails {
            let vc = UIStoryboard().socialLinksVC()
            vc.user = user
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.showAlert("", "Oops!! Can't get user detail. Please try again later!")
        }
    }

    @IBAction func btnClickFriend(_ sender: UIButton) {
        SVProgressHUD.show()
        self.addFirend(foneId: (userDetails?.cnic)!, friendId: (userDetails?.userId)!, url: (btnFonemeID.titleLabel?.text)!) { (user, success) in
            if success {
                self.getContacts { finished in
                    SVProgressHUD.dismiss()
                    // @rackuka: reflect state change - now friend has been added
                    self.btnFriend.isFriendAdded = true
                    self.showAlert("Friend add successfully")
                }
            } else {
                SVProgressHUD.dismiss()
                self.showAlert("\(self.userDetails?.name ?? "User") is already your friend.")
            }
        }
    }

    @IBAction func btnClickVoiceCall(_ sender: UIButton) {

        // UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)

//        let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
//        if subscription.lowercased() == "active" {

        let contact = userDetails
        let vc = UIStoryboard().loadVideoCallVC()
        vc.isVideo = false
        vc.recieverNumber = contact?.phoneNumber
        vc.name = contact?.name ?? ""
        vc.userImage = contact?.imageUrl
        vc.DialerFoneID = contact?.cnic ?? ""
        vc.userDetails = contact
        NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
        self.present(vc, animated: true, completion: nil)
//        } else {
//
//            self.show(message: "Please subscribe for app to use this feature.")
//        }

    }

    @IBAction func btnClickChat(_ sender: UIButton) {
        if let userDetail = self.userDetails,
            let query = SBDMain.createApplicationUserListQuery() {
            query.limit = 100
            query.userIdsFilter = [userDetail.phoneNumber]

            SVProgressHUD.show()
            query.loadNextPage {[weak self] users, error in
                guard let sSelf = self else { return }
                if let error = error {
                    SVProgressHUD.dismiss()
                    sSelf.showAlert("Error", error.localizedDescription)
                    return
                }
                if let users = users, let selectedUser = users.first {
                    SBDGroupChannel.createChannel(with: [selectedUser], isDistinct: true) {[weak self] channel, error in
                        guard let sSelf = self else { return }
                        SVProgressHUD.dismiss()
                        if let error = error {
                            sSelf.showAlert("Error", error.localizedDescription)
                            return
                        }

                        DispatchQueue.main.async {
                            let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                            vc.delegate = sSelf
                            vc.userDetails = sSelf.userDetails
                            vc.channel = channel
                            let nav = UINavigationController(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            sSelf.present(nav, animated: true, completion: nil)
                        }
                    }
                } else {
                    SVProgressHUD.dismiss()
                    sSelf.showAlert("Error", "Can't find this user in Sendbird. Please contact administrator.")
                }
            }
        }
    }

    @IBAction func btnClickVideoCall(_ sender: UIButton) {
//        let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
//      if subscription.lowercased() == "active" {
        let contact = userDetails
        let vc = UIStoryboard().loadVideoCallVC()
        vc.isVideo = true
        vc.recieverNumber = contact?.phoneNumber
        vc.name = contact?.name ?? ""
        vc.userImage = contact?.imageUrl
        vc.DialerFoneID = contact?.cnic ?? ""
        vc.userDetails = contact
        NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
        self.present(vc, animated: true, completion: nil)
//              } else {
//
//            self.show(message: "Please subscribe for app to use this feature.")
//        }
    }

    func show(message: String) {
        DispatchQueue.main.async {

            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UserDetailsVC: GroupChannelsUpdateListDelegate {

}
