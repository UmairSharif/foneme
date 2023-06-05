//
//  AppDelegate+DeepLink.swift
//  Fone
//
//  Created by Thu Le on 10/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import Foundation
import UIKit
import SendBirdSDK

extension AppDelegate {
    func redirectToGroup(groupLink: String) {
        let parameters = [
            "DeepLink": "https://fone.me/g/\(groupLink)"
        ] as [String: Any]
        var activity: UIActivityIndicatorView?
        if let topVC = topViewController() {
            activity = UIActivityIndicatorView.init(frame: CGRect.init(x: topVC.view.frame.width / 2 - 30, y: topVC.view.frame.height / 2, width: 60, height: 60))
            activity?.style = .gray
            activity?.startAnimating()
            activity?.hidesWhenStopped = true
            topVC.view.addSubview(activity!)
        }
        var headers = [String: String]()
        headers = ["Content-Type": "application/json"]

        ServerCall.makeCallWitoutFile(getGroupByDeepLink, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in
            if let json = response {
                debugPrint(json)
                if let vall = json["GroupData"].array,
                    let group = vall.first?.dictionary {
                    let groupId = group["GroupID"]?.string ?? ""
                    let grouptype = group["IsPublic"]?.string ?? ""
                    if let topVC = topViewController() {
                        if grouptype != "False" {
                            var channel: SBDOpenChannel?
                            SBDOpenChannel.getWithUrl(groupId) { (groupChannel, error) in
                                guard error == nil else {
                                    return
                                }
                                channel = groupChannel
                                topVC.view.alpha = 1.0
                                activity?.stopAnimating()
                                let vc = UIStoryboard(name: "OpenChannel", bundle: nil).instantiateViewController(withIdentifier: "OpenChannelChatViewController") as! OpenChannelChatViewController
                                vc.channel = channel

                                let navCont = UINavigationController.init(rootViewController: vc)
                                navCont.modalPresentationStyle = .overFullScreen
                                navCont.modalTransitionStyle = .crossDissolve
                                topVC.present(navCont, animated: false, completion: {
                                    topVC.view.alpha = 1
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    func redirectToPrivateChat(channelURL: String) {
        if let topVC = topViewController() {
            SBDGroupChannel.getWithUrl(channelURL) { (groupChannel, error) in
                guard error == nil else {
                    return
                }
                let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                vc.channel = groupChannel

                let navCont = UINavigationController.init(rootViewController: vc)
                navCont.modalPresentationStyle = .overFullScreen
                navCont.modalTransitionStyle = .crossDissolve
                topVC.present(navCont, animated: false, completion: {
                })
            }
        }
    }
}
