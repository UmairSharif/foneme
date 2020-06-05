//
//  MainTabBarController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/12/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import UserNotifications

class MainTabBarController: UITabBarController, SBDConnectionDelegate, SBDNetworkDelegate {
    private static let TITLE_GROUP_CHANNELS = "Group"
    private static let TITLE_OPEN_CHANNELS = "Open"
    private static let TITLE_SETTINGS = "Settings"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.tintColor = hexStringToUIColor(hex: "0072F8")
    }

    // MARK: SBDNetworkDelegate
    @objc func didReconnect() {
        
    }
}
