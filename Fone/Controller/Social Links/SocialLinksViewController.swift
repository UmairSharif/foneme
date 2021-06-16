//
//  SocialLinksViewController.swift
//  Fone
//
//  Created by Thu Le on 12/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit
import SDWebImage
import Toast_Swift

class FMBaseViewController: UIViewController {
    @IBOutlet weak var lbTitle: UILabel!

    override var title: String? {
        didSet {
            lbTitle.text = title
        }
    }

    @IBAction func btnBackTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

class SocialLinksViewController: FMBaseViewController,
    LinksManagementViewControllerDelegate {
    @IBOutlet weak var vManageLink: UIView!
    @IBOutlet weak var vManageLinksHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbSubtile: UILabel!

    @IBOutlet weak var lbNoLink: UILabel!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.rowHeight = UITableView.automaticDimension
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    public var user: UserDetailModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        vManageLink.isHidden = true
        vManageLinksHeightConstraint.constant = 0

        lbName.text = user.name
        lbSubtile.text = "https://fone.me/\(user.cnic!)"
        if let url = URL(string: user.imageUrl) {
            imgAvatar.sd_setImage(with: url, placeholderImage: UIImage(named: "ic_profile"), options: .cacheMemoryOnly, completed: nil)
        }
        title = "\(user.name!)'s Links"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.lbNoLink.isHidden = user.socialLinks.count > 0

        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data,
            let me = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
            if user.userId == me.userId {
                vManageLink.isHidden = false
                vManageLinksHeightConstraint.constant = 100

                title = "My Links"
            }
        }
    }

    @IBAction func btnCopyTapped(_ sender: Any) {
        UIPasteboard.general.string = "https://fone.me/\(user.cnic!)"
        showToast(controller: self, message: "Copied to clipboard!!", seconds: 0.5)
    }

    @IBAction func btnManageLinkTapped(_ sender: Any) {
        let vc = UIStoryboard().linksManagementVC()
        vc.user = user
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func linksManagementViewController(vc: LinksManagementViewController, didBackWith user: UserDetailModel) {
        self.user = user
        self.tableView.reloadData()
    }
}

extension SocialLinksViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.socialLinks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocialLinkCell", for: indexPath) as! SocialLinkCell
        let link = user.socialLinks[indexPath.row]
        cell.lbName.text = link.name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //open webview
        let link = user.socialLinks[indexPath.row]
        if let url = URL(string: link.url),
            UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            showAlert("", "Can't open url: \(link.url)")
        }
    }
}

class SocialLinkCell: UITableViewCell {
    @IBOutlet weak var lbName: UILabel!
}
