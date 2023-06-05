//
//  GroupChannelsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/12/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import SwiftyJSON
import SVProgressHUD
import CommonCrypto
import SwiftJWT

class GroupChannelsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SBDChannelDelegate, SBDConnectionDelegate, NotificationDelegate, CreateGroupChannelViewControllerDelegate, GroupChannelsUpdateListDelegate, CreateOpenChannelDelegate {
    
    @IBOutlet weak var topSegmentCntl: UISegmentedControl?
    @IBOutlet weak var searchBar : UISearchBar!
    @IBOutlet weak var groupChannelsTableView: UITableView!
    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var toastMessageLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    var isFiltering = false
    var filteredChannels: [SBDGroupChannel] = []
    var openChannelVC: OpenChannelsViewController?
    var openChannelNav: UINavigationController?

    var refreshControl: UIRefreshControl?
    var trypingIndicatorTimer: [String : Timer] = [:]
    
    var channelListQuery: SBDGroupChannelListQuery?
    var channels: [SBDGroupChannel] = []
    var toastCompleted: Bool = true
    var isFirstTimeLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show loader and load the data
//        SVProgressHUD.show()

        self.navigationController?.navigationBar.isHidden = true
        title = "Chat"
        navigationController?.title = "Chat"
        self.loadingIndicatorView.isHidden = true
        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.groupChannelsTableView.tableFooterView = UIView.init()
        
        self.groupChannelsTableView.delegate = self
        self.groupChannelsTableView.dataSource = self

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelsViewController.longPressChannel(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.groupChannelsTableView.addGestureRecognizer(longPressGesture)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(GroupChannelsViewController.refreshChannelList), for: .valueChanged)
        
        self.groupChannelsTableView.refreshControl = self.refreshControl
        
        self.updateTotalUnreadMessageCountBadge()
        
        self.getUserDetail { model, success in
            print(model)
        }
        
        var USER_ID : String?
        var USER_NAME : String?
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        do {
            let jwt = try decode(jwtToken: loginToken ?? "")
            print(jwt)
            USER_ID = jwt["uid"] as? String
            USER_NAME = jwt["uid"] as? String
        } catch {
            
        }
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                USER_ID = user.uniqueContact
                USER_NAME = user.name ?? ""
                
                let userDefault = UserDefaults.standard
                userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
                userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
                
                ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                    print(error ?? "not an error")
                    guard error == nil else {
                        return
                    }
                }
            }
        } else {
            let userDefault = UserDefaults.standard
            userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
            userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
            
            ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                print(error ?? "not an error")
                guard error == nil else {
                    return
                }
            }
        }
        
        guard let _ = USER_ID, let _ = USER_NAME else {
            SVProgressHUD.dismiss()
            Utils.showAlertController(title: "Error", message: "User ID and Nickname are required.", viewController: self)
            
            return
        }
        
        let userDefault = UserDefaults.standard
        userDefault.setValue(USER_ID, forKey: "sendbird_user_id")
        userDefault.setValue(USER_NAME, forKey: "sendbird_user_nickname")
        
        if  SBDMain.getCurrentUser() == nil {
            ConnectionManager.login(userId: USER_ID!, nickname: USER_NAME!) { user, error in
                guard error == nil else {
                    return
                }
                self.refreshChannelList()
            }
        }
        
        SBDMain.add(self as SBDChannelDelegate, identifier: NSUUID().uuidString)
        SBDMain.add(self as SBDConnectionDelegate, identifier: NSUUID().uuidString)
        
        searchBar.searchBarStyle = .minimal;

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor:                                                                          UIColor.white,
                                                                   NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21, weight: .medium)]

        self.navigationController?.navigationBar.barTintColor = hexStringToUIColor(hex: "0072F8")
        self.navigationController?.navigationBar.isTranslucent = false
        refreshChannelList()
        self.groupChannelsTableView.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
    }
    func showToast(message: String, completion: (() -> Void)?) {
        self.toastCompleted = false
        self.toastView.alpha = 1
        self.toastMessageLabel.text = message
        self.toastView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: {
            self.toastView.alpha = 0
        }) { (finished) in
            self.toastView.isHidden = true
            self.toastCompleted = true
            
            completion?()
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateGroupChannel", let destination = segue.destination as? CreateGroupChannelNavigationController{
            destination.channelCreationDelegate = self
        } else if segue.identifier == "ShowGroupChat", let destination = segue.destination.children.first as? GroupChannelChatViewController {
            destination.hidesBottomBarWhenPushed = true
            
            if let index = sender as? Int {
                print(self.channels[index].channelUrl)
                destination.channel = self.channels[index]
            } else if let channel = sender as? SBDGroupChannel {
                destination.channel = channel
            }
            
            destination.delegate = self
        }
    }
    
    
    @IBAction func segmentValeChanges(){
        
        if topSegmentCntl?.selectedSegmentIndex == 0 {
            containerView.isHidden = true
        } else {
            emptyLabel.isHidden = true;
            containerView.isHidden = false
            if openChannelVC == nil {
                let storyboard = UIStoryboard(name: "OpenChannel", bundle: nil)
                openChannelVC = storyboard.instantiateViewController(withIdentifier: "OpenChannelsViewController") as? OpenChannelsViewController
                openChannelNav = UINavigationController.init(rootViewController: openChannelVC ?? UIViewController())
            }
            if let controller = openChannelNav {
                let rectvalue = CGRect(x: 0, y: -38, width: self.containerView.bounds.width, height: self.containerView.bounds.height)
                controller.view.frame = rectvalue//rectvalue
                containerView.addSubview(controller.view)
                self.addChild(controller)
                controller.didMove(toParent: self)
                
            }
        }
        
    }
    
 @IBAction func clickForGroupChannel(_ sender: Any) {
    
    let alert = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        
        let actionGroup = UIAlertAction(title: "Create Private Chats", style: .default) { (action) in
            self.clickCreateGroup()
            
        }
        let actionChannel = UIAlertAction(title: "Create Public Chats", style: .default) { (action) in
            self.clickCreateChannel()
               
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(actionGroup)
        alert.addAction(actionChannel)
        alert.addAction(actionCancel)
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    @objc func clickCreateGroup() {
        performSegue(withIdentifier: "CreateGroupChannel", sender: self)
    }
    
    @objc func clickCreateChannel() {
        
        let storyboard = UIStoryboard(name: "OpenChannel", bundle: nil)
        let myVC = storyboard.instantiateViewController(withIdentifier: "CreateOpenChannelNavigation") as! CreateOpenChannelNavigationController
        
        
        if openChannelVC != nil {
         //let destination = myVC.children.first as? OpenChannelChatViewController
            myVC.createChannelDelegate = openChannelVC
        }
        
        myVC.modalPresentationStyle = .fullScreen
        self.present(myVC, animated: true, completion: nil)
         //  performSegue(withIdentifier: "CreateOpenChannel", sender: nil)
       }
    
    @objc func longPressChannel(_ recognizer: UILongPressGestureRecognizer) {
        let point = recognizer.location(in: self.groupChannelsTableView)
        guard let indexPath = self.groupChannelsTableView.indexPathForRow(at: point) else { return }
        if recognizer.state == .began {
            let channel = self.channels[indexPath.row]
            let alert = UIAlertController(title: Utils.createGroupChannelName(channel: channel), message: nil, preferredStyle: .actionSheet)
            
            let actionLeave = UIAlertAction(title: "Leave Channel", style: .destructive) { (action) in
                channel.leave(completionHandler: { (error) in
                    if let _ = error {
                        ///Utils.showAlertController(error: error, viewController: self)
                        return
                    }
                    self.refreshChannelList()
                })
            }
            
            let actionReport = UIAlertAction(title: "Report", style: .default) { (action) in
                self.showConfirmDialog("Report", "Are you sure you want to report this channel?") {
                    self.showToast(message: "Reported", completion: nil)
                }
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.modalPresentationStyle = .popover
            alert.addAction(actionLeave)
            alert.addAction(actionReport)
            alert.addAction(actionCancel)
            
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0)
                presenter.permittedArrowDirections = []
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateTotalUnreadMessageCountBadge() {
        SBDMain.getTotalUnreadMessageCount { (unreadCount, error) in
            guard let navigationController = self.navigationController else { return }
            if error != nil {
                navigationController.tabBarItem.badgeValue = nil
                
                return
            }
            
            if unreadCount > 0 {
                navigationController.tabBarItem.badgeValue = String(format: "%ld", unreadCount)
            }
            else {
                navigationController.tabBarItem.badgeValue = nil
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            SBDMain.getTotalUnreadMessageCount { (unreadCount, error) in
                guard let navigationController = self.navigationController else { return }
                if error != nil {
                    navigationController.tabBarItem.badgeValue = nil
                    return
                }
                
                if unreadCount > 0 {
                    navigationController.tabBarItem.badgeValue = String(format: "%ld", unreadCount)
                }
                else {
                    navigationController.tabBarItem.badgeValue = nil
                }
            }
        }
    }
    
    func buildTypingIndicatorLabel(channel: SBDGroupChannel) -> String {
        let typingMembers = channel.getTypingMembers()
        if typingMembers == nil || typingMembers?.count == 0 {
            return ""
        }
        else {
            if typingMembers?.count == 1 {
                return String(format: "%@ is typing.", typingMembers![0].nickname!)
            }
            else if typingMembers?.count == 2 {
                return String(format: "%@ and %@ are typing.", typingMembers![0].nickname!, typingMembers![1].nickname!)
            }
            else {
                return "Several people are typing."
            }
        }
    }
    
    @objc func typingIndicatorTimeout(_ timer: Timer) {
        if let channelUrl = timer.userInfo as? String {
            self.trypingIndicatorTimer[channelUrl]?.invalidate()
            self.trypingIndicatorTimer.removeValue(forKey: channelUrl)
            DispatchQueue.main.async {
                self.groupChannelsTableView.reloadData()
            }
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {

    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelTableViewCell") as! GroupChannelTableViewCell

        var channel = self.channels[indexPath.row]
        
        if isFiltering {
            channel = self.filteredChannels[indexPath.row]
        }

        cell.channelNameLabel.text = channel.name
        
        let lastMessageDateFormatter = DateFormatter()
        var lastUpdatedAt: Date?
        
        /// Marking Date on the Group Channel List
        if channel.lastMessage != nil {
            lastUpdatedAt = Date(timeIntervalSince1970: Double((channel.lastMessage?.createdAt)! / 1000))
        } else {
            lastUpdatedAt = Date(timeIntervalSince1970: Double(channel.createdAt))
        }
        
        let currDate = Date()
        
        let lastMessageDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: lastUpdatedAt!)
        let currDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currDate)
        
        if lastMessageDateComponents.year != currDateComponents.year || lastMessageDateComponents.month != currDateComponents.month || lastMessageDateComponents.day != currDateComponents.day {
            lastMessageDateFormatter.dateStyle = .short
            lastMessageDateFormatter.timeStyle = .none
            cell.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: lastUpdatedAt!)
        }
        else {
            lastMessageDateFormatter.dateStyle = .none
            lastMessageDateFormatter.timeStyle = .short
            cell.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: lastUpdatedAt!)
        }
        
        let typingIndicatorText = self.buildTypingIndicatorLabel(channel: channel)
        let timer = self.trypingIndicatorTimer[channel.channelUrl]
        var showTypingIndicator = false
        if timer != nil && typingIndicatorText.count > 0 {
            showTypingIndicator = true
        }
        
        if showTypingIndicator {
            cell.lastMessageLabel.isHidden = true
            cell.typingIndicatorContainerView.isHidden = false
            cell.typingIndicatorLabel.text = typingIndicatorText
        }
        else {
            cell.lastMessageLabel.isHidden = false
            cell.typingIndicatorContainerView.isHidden = true
            if channel.lastMessage != nil {
                if channel.lastMessage is SBDUserMessage {
                    let lastMessage = channel.lastMessage as! SBDUserMessage

                    cell.lastMessageLabel.text = lastMessage.message
                }
                else if channel.lastMessage is SBDFileMessage {
                    let lastMessage = channel.lastMessage as! SBDFileMessage
                    if lastMessage.type.hasPrefix("image") {
                        cell.lastMessageLabel.text = "(Image)"
                    }
                    else if lastMessage.type.hasPrefix("video") {
                        cell.lastMessageLabel.text = "(Video)"
                    }
                    else if lastMessage.type.hasPrefix("audio") {
                        cell.lastMessageLabel.text = "(Audio)"
                    }
                    else {
                        cell.lastMessageLabel.text = "(File)"
                    }
                }
                else {
                    cell.lastMessageLabel.text = ""
                }
            }
            else {
                cell.lastMessageLabel.text = ""
            }
        }
        
        cell.unreadMessageCountContainerView.isHidden = false
        if channel.unreadMessageCount > 99 {
            cell.unreadMessageCountLabel.text = "+99"
        }
        else if channel.unreadMessageCount > 0 {
           
            cell.unreadMessageCountLabel.font = UIFont.boldSystemFont(ofSize: 17)
            cell.unreadMessageCountLabel.text =  "\(channel.unreadMessageCount)"
        } else {
            cell.unreadMessageCountContainerView.isHidden = true
        }
        
        if channel.memberCount <= 2 {
            cell.memberCountContainerView.isHidden = true
        }
        else {
            cell.memberCountContainerView.isHidden = false
            cell.memberCountLabel.text = String(channel.memberCount)
        }
        
        let pushOption = channel.myPushTriggerOption
        
        switch pushOption {
        case .all, .default, .mentionOnly:
            cell.notiOffIconImageView.isHidden = true
            break
        case .off:
            cell.notiOffIconImageView.isHidden = false
            break
        }

        var members: [SBDUser] = []
        var count = 0
        if let channelMembers = channel.members as? [SBDMember], let currentUser = SBDMain.getCurrentUser() {

            if channelMembers.count == 2 {
                for member in channelMembers {
                    if member.userId != currentUser.userId {
                        cell.profileImagView.makeCircularWithSpacing(spacing: 1)
                        if let coverUrl = member.profileUrl, !coverUrl.hasPrefix("https://static.sendbird.com/sample/user_sdk"){
                            cell.profileImagView.setImage(withCoverUrl: coverUrl)
                        } else {
                            cell.profileImagView.setImage(withImage: UIImage(named: "ic_profile")!)
                        }
                    }
                }
            }else {
                for member in channelMembers {
                    if member.userId == currentUser.userId {
                        continue
                    }
                    members.append(member)
                    count += 1
                    if count == 4 {
                        break
                    }
                }
                if members.count == 1 {
                    print("break here")
                }

                if let coverUrl = channel.coverUrl {
                    if coverUrl.count > 0 && !coverUrl.hasPrefix("https://static.sendbird.com"){
                        cell.profileImagView.setImage(withCoverUrl: coverUrl)
                    }
                    else {
                        cell.profileImagView.users = members
                        cell.profileImagView.makeCircularWithSpacing(spacing: 1)
                    }
                }
            }
        }
        
        if self.channels.count > 0 && (indexPath.row == (self.channels.count - 1)) {
            self.loadChannelListNextPage(false)
        }
        
        cell.contentChatView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.contentChatView.layer.borderWidth = 1.0
        cell.contentChatView.layer.cornerRadius = 12.0
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.channels.count == 0 && self.toastCompleted && (topSegmentCntl?.selectedSegmentIndex == 0 ) {
            if !isFirstTimeLoad {
                self.emptyLabel.isHidden = false
            }
        }
        else {
            self.emptyLabel.isHidden = true
        }
        
        if isFiltering {
            return filteredChannels.count
        } else {
            return self.channels.count
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = self.channels[indexPath.row]
        if  channel.members?.count == 2,
            let currentUserLogged = CurrentSession.shared.user,
            let members = channel.members as? [SBDUser],
            let friend = members.first(where: { (currentUserLogged.mobile != $0.userId && currentUserLogged.email != $0.userId ) }) {
            
            SVProgressHUD.show()
            getUserDetailPhone(cnic: friend.userId.replacingOccurrences(of: " ", with: ""), friend: "") {userModel, success in
                SVProgressHUD.dismiss()
                if (success) {
                    let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                    vc.delegate = self
                    vc.userDetails = userModel
                    vc.contact = nil
                    vc.channel = channel
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                }
            }
        } else {
            performSegue(withIdentifier: "ShowGroupChat", sender: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let leaveAction: UIContextualAction = UIContextualAction.init(style: .destructive, title: "Leave") { (action, sourceView, completionHandler) in
            self.channels[indexPath.row].leave(completionHandler: { (error) in
                if let _ = error {
                    Utils.showAlertController(title: "Error", message: "Sorry, you cannot leave on the chat room at the moment. Please try again later.", viewController: self)
                    return
                }
                self.refreshChannelList()
            })
            
            completionHandler(true)
        }
        leaveAction.backgroundColor = UIColor(named: "color_leave_group_channel_bg")
        
        return UISwipeActionsConfiguration(actions: [leaveAction])
    }
    
    // MARK: - Load channels
    @objc func refreshChannelList() {
        self.loadChannelListNextPage(true)
    }
    
    func loadChannelListNextPage(_ refresh: Bool) {
        if refresh {
            self.channelListQuery = nil
        }
        
        if self.channelListQuery == nil {
            self.channelListQuery = SBDGroupChannel.createMyGroupChannelListQuery()
            self.channelListQuery?.limit = 100
            self.channelListQuery?.includeEmptyChannel = true
            self.channelListQuery?.order = .latestLastMessage
        }
        
        if self.channelListQuery?.hasNext == false {
            return
        }
        SVProgressHUD.show()
        self.channelListQuery?.loadNextPage(completionHandler: { (channels, error) in

            DispatchQueue.main.async {
                guard error == nil else {
                    return
                }
                if refresh {
                    self.channels.removeAll()
                }

                for channel in channels! {
                    var channelName =  Utils.createGroupChannelName(channel: channel)
                    if let channelMembers = channel.members as? [SBDMember], let currentUser = SBDMain.getCurrentUser() {
                        if channelMembers.count == 2 {// Peer chat
                            for member in channelMembers {
                                if member.userId != currentUser.userId {
                                    channelName = member.nickname ?? ""
                                }
                            }
                        } else if channelMembers.count == 1 {
                            channelName = channelMembers.first?.nickname ?? ""
                        }
                    }
                    channel.name = channelName
                    if channel.name != "" && channel.name.contains("+") == false { /// Skip channel is empty
                        self.channels.append(channel)
                    }
                }
                self.isFirstTimeLoad = false
                self.groupChannelsTableView.reloadData()
                self.refreshControl?.endRefreshing()
                SVProgressHUD.dismiss()
            }
        })
    }
    
    // MARK: - CreateGroupChannelViewControllerDelegate
    func didCreateGroupChannel(_ channel: SBDGroupChannel) {
        DispatchQueue.main.async {
            if self.channels.firstIndex(of: channel) == nil {
                self.channels.insert(channel, at: 0)
            }
            
            self.groupChannelsTableView.reloadData()
        }
    }
    
    // MARK: - GroupChannelsUpdateListDelegate
    func updateGroupChannelList() {
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
        
        self.updateTotalUnreadMessageCountBadge()
    }
    
    // MARK: - SBDChannelDelegate
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        DispatchQueue.main.async {
            if sender is SBDGroupChannel {
                var hasChannelInList = false
                for ch in self.channels {
                    if ch.channelUrl == sender.channelUrl {
                        self.channels.removeObject(ch)
                        self.channels.insert(ch, at: 0)
                        self.groupChannelsTableView.reloadData()
                        self.updateTotalUnreadMessageCountBadge()
                        
                        hasChannelInList = true
                        break
                    }
                }
                
                if hasChannelInList == false {
                    guard let channel = sender as? SBDGroupChannel else {
                        return
                    }
                    channel.name = self.generateChannelNameBy(channel)
                    self.channels.insert(channel, at: 0)
                    self.groupChannelsTableView.reloadData()
                    self.updateTotalUnreadMessageCountBadge()
                }
            }
        }
    }
    
    func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        if let timer = self.trypingIndicatorTimer[sender.channelUrl] {
            timer.invalidate()
        }
        
        let timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(GroupChannelsViewController.typingIndicatorTimeout(_ :)), userInfo: sender.channelUrl, repeats: false)
        self.trypingIndicatorTimer[sender.channelUrl] = timer
        
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        DispatchQueue.main.async {
            if self.channels.firstIndex(of: sender) == nil {
                sender.name = self.generateChannelNameBy(sender)
                self.channels.insert(sender, at: 0)
            }
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        DispatchQueue.main.async {
            if let index = self.channels.firstIndex(of: sender as SBDGroupChannel) {
                self.channels.remove(at: index)
            }
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channelWasChanged(_ sender: SBDBaseChannel) {
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        if sender is SBDGroupChannel {
            var hasChannelInList = false
            for ch in self.channels {
                if ch.channelUrl == sender.channelUrl {
                    DispatchQueue.main.async {
                        self.channels.removeObject(ch)
                        self.channels.insert(ch, at: 0)
                        self.groupChannelsTableView.reloadData()
                        self.updateTotalUnreadMessageCountBadge()
                    }
                    
                    hasChannelInList = true
                }
            }
            
            if hasChannelInList == false {
                DispatchQueue.main.async {
                    guard let channel = sender as? SBDGroupChannel else {
                        return
                    }
                    channel.name = self.generateChannelNameBy(channel)
                    self.channels.insert(channel, at: 0)
                    self.groupChannelsTableView.reloadData()
                    self.updateTotalUnreadMessageCountBadge()
                }
            }
        }
    }

    private func generateChannelNameBy(_ channel: SBDGroupChannel) -> String {

        var channelName =  Utils.createGroupChannelName(channel: channel)

        if let channelMembers = channel.members as? [SBDMember], let currentUser = SBDMain.getCurrentUser() {
            if channelMembers.count == 2 {// Peer chat
                for member in channelMembers {
                    if member.userId != currentUser.userId {
                        channelName = member.nickname ?? ""
                    }
                }
            } else if channelMembers.count == 1 {
                channelName = channelMembers.first?.nickname ?? ""
            }
        }
        return channelName

    }
    
    // MARK: - Utilities
    private func showLoadingIndicatorView() {
        SVProgressHUD.show()
    }
    
    private func hideLoadingIndicatorView() {
        SVProgressHUD.dismiss()
    }
}


extension GroupChannelsViewController : UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isFiltering = true
        guard let searchText = searchBar.text else {
            isFiltering = false
            return
        }
        if searchText == "" {
            isFiltering = false
            self.filteredChannels.removeAll()
            self.groupChannelsTableView.reloadData()
            return
        }
        self.filteredChannels.removeAll()
        self.filteredChannels =  self.channels.filter({ $0.name.lowercased().range(of: searchText.lowercased()) != nil})
        self.groupChannelsTableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isFiltering = false
        searchBar.text = ""
        self.view.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isFiltering = false
        guard let firstSubview = searchBar.subviews.first else { return }
        
        firstSubview.subviews.forEach {
            ($0 as? UITextField)?.clearButtonMode = .never
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isFiltering = false
        self.view.endEditing(true)
    }
    
   
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        debugPrint(#function)
        isFiltering = true
        guard let searchText = searchBar.text else {
            isFiltering = false
            return
        }
        if searchText == "" {
            isFiltering = false
            self.filteredChannels.removeAll()
            self.groupChannelsTableView.reloadData()
            return
        }
        self.filteredChannels.removeAll()
        self.filteredChannels =  self.channels.filter({ $0.name.lowercased().range(of: searchText.lowercased()) != nil})
        self.groupChannelsTableView.reloadData()

    }
    
}
