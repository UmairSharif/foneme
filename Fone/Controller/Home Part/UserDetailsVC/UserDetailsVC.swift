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

protocol AddFriendDelegate {
    func addFriendRefresh()
}
class UserDetailsVC: UIViewController {

    //MARK:-Outlets
    
    @IBOutlet weak var lblVideoCall: UILabel!
    @IBOutlet weak var lblChat: UILabel!
    @IBOutlet weak var lblVoiceCall: UILabel!
    @IBOutlet weak var btnVideoCall: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    @IBOutlet weak var btnFriend: UIButton!
    @IBOutlet weak var btnFonemeID: UIButton!
    @IBOutlet weak var LbluserName: UILabel!
    @IBOutlet weak var UserImage: UIImageView!
    var userDetails:UserDetailModel?
    var userListQuery: SBDApplicationUserListQuery?
    var isSearch = false
    var delegate : AddFriendDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillAppear(_ animated: Bool) {
        print(userDetails?.userId)
        
        let currUserNumber = userDetails?.phoneNumber ?? ""
              var isContactAdded = false
              if let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data  {
                                if let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) {
                                    if contacts.count > 0 {
                                        for items in contacts {
                                            let dict = items.dictionary
                                            let number = dict?["ContactsNumber"]?.string ?? ""
                                          if number == currUserNumber {
                                              isContactAdded = true
                                              break;
                                          }
                                            
                                        }
                                    }
                                }
                                
                            }
        if isSearch && !isContactAdded{
            self.btnFriend.isHidden = false
        }else{
            self.btnFriend.isHidden = true
        }
        UserImage.layer.cornerRadius = UserImage.frame.size.height / 2
        self.UserImage.sd_setImage(with: URL(string: userDetails?.imageUrl ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        self.LbluserName.text = userDetails?.name ?? ""
        self.btnFonemeID.setTitle("fone.me/\(userDetails?.cnic ?? "")", for: .normal)
        
    }
    
    @IBAction func btnClickBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnCopyBranchLink(_ sender : UIButton){
        UIPasteboard.general.string = sender.titleLabel?.text ?? ""
        self.showToast(controller: self, message: "Fone id copied", seconds: 1)
    }
    
    
    @IBAction func btnClickFriend(_ sender: UIButton) {
        self.addFirend(foneId: (userDetails?.cnic)!, friendId: (userDetails?.userId)!, url: (btnFonemeID.titleLabel?.text)!) { (user, success) in
            if success {
                self.showAlert("Friend add successfully")
                if self.delegate != nil {
                    self.delegate?.addFriendRefresh()
                }
            }else{
                self.showAlert("\(self.userDetails?.name ?? "User") is already your friend.")
            }
        }
    }
    
    @IBAction func btnClickVoiceCall(_ sender: UIButton) {
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
    }
    
    @IBAction func btnClickChat(_ sender: UIButton) {
        var userId = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId!
            }
        }
        let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
        vc.delegate = self
        self.userListQuery = SBDMain.createApplicationUserListQuery()
        self.userListQuery?.limit = 100
        var arrayNumber = [String]()
        if let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data  {
            if let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) {
                if contacts.count > 0 {
                    for items in contacts
                    {
                        let dict = items.dictionary
                            
                        let number = dict?["ContactsNumber"]?.string ?? ""
                        arrayNumber.append(number)
                    }
                }
            }

        }
        if arrayNumber.count > 0 {
            self.userListQuery?.userIdsFilter = [self.userDetails!.phoneNumber!]
        }else {
            self.userListQuery?.userIdsFilter = ["0"]
        }
        var selecteduser = SBDUser()
        self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
            if error != nil {
                print(error?.localizedDescription ?? "Error")
                return
            }
            
            DispatchQueue.main.async {
              
                for user in users! {
                    if user.userId == SBDMain.getCurrentUser()!.userId {
                        continue
                    }
                    //User user here
                    selecteduser = user
                }
                
                let params = SBDGroupChannelParams()
                params.coverImage = self.UserImage.image?.jpegData(compressionQuality: 0.5)
                params.add(selecteduser)
                params.name = self.userDetails?.name
                
                SBDGroupChannel.createChannel(with: [selecteduser], isDistinct: true) { (channel, error) in
                    if let error = error {
                        let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                        alertController.addAction(actionCancel)
                        DispatchQueue.main.async {
                            self.present(alertController, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    
                    vc.channel = channel
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                }
                
            }
        })
        
    }
    
    @IBAction func btnClickVideoCall(_ sender: UIButton) {
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
    }
}

extension UserDetailsVC : GroupChannelsUpdateListDelegate {
    
}
