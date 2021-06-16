//
//  LinksManagementViewController.swift
//  Fone
//
//  Created by Thu Le on 12/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol LinksManagementViewControllerDelegate: NSObjectProtocol {
    func linksManagementViewController(vc: LinksManagementViewController, didBackWith user: UserDetailModel)
}

class LinksManagementViewController: FMBaseViewController,
    SocialLinkViewDelegate,
    AddLinkViewControllerDelegate {
    @IBOutlet weak var lbNoLink: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!

    weak var delegate: LinksManagementViewControllerDelegate?

    var user: UserDetailModel!

    private var views: [SocialLinkView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func btnBackTapped(_ sender: Any) {
        self.delegate?.linksManagementViewController(vc: self, didBackWith: user)
        super.btnBackTapped(sender)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        user.socialLinks.forEach { link in
            let v = SocialLinkView(socialLink: link)
            v.delegate = self
            views.append(v)
            stackView.addArrangedSubview(v)
        }
        stackViewHeightConstraint.constant = CGFloat(views.count * 100)

        lbNoLink.isHidden = views.count > 0
    }

    @IBAction func btnAddNewLinkTapped(_ sender: Any) {
        let vc = UIStoryboard().addlinkVC()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.view.backgroundColor = .black.withAlphaComponent(0.5)
        self.present(vc, animated: true, completion: nil)
    }

    func socialLinkDidTap(v: SocialLinkView) {
        if let index = self.views.firstIndex(of: v) {
            //call api delete
            let link = self.user.socialLinks[index]
            let vc = UIStoryboard().addlinkVC()
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.socialLink = link
            vc.view.backgroundColor = .black.withAlphaComponent(0.5)
            self.present(vc, animated: true, completion: nil)
        }
    }

    func socialLinkViewDidDelete(v: SocialLinkView) {
        let alertVc = UIAlertController(title: "",
                                        message: "Are you sure you want to delete this item?",
                                        preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertVc.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if let index = self.views.firstIndex(of: v) {
                //call api delete
                let link = self.user.socialLinks[index]
                self.deleteSocialLink(link: link) { success in
                    if(success) {
                        self.user.socialLinks.remove(at: index)
                        self.views.removeObject(v)
                        self.stackView.removeFully(view: v)
                        self.stackViewHeightConstraint.constant = CGFloat(self.views.count * 100)
                        self.lbNoLink.isHidden = self.views.count > 0
                    } else {
                        self.showAlert("", "Can't delete social link at this time. Please try again later")
                    }
                }
            }
        }))
        self.present(alertVc, animated: true, completion: nil)
    }

    func addLinkViewController(vc: AddLinkViewController, didFinishWith link: SocialLink) {
        if link.id != 0 {
            SVProgressHUD.show()
            updateSocialLink(link: link) { success in
                SVProgressHUD.dismiss()
                if(success) {
                    vc.dismiss(animated: true) {
                        if let index = self.user.socialLinks.firstIndex(where: {$0.id == link.id}) {
                            self.user.socialLinks[index] = link
                            self.views[index].tfName.text = link.name
                            self.views[index].tfUrl.text = link.url
                        }
                        self.lbNoLink.isHidden = self.views.count > 0
                    }
                } else {
                    self.showAlert("", "Can't update social link at this time. Please try again later")
                }
            }
        } else {
            SVProgressHUD.show()
            addSocialLink(links: [link]) { success in
                SVProgressHUD.dismiss()
                if(success) {
                    vc.dismiss(animated: true) {
                        self.user.socialLinks.append(link)
                        let v = SocialLinkView(socialLink: link)
                        v.delegate = self
                        self.views.append(v)
                        self.stackView.addArrangedSubview(v)
                        self.stackViewHeightConstraint.constant = CGFloat(self.views.count * 100)
                        self.lbNoLink.isHidden = self.views.count > 0

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            if self.scrollView.contentSize.height > self.scrollView.bounds.height {
                                let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
                                self.scrollView.setContentOffset(bottomOffset, animated: true)
                            }
                        }
                    }
                } else {
                    self.showAlert("", "Can't add social link at this time. Please try again later")
                }
            }
        }
    }
}

extension UIStackView {
    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    func removeFullyAllArrangedSubviews() {
        arrangedSubviews.forEach { (view) in
            removeFully(view: view)
        }
    }
}
