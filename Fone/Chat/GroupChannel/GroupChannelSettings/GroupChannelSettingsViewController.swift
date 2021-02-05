//
//  GroupChannelSettingsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/9/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Photos
import AlamofireImage
import MobileCoreServices
import Branch

class GroupChannelSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupChannelInviteMemberDelegate, GroupChannelSettingsTableViewCellDelegate, GroupChannelCoverImageNameSettingDelegate, NotificationDelegate, SBDChannelDelegate {

    weak var delegate: GroupChannelSettingsDelegate?
    var channel: SBDGroupChannel?
    var members: [SBDMember] = []
    var selectedUsers: [String:SBDUser] = [:]
    var groupInfoDic = [String:Any]();

    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    static let REGULAR_MEMBER_MENU_COUNT = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getGroupInfo();
        // Do any additional setup after loading the view.
        self.title = "Private Chat Settings"
        
        self.settingsTableView.delegate = self
        self.settingsTableView.dataSource = self
        
        SBDMain.add(self as SBDChannelDelegate, identifier: self.description)
        
        self.loadingIndicatorView.isHidden = true
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        
        self.rearrangeMembers()
        
        self.settingsTableView.reloadData()
    }
    
    
    func getGroupInfo(){
        
        var userId = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId!
            }
        }

        let groupID = self.channel?.channelUrl
        
        let params = ["GroupID":groupID!,
                      "UserID": userId] as [String:Any]
        // "CNIC": textFieldFoneId.text!,
        
        print("params: \(params)")
        var headers = [String:String]()
        headers = ["Content-Type": "application/json"]
        
        ServerCall.makeCallWitoutFile(getSingleGroupDetails, params: params, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                print(json)
                //                    self.activityIndicator.stopAnimating()
                //                    self.activityIndicator.isHidden = true
                
                let statusCode = json["StatusCode"].string ?? ""
                
                if statusCode == "200" || statusCode == "201"{
                   if let groupInfo = json["GroupData"].array {
                    for items in groupInfo {
                    self.groupInfoDic  = items.dictionaryObject ?? [String:Any]()
                       }
                   }
                   
                   print(self.groupInfoDic)

                   
                } else {
                    if let message = json["Message"].string
                    {
                        print(message)
                       // self.errorAlert("\(message)")
                    }
                    
                    //                        self.activityIndicator.stopAnimating()
                    //                        self.activityIndicator.isHidden = true
                }
                self.settingsTableView.reloadData()

            }
        }
    }
      
    
    private func rearrangeMembers() {
        self.members.removeAll()
        guard let channel = self.channel else { return }
        guard let members = channel.members else { return }
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        
        for member in members as? [SBDMember] ?? [] {
            if member.userId == currentUser.userId {
                self.members.insert(member, at: 0)
            }
            else {
                self.members.append(member)
            }
        }
    }
    
    func openChat(_ channelUrl: String) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: false)
        }
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }

  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GroupChannelInviteMember", let destination = segue.destination as? GroupChannelInviteMemberViewController {
            destination.channel = self.channel
            destination.delegate = self
        } else if segue.identifier == "GroupChannelCoverSettings", let destination = segue.destination as? GroupChannelCoverImageNameSettingViewController {
            destination.channel = self.channel
            destination.delegate = self
        } else if segue.identifier == "ShowUserProfile", let destination = segue.destination as? UserProfileViewController, let index = sender as? Int {
            destination.user = self.members[index]
        }
    }
    
  func inviteBtnTapped() {
        //Set the default sharing message.
        var message = "Fone App"
    
    var groupLink = "";
    
    
    let buo = BranchUniversalObject.init(canonicalIdentifier: "content/\(self.groupInfoDic["PublicGroupLink"] as! String )")
    buo.title = "Group"
    buo.publiclyIndex = true
    buo.locallyIndex = true
    buo.contentMetadata.customMetadata["key1"] = self.groupInfoDic["GroupLink"] as? String ?? ""
    let lp: BranchLinkProperties = BranchLinkProperties()
    lp.channel = "https://fone.me/\(self.groupInfoDic["PublicGroupLink"] as! String )"
    lp.feature = "sharing"

//    let message = "Check out this link"
    buo.showShareSheet(with: lp, andShareText: message, from: self) { (activityType, completed) in
      print(activityType ?? "")
    }
         let isPublic =  self.groupInfoDic["IsPublic"] as? String
        if isPublic == "True" {
            groupLink = "https://foneme.app.link/\(self.groupInfoDic["PublicGroupLink"] as! String )"
            
//            let buo = BranchUniversalObject.init(canonicalIdentifier: "content/\(self.groupInfoDic["PublicGroupLink"] as! String )")
//            buo.title = "Group"
//            buo.publiclyIndex = true
//            buo.locallyIndex = true
//            buo.contentMetadata.customMetadata["key1"] = self.groupInfoDic["GroupLink"] as? String ?? ""
//            let lp: BranchLinkProperties = BranchLinkProperties()
//            lp.channel = "https://fone.me/\(self.groupInfoDic["PublicGroupLink"] as! String )"
//            lp.feature = "sharing"
//
//        //    let message = "Check out this link"
//            buo.showShareSheet(with: lp, andShareText: message, from: self) { (activityType, completed) in
//              print(activityType ?? "")
//            }
//            return
            
       } else {
        groupLink = self.groupInfoDic["GroupLink"] as? String ?? ""
        
//        let buo = BranchUniversalObject.init(canonicalIdentifier: "content/\(self.groupInfoDic["GroupLink"] as! String )")
//        buo.title = "Group"
//        buo.publiclyIndex = true
//        buo.locallyIndex = true
//        buo.contentMetadata.customMetadata["key1"] = self.groupInfoDic["GroupLink"] as? String ?? ""
//        let lp: BranchLinkProperties = BranchLinkProperties()
//        lp.channel = "https://fone.me/\(self.groupInfoDic["GroupLink"] as! String )"
//        lp.feature = "sharing"
//
//    //    let message = "Check out this link"
//        buo.showShareSheet(with: lp, andShareText: message, from: self) { (activityType, completed) in
//          print(activityType ?? "")
//        }
//        return
       }
    
    message = groupLink;
        //Set the link to share.
        if let link = NSURL(string: groupLink)
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 3) ? "Members" : nil
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return self.members.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let channel = self.channel, let currentUser = SBDMain.getCurrentUser() else { return UITableViewCell() }
       
        switch indexPath.section {
        case 0:
            guard let channelCoverNameCell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsChannelCoverNameTableViewCell", for: indexPath) as? GroupChannelSettingsChannelCoverNameTableViewCell else { return UITableViewCell() }
            channelCoverNameCell.channelNameTextField.placeholder = Utils.createGroupChannelNameFromMembers(channel: channel)
            channelCoverNameCell.channelNameTextField.text = channel.name
            channelCoverNameCell.delegate = self
            
            var currentMembers: [SBDMember] = []
            var count = 0
            if let members = channel.members as? [SBDMember] {
                for member in members {
                    if member.userId == currentUser.userId {
                        continue
                    }
                    currentMembers.append(member)
                    count += 1
                    if count == 4 {
                        break
                    }
                }
            }
            
            if let url = channel.coverUrl, url.count > 0 && !url.hasPrefix("https://sendbird.com/main/img/cover/") {
                channelCoverNameCell.profileImageView.setImage(withCoverUrl: url)
            }
            else {
                channelCoverNameCell.profileImageView.users = members
            }
            channelCoverNameCell.profileImageView.makeCircularWithSpacing(spacing: 1)
            
            return channelCoverNameCell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GroupShareInfoCell")!
            let infoLabel = cell.viewWithTag(100) as? UILabel
            
            let isPublic =  self.groupInfoDic["IsPublic"] as? String
            if isPublic == "True" {
                infoLabel?.text = "https://foneme.app.link/\(self.groupInfoDic["PublicGroupLink"] as! String)"
            } else {
                infoLabel?.text = self.groupInfoDic["GroupLink"] as? String
            }
            return cell
            
        case 2:
            guard let notiCell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsNotificationsTableViewCell", for: indexPath) as? GroupChannelSettingsNotificationsTableViewCell else { return UITableViewCell() }
            
            notiCell.notificationSwitch.isOn = self.channel?.myPushTriggerOption == .off ? false : true
            notiCell.delegate = self
            
            return notiCell
        case 3:
            if indexPath.row == 0{
                return tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsInviteMemberTableViewCell", for: indexPath)
            } else {
                guard let memberCell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsMemberTableViewCell", for: indexPath) as? GroupChannelSettingsMemberTableViewCell else { return UITableViewCell() }
                
                let member = self.members[indexPath.row - 1]
                memberCell.nicknameLabel.text = member.nickname
                if member.isBlockedByMe {
                    memberCell.blockedUserCoverImageView.isHidden = false
                    memberCell.statusLabel.isHidden = false
                    memberCell.statusLabel.text = "Blocked"
                }
                else {
                    memberCell.blockedUserCoverImageView.isHidden = true
                    memberCell.statusLabel.isHidden = true
                    memberCell.statusLabel.text = ""
                }
                
                if member.userId == currentUser.userId {
                    memberCell.accessoryType = .none
                }
                else {
                    memberCell.accessoryType = .disclosureIndicator
                }
                
                DispatchQueue.main.async {
                    guard let updateCell = tableView.cellForRow(at: indexPath) as? GroupChannelSettingsMemberTableViewCell else { return }
                    
                    updateCell.profileImageView.setProfileImageView(for: member)
                    
                    if member.userId == currentUser.userId {
                        updateCell.myProfileImageCoverView.isHidden = false
                    }
                    else {
                        updateCell.myProfileImageCoverView.isHidden = true
                    }
                }
                
                return memberCell
            }
        case 4:
            return tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsLeaveChatTableViewCell", for: indexPath)
        default:
            return UITableViewCell()
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return (section == 0) ? 0.1 : 18.0

     }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 251
        }
        else if indexPath.section == 1 {
            return 48
        }
        else {
            return 48
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if indexPath.section == 1 {
            inviteBtnTapped()
        } else if indexPath.section == 3, indexPath.row == 0 {
            // Invite member
            performSegue(withIdentifier: "GroupChannelInviteMember", sender: nil)
        }
        else if indexPath.section == 3 {
            performSegue(withIdentifier: "ShowUserProfile", sender: (indexPath.row - 1))
        } else if indexPath.section == 4 {
            // Leave channel
            guard let channel = self.channel else { return }
            channel.leave { (error) in
                guard error == nil else { return }
                
                DispatchQueue.main.async {
                    if self.splitViewController?.displayMode == UISplitViewController.DisplayMode.allVisible {
                        if let delegate = self.delegate {
                            delegate.didLeaveChannel()
                        }
                    } else {
                        self.dismiss(animated: true, completion: {
                            if let delegate = self.delegate {
                                delegate.didLeaveChannel()
                            }
                        })
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section != 2 || indexPath.row == 0 { return nil }
        let currentMember = self.members[indexPath.row - 1]
        if !currentMember.isBlockedByMe { return nil }
        
        let unblockAction = UIContextualAction(style: .normal, title: "Unblock") { (action, sourceView, completionHandler) in
            SBDMain.unblockUserId(currentMember.userId, completionHandler: { error in })
            let currentCell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelSettingsMemberTableViewCell", for: indexPath) as! GroupChannelSettingsMemberTableViewCell
            currentCell.blockedUserCoverImageView.isHidden = true
            currentCell.statusLabel.isHidden = true
            currentCell.statusLabel.text = ""
            tableView.reloadData()
        }
        
        unblockAction.backgroundColor = UIColor(named: "color_leave_group_channel_bg")
        return UISwipeActionsConfiguration(actions: [unblockAction])
    }
    
    // MARK: - GroupChannelInviteMemberDelegate
    func didInviteMembers() {
        self.rearrangeMembers()
        self.settingsTableView.reloadData()
    }
    
    // MARK: - GroupChannelSettingsTableViewCellDelegate
    func willUpdateChannelNameAndCoverImage() {
        performSegue(withIdentifier: "GroupChannelCoverSettings", sender: nil)
    }
    
    func didChangeNotificationSwitchButton(isOn: Bool) {
        guard let channel = self.channel else { return }
        self.loadingIndicatorView.superViewSize = self.view.frame.size
        self.loadingIndicatorView.updateFrame()
        
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
        }
        
        let pushOption:SBDGroupChannelPushTriggerOption = isOn ? .all : .off
        channel.setMyPushTriggerOption(pushOption) { (error) in
            DispatchQueue.main.async {
                self.loadingIndicatorView.isHidden = true
                self.loadingIndicatorView.stopAnimating()
            }
        }
    }
    
    // MARK: - GroupChannelCoverImageNameSettingDelegate
    func didUpdateGroupChannel() {
        DispatchQueue.main.async {
            self.settingsTableView.reloadData()
        }
    }
    
    // MARK: - SBDChannelDelegate
    func channelWasChanged(_ sender: SBDBaseChannel) {
        guard let channel = self.channel else { return }
        if sender.channelUrl == channel.channelUrl {
            DispatchQueue.main.async {
                self.rearrangeMembers()
                self.settingsTableView.reloadData()
            }
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        guard let channel = self.channel else { return }
        if sender.channelUrl == channel.channelUrl {
            DispatchQueue.main.async {
                self.rearrangeMembers()
                self.settingsTableView.reloadData()
            }
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        guard let channel = self.channel else { return }
        if sender.channelUrl == channel.channelUrl {
            DispatchQueue.main.async {
                self.rearrangeMembers()
                self.settingsTableView.reloadData()
            }
        }
    }
    
    // MARK: - Utilities
    private func showLoadingIndicatorView() {
        self.loadingIndicatorView.superViewSize = self.view.frame.size
        self.loadingIndicatorView.updateFrame()
        
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
        }
    }
    
    private func hideLoadingIndicatorView() {
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = true
            self.loadingIndicatorView.stopAnimating()
        }
    }
}
