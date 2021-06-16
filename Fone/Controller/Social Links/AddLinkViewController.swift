//
//  AddLinkViewController.swift
//  Fone
//
//  Created by Thu Le on 12/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import Foundation
import UIKit

protocol AddLinkViewControllerDelegate: NSObjectProtocol {
    func addLinkViewController(vc: AddLinkViewController, didFinishWith link: SocialLink)
}

class AddLinkViewController: UIViewController {
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tfUrl: UITextField!

    var socialLink: SocialLink?
    weak var delegate: AddLinkViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if socialLink != nil {
            lbTitle.text = "Edit Link"
            tfName.text = socialLink?.name
            tfUrl.text = socialLink?.url
        }
    }

    @IBAction func btnCancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func btnOkTapped(_ sender: Any) {
        guard let name = tfName.text,
            name.isEmpty == false,
            var url = tfUrl.text,
            url.validURL else {
            showAlert("", "Please input valid name and URL!!!")
            return
        }

        if !url.starts(with: "https://") &&
            !url.starts(with: "http://") {
            url = "https://\(url)"
        }

        let result = socialLink == nil
            ? SocialLink(id: 0, name: name, link: url): SocialLink(id: socialLink!.id, name: name, link: url)
        delegate?.addLinkViewController(vc: self, didFinishWith: result)
    }
}

extension String {
    var validURL: Bool {
        get {
            let regEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
            let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regEx])
            return predicate.evaluate(with: self)
        }
    }
}
