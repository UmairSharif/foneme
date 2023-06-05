//
//  ChatVC.swift
//  Fone
//
//  Created by PC on 22/05/20.
//  Copyright © 2020 Optechno. All rights reserved.
//

/*import UIKit
import SendBirdSDK

class ChatVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.connectToSendBirdServer()
        // Do any additional setup after loading the view.
    }
    
    func connectToSendBirdServer(){
        var USER_ID : String?
            
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                USER_ID = user.userId
            }
        }
        SBDMain.connect(withUserId: USER_ID!, completionHandler: { (user, error) in
            guard error == nil else {   // Error.
                return
            }
            print(user?.nickname)
            SBDOpenChannel.getWithUrl(CHANNEL_URL, completionHandler: { (openChannel, error) in
                guard error == nil else {   // Error.
                    return
                }
                print(openChannel)
                openChannel?.enter(completionHandler: { (error) in
                    guard error == nil else {   // Error.
                        return
                    }
                })
            })
        })
    }

    

}*/


//
//  ViewController.swift
//  SendBirdUIKit-Sample
//
//  Created by Tez Park on 11/03/2020.
//  Copyright © 2020 SendBird, Inc. All rights reserved.
//

import UIKit
//import SendBirdUIKit


class ChatVC: UIViewController {

   
    override func viewDidLoad() {
        super.viewDidLoad()
        var USER_ID : String?
        var USER_NAME : String?
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                USER_ID = user.mobile
                USER_NAME = user.name
            }
        }
        
                  view.isUserInteractionEnabled = false
                  
                  let userID = USER_ID
                  let nickname = USER_NAME
                  
        
//        if let _ = userID{
//            SBUGlobals.CurrentUser = SBUUser(userId: userID!, nickname: nickname)
//            SBUMain.connect { user, error in
//              if let user = user {
//                  UserDefaults.standard.set(userID, forKey: "user_id")
//                  UserDefaults.standard.set(nickname, forKey: "nickname")
//
//                  print("SBUMain.connect: \(user)")
//                           let channelListVC = SBUChannelListViewController(nibName: nil, bundle: nil)
////                channelListVC.theme.navigationBarTintColor =  UIColor(red: 0.0, green: 114.0/255.0, blue: 248.0/255.0, alpha: 1.0)
//
//
//                channelListVC.leftBarButton = nil
//                           let naviVC = UINavigationController(rootViewController: channelListVC)
//                           naviVC.modalPresentationStyle = .overCurrentContext
//                self.present(naviVC, animated: false, completion: nil)
//             }
//          }
//        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    // Action
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
  
}

//extension UILabel {
//    func changeColor(_ color: UIColor, duration: TimeInterval) {
//        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: {
//            self.textColor = color
//        }, completion: nil)
//    }
//}
//
//extension UIView {
//    func animateBorderColor(toColor: UIColor, duration: Double) {
//        let animation:CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
//        animation.fromValue = layer.borderColor
//        animation.toValue = toColor.cgColor
//        animation.duration = duration
//        layer.add(animation, forKey: "borderColor")
//        layer.borderColor = toColor.cgColor
//    }
//
//    func shake() {
//        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
//        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
//        animation.duration = 0.3
//        animation.values = [-10.0, 10.0, -5.0, 5.0, -2.5, 2.5, 0.0 ].map { $0 * 0.7 }
//        layer.add(animation, forKey: "shake")
//    }
//}


