//
//  CreateOpenChannelNavigationController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class CreateOpenChannelNavigationController: UINavigationController {
    weak var createChannelDelegate: CreateOpenChannelDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        //Rajesh
       navigationBar.tintColor = UIColor.white;
       navigationBar.barTintColor = hexStringToUIColor(hex: "0072F8")//UIColor(named: "color_navigation_tint")
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white,
                                             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21, weight: .medium)]
        navigationBar.isTranslucent = false
        self.navigationBar.prefersLargeTitles = false
        self.navigationBar.isHidden = true
    }
}
