//
//  UserProfileViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/17/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage

class UserProfileViewController: UIViewController, NotificationDelegate {
    var user: SBDUser?

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var onlineStateLabel: UILabel!
    @IBOutlet weak var onlineStateImageView: UIImageView!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    var userNew: SBDUser?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Profile"
        self.navigationItem.largeTitleDisplayMode = .automatic

        guard let user = self.user else { return }
        self.refreshUserInfo(user)

        let query = SBDMain.createApplicationUserListQuery()
        query?.userIdsFilter = [user.userId]
        query?.loadNextPage(completionHandler: { (users, error) in
            if error != nil {
                Utils.showAlertController(error: error!, viewController: self)
                return
            }

            if (users?.count)! > 0 {
                self.refreshUserInfo(users![0])
            }
        })
    }

    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }

    func refreshUserInfo(_ user: SBDUser) {
        self.profileImageView.setProfileImageView(for: user)

        self.nicknameLabel.text = user.nickname
        userNew = user
        if user.connectionStatus == .online {
            self.onlineStateImageView.image = UIImage(named: "img_online")
            self.onlineStateLabel.text = "Online"
            self.lastUpdatedLabel.isHidden = true
        }
        else {
            self.onlineStateImageView.image = UIImage(named: "img_offline")
            self.onlineStateLabel.text = "Offline"
            if user.lastSeenAt > 0 {
                self.lastUpdatedLabel.text = String(format: "Last Updated %@", Utils.getDateStringForDateSeperatorFromTimestamp(user.lastSeenAt))
                self.lastUpdatedLabel.isHidden = false
            }
            else {
                self.lastUpdatedLabel.isHidden = true
            }
        }
    }
    @IBAction func OpenProfile(_ sender: Any) {
        guard let userM = self.userNew else { return }


//        self.view.isUserInteractionEnabled = false
//        return;

        debugPrint("USER", userM.userId, userM.friendDiscoveryKey, userM.metaData, userM.friendName, userM.nickname)
        let vc = UIStoryboard().loadUserDetailsVC()
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        self.getUserDetailPhone(cnic: userM.userId, friend: "") { (user, success) in
            if success {
                self.view.isUserInteractionEnabled = true

                vc.userDetails = user!
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }

    }

    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: false)
        }
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
}
