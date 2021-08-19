//
//  FriendTabVC.swift
//  Fone
//
//  Created by Bester on 19/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import SwiftyJSON
import NVActivityIndicatorView
import Alamofire
import SendBirdSDK
import Branch
class FriendTabVC: UIViewController {
    var users = [SBDUser]()

    //IBoutlet and Variables
    @IBOutlet weak var contactTVC: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var inviteView: UIView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    var contactArray = [Contacts]()
    var friendList = [FriendList]()
    var filteredContacts = [FriendList]()
    var isFiltering = false
    let network = NetworkManager.sharedInstance
    var netStatus: Bool?
    var refreshControl = UIRefreshControl()

    var userListQuery: SBDApplicationUserListQuery?
    var userDetails: UserDetailModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        contactTVC.addSubview(refreshControl) // not required when using UITableViewController

        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.inviteView.isHidden = true
        self.contactTVC.tableFooterView = UIView.init()

        var showLoader = true
        if !CurrentSession.shared.friends.isEmpty { showLoader = false }

        // Get Contacts Friend List
        self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: showLoader)
        network.reachability.whenReachable = { reachability in

            self.netStatus = true
            UserDefaults.standard.set("Yes", forKey: "netStatus")
            UserDefaults.standard.synchronize()

            // Get Contacts Friend List
            self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: showLoader)
        }

        network.reachability.whenUnreachable = { reachability in

            self.netStatus = false
            UserDefaults.standard.set("No", forKey: "netStatus")
            UserDefaults.standard.synchronize()
            let alertController = UIAlertController(title: "No Internet!", message: "Please connect your device to the internet.", preferredStyle: .alert)

            let action1 = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in

            }

            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    @objc func refresh(_ sender: AnyObject) {
        // Code to refresh table view
        self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: true)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)


        if PlatformUtils.isSimulator {
        } else {
            self.getSubscriptionsForCustomer()

        }

        friendList = CurrentSession.shared.friends
        getUSERSTATUS()
        self.updateView()
//        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: true)

        //checkOpenSocialLinksIfNeeded()
    }

    private func checkOpenSocialLinksIfNeeded() {
        if !UserDefaults.standard.bool(forKey: KEY_OPEN_PROFILE_SOCIAL_LINKS) {
            let alertViewController = UIAlertController(title: "Social Links", message: "It looks like your profile is not up to date. Do you want to update it now?", preferredStyle: .alert)
            alertViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                UserDefaults.standard.setValue(true, forKey: KEY_OPEN_PROFILE_SOCIAL_LINKS)
                UserDefaults.standard.synchronize()
            }))
            alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let topController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
                    topController.selectedIndex = 3 // Settings
                }
            }))
            self.present(alertViewController, animated: true, completion: nil)
        }
    }

    func updateView() {
        // if there is data for table view then show table view
        if isFiltering && filteredContacts.count > 0 || !isFiltering && friendList.count > 0 {
            contactTVC.isHidden = false
            inviteView.isHidden = true
            contactTVC.reloadData()
        } else {
            contactTVC.isHidden = true
            inviteView.isHidden = false
        }
    }

    func sendContactAPI(contactsArray: [Contacts], showLoader: Bool)
    {
        if showLoader {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }

        var userId: String = CurrentSession.shared.user?.userId ?? ""
        let loginToken = CurrentSession.shared.accessToken
        
        var contactList = [[String: Any]]()
        for contact in contactsArray
        {
            let number = contact.number?.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")

            let parameter = ["ContactsName": contact.name ?? "",
                "ContactsNumber": number ?? ""
            ]

            contactList.append(parameter)
        }

        var parameters = [
            "UserId": userId,
            "Contacts": contactList
        ] as [String: Any]
        if showLoader || contactList.count == 0 {
            parameters = ["UserId": userId] as [String: Any]
        }

        // print(parameters)
        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]

        ServerCall.makeCallWitoutFile(saveContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in

            self.refreshControl.endRefreshing()
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true


            if let json = response {
                // print(json)
                let statusCode = json["StatusCode"].string ?? ""
                if statusCode == "401" {
                    var mobilenumber: String?

                    if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                        print(userProfileData)
                        if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                            mobilenumber = user.mobile
                        }
                    }
                    self.getAccessTokenAPI(mobileNumber: mobilenumber ?? "")
                    return
                }

                ///  print(json)
                if let contacts = json["Contacts"].array {
                    if contacts.count > 0 {
                        var midConatct = [SwiftyJSON.JSON]()

                        for var items in contacts {
                            let dict = items.dictionary
                            var number = dict?["ContactsNumber"]?.string ?? ""
                            number = number.replacingOccurrences(of: " ", with: "")
                            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""

                            //let json = JSON(number)
                            items["ContactsNumber"] = JSON(number)
                            if (number.count > Min_Contact_Number_Lenght) && !(ContactsCnic.isEmpty) {
                                midConatct.append(items)
                            }
                        }

                        CurrentSession.shared.storeFriends(friends: midConatct)
                        if self.friendList.count == 0 {
                            if let chatvc = self.tabBarController?.viewControllers?[2] as? GroupChannelsViewController {
                                if chatvc.isViewLoaded {
                                    chatvc.refreshChannelList()
                                }
                            }
                        }

                        self.friendList = CurrentSession.shared.friends

                        self.getUSERSTATUS()
                    }
                }
                self.updateView()
            } else {

                var mobilenumber: String?

                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                    print(userProfileData)
                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                        mobilenumber = user.mobile
                    }
                }
                self.getAccessTokenAPI(mobileNumber: mobilenumber ?? "")
            }
        }
    }

    func getUSERSTATUS() {
        if friendList.count > 0 {
            let ids: [String] = friendList.map { $0.number ?? "" }
            let query = SBDMain.createApplicationUserListQuery()
            query?.userIdsFilter = ids
            query?.loadNextPage(completionHandler: { (users, error) in
                if error != nil {
                    Utils.showAlertController(error: error!, viewController: self)
                    return
                }

                if (users?.count)! > 0 {
                    self.users.removeAll()
                    self.users = users!
                }
                DispatchQueue.main.async {
                    self.updateView()
                }
            })
        }
    }

    func getAccessTokenAPI(mobileNumber: String)
    {

        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false

        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let parameters: [String: Any] = [
            "username": mobileNumber,
            "password": "123456",
            "client_id": ClientId,
            "grant_type": "password"
        ]

        Alamofire.request(getAccessTokenUrl, method: .post, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseJSON { (response: DataResponse<Any>) in

            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true

            switch(response.result) {
            case.success(let data):
                let json = JSON(data)
                print(json)
                let accessToken = json["access_token"].string ?? ""

                UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: true)

            case.failure(let error):
                print("Not Success", error)
                //self.errorAlert("\(error)")
                var mobilenumber: String?

                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                    print(userProfileData)
                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                        mobilenumber = user.mobile
                    }
                }
                self.getAccessTokenAPI(mobileNumber: mobilenumber ?? "")
            }
        }
    }

    @IBAction func inviteBtnTapped(_ sender: UIButton)
    {
        //Set the default sharing message.
        let message = "Fone App"
        //Set the link to share.
        if let link = NSURL(string: "")
        {
            let objectsToShare = [message, link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }


    func getSubscriptionsForCustomer() {

        var mobilenumber = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                mobilenumber = user.mobile ?? ""
            }
        }
        if mobilenumber == "+18888888888" {
            return
        }
        // mobilenumber = "9199876543"
        let header = ["Content-Type": "application/json"]
        // APIManager.sharedManager.request(getBrainTreePlans, method: Alamofire.HTTPMethod.post, parameters: nil, encoding:  JSONEncoding.default,
        let apiURL = "\(getSubscriptions_Customer)\(mobilenumber)"

        ServerCall.makeCallWitoutFile(apiURL, params: nil, type: Method.POST, currentView: nil, header: header) { (response) in
            let isAvilabel = response?["response"] ?? false
            print(isAvilabel)
            print(response)
            if isAvilabel == true {
                let subscriptionArr = response?["subscriptions"].arrayObject
                let subscritpionobject = subscriptionArr?.last as? [String: Any]
                let subDateobject = subscritpionobject?["lastdate"] as? [String: Any]
                let dateExpiry = subDateobject?["date"] as? String ?? ""
                print("dateExpiry = \(dateExpiry)")
                let dateObj = Utility.sharedInstance.getDateFromString(dateExpiry, "yyyy-MM-dd HH:mm:ss") ?? Date()
                let diffreance = Utility.sharedInstance.diffranceBetweenDays(formatedStartDate: dateObj)
                print("diffreance = \(diffreance)")

                let subscriptionStatus = subscritpionobject?[SubscriptionStatus] as? String ?? ""
                let subscriptionId = subscritpionobject?[SubscriptionId] as? String ?? ""
                let subscriptionPlan = subscritpionobject?[SubscriptionPlan] as? String
                UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)
                UserDefaults.standard.set(subscriptionPlan, forKey: SubscriptionPlan)
                UserDefaults.standard.set(subscriptionId, forKey: SubscriptionId)
                UserDefaults.standard.set("\(diffreance)", forKey: SubscriptionDays)

                if (subscriptionStatus.lowercased() != "active") && (diffreance < 0) {
                    self.openPlanListView()
                }

            } else {
                UserDefaults.standard.set("", forKey: SubscriptionStatus)
                UserDefaults.standard.set("", forKey: SubscriptionPlan)
                UserDefaults.standard.set("0", forKey: SubscriptionDays)

                self.openPlanListView()
            }
            // self.openPlanListView()

        }

    }

    func openPlanListView() {
        return
        let desiredVC = UIStoryboard().loadPlanVC()
        desiredVC.modalPresentationStyle = .fullScreen
        topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)

        //topViewController

    }

}


extension FriendTabVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredContacts.count
        }
        else
        {
            return friendList.count
        }
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocalContactTVC
        cell.btnCall.isHidden = true
        cell.btnVideo.isHidden = true
        if isFiltering {
            if filteredContacts.count > 0 {
                let contact = filteredContacts[indexPath.row]
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.ContactsCnic?.cnicToLink
                cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            } else {
                return UITableViewCell()
            }
        }
        else
        {
            if friendList.count > 0
            {
                let contact = friendList[indexPath.row]
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.ContactsCnic?.cnicToLink
                cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
                if let user = users.first(where: { $0.userId == contact.number }) {
                    if user.connectionStatus == .online {
                        debugPrint("LAST SEEN online")
                        cell.online.isHidden = false
                        cell.online.layer.cornerRadius = 5
                        cell.online.layer.masksToBounds = true
                        cell.lastseen.text = "Online"
                        cell.lastseen.textColor = .systemGreen
                    }
                    else
                    {
                        cell.online.isHidden = true
                        if user.lastSeenAt > 0 {
                            let date = Date(timeIntervalSince1970: TimeInterval(user.lastSeenAt / 1000))
                            cell.lastseen.textColor = .lightGray
                            cell.lastseen.text = date.timeAgoSinceDate()
                        }
                    }
                }
            } else {
                return UITableViewCell()
            }
        }
        cell.btnCall.tag = indexPath.row
        cell.btnCall.addTarget(self, action: #selector(self.btnCallClicked(_:)), for: .touchUpInside)
        cell.btnVideo.tag = indexPath.row
        cell.btnVideo.addTarget(self, action: #selector(self.btnVideoClicked(_:)), for: .touchUpInside)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

        if isFiltering, filteredContacts.count > 0 {
            let contact = filteredContacts[indexPath.row]
            let vc = UIStoryboard().loadUserDetailsVC()
            vc.isSearch = true
            self.getUserDetail(cnic: "", friend: contact.userId!) { (user, success) in
                if success {
                    self.view.isUserInteractionEnabled = true
                    if let cell = tableView.cellForRow(at: indexPath) as? LocalContactTVC {
                        if cell.userImage.image != nil {
                            let imgdata = cell.userImage.image?.jpegData(compressionQuality: 0.5)
                            if self.checkUSERFRIEND(num: user?.phoneNumber ?? "") {
                                self.btnClickChat(user, img: imgdata, cont: contact)

                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.isHidden = true
                                return

                            }
                        }
                    }
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    vc.userDetails = user!
                    let nav = UINavigationController(rootViewController: vc)
                    nav.navigationBar.isHidden = true
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true

                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
        else if friendList.count > 0
        {
            let contact = friendList[indexPath.row]
            let vc = UIStoryboard().loadUserDetailsVC()
            self.getUserDetail(cnic: contact.ContactsCnic!, friend: "") { (user, success) in
                if success {
                    self.view.isUserInteractionEnabled = true
                    if let cell = tableView.cellForRow(at: indexPath) as? LocalContactTVC {

                        if cell.userImage.image != nil
                        {
                            let imgdata = cell.userImage.image?.jpegData(compressionQuality: 0.5)


                            if self.checkUSERFRIEND(num: user?.phoneNumber ?? "") {
                                self.btnClickChat(user, img: imgdata, cont: contact)


                                return
                            }
                        }
                    }
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true

                    vc.userDetails = user!
                    let nav = UINavigationController(rootViewController: vc)
                    nav.navigationBar.isHidden = true
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
    }

    @objc func btnCallClicked(_ sender: UIButton) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

        if isFiltering, filteredContacts.count > 0 {
            let contact = filteredContacts[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = false
            vc.recieverNumber = contact.number
            vc.name = contact.name ?? ""
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: "", friend: contact.userId!) { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
        else if friendList.count > 0 {
            let contact = friendList[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = false
            vc.recieverNumber = contact.number
            vc.name = contact.name ?? ""
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: contact.ContactsCnic!, friend: "") { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }

        }
    }

    //MARK:- CHECK USER FRIEND STATUS : -
    func checkUSERFRIEND(num: String) -> Bool {
        if num.isEmpty { return false }
        return CurrentSession.shared.friends.first(where: { num.comparePhoneNumber(number: $0.number) }) != nil
    }


    @objc func btnVideoClicked(_ sender: UIButton) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

        if isFiltering {
            let contact = filteredContacts[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = true
            vc.recieverNumber = contact.number
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: "", friend: contact.userId!) { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
        else {
            let contact = friendList[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = true
            vc.recieverNumber = contact.number
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: contact.ContactsCnic!, friend: "") { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(
                        "Error",
                        "Can't get user information. Please try again."
                    )
                }
            }

        }
    }

    //MARK:- NEW CHANGE FOR CALL DIRECT :-
    func btnClickChat(_ userMd: UserDetailModel?, img: Data?, cont: FriendList?) {
        var userId = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId!
            }
        }
        let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
        vc.delegate = self
        vc.userDetails = userMd
        vc.contact = cont
        self.userListQuery = SBDMain.createApplicationUserListQuery()
        self.userListQuery?.limit = 100
        let arrayNumber = CurrentSession.shared.friends.map({ $0.number })
        if arrayNumber.count > 0 {
            self.userListQuery?.userIdsFilter = [userMd!.phoneNumber]
        } else {
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
                params.coverImage = img
                params.add(selecteduser)
                params.name = userMd?.name

                SBDGroupChannel.createChannel(with: [selecteduser], isDistinct: true) { (channel, error) in

                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
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



}

extension FriendTabVC: UISearchBarDelegate {

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isFiltering = true
        guard let searchText = searchBar.text else {
            isFiltering = false
            updateView()
            return
        }
        if searchText == "" {
            isFiltering = false
            self.filteredContacts.removeAll()
            updateView()
            return
        }

        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false
        self.searchFriend(byCnic: searchText) { (users, success) in
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.view.isUserInteractionEnabled = true
            if success {
                self.filteredContacts.removeAll()
                self.filteredContacts = users!

                self.isFiltering = self.filteredContacts.count > 0
                if self.isFiltering == false {
                    self.showAlert("Not user found for this fone id.")
                }
                self.updateView()
            }
        }
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
        if searchText.isEmpty {
            isFiltering = false
            self.filteredContacts.removeAll()
            updateView()
        }
    }
}

extension FriendTabVC: GroupChannelsUpdateListDelegate {

}
