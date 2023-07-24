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
import SVProgressHUD
import CoreLocation

class FriendTabVC: UIViewController, CLLocationManagerDelegate {
    
    var users = [SBDUser]()
  
    //IBoutlet and Variables
    @IBOutlet weak var contactTVC: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var inviteView: UIView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!

    private var contactArray: [Contacts] = [] {
        didSet {
            contactTVC.reloadData()
        }
    }
    
    private var friendList: [FriendList] = [] {
        didSet {
            contactTVC.reloadData()
        }
    }
    
    private var filteredContacts: [FriendList] = [] {
        didSet {
            contactTVC.reloadData()
        }
    }
    
    private var isFiltering = false
    private let network = NetworkManager.sharedInstance
    private var netStatus: Bool?
    private var refreshControl = UIRefreshControl()
    private var userListQuery: SBDApplicationUserListQuery?
    private var userDetails: UserDetailModel?
    private var locationManager = CLLocationManager()
    private var prevLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.contactTVC.keyboardDismissMode = .interactive
        var showLoader = true
        if !CurrentSession.shared.friends.isEmpty { showLoader = false }
        
        // Get Contacts Friend List
        self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: showLoader)
        network.reachability.whenReachable = { reachability in

            self.netStatus = true
            UserDefaults.standard.set("Yes", forKey: "netStatus")
            UserDefaults.standard.synchronize()
            self.setCacheData()
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
        
        searchBar.backgroundImage = UIImage()
        startUpdatingLocation()
    }
    
    
    private func startUpdatingLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func updateUserLocation(_ newLocation : CLLocation) {
        if let currentUser = CurrentSession.shared.user {
            currentUser.updateUserLocationWithBlock(latitude: "\(newLocation.coordinate.latitude)", longitude: "\(newLocation.coordinate.longitude)") { status in
                if status {
                    debugPrint("User location successfully updated.")
                } else {
                    debugPrint("User location failed to update.")
                }
            }
        }
    }
    
    // MARK: Location manager delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            /// Update user location
            if prevLocation == nil {
                prevLocation = newLocation
                updateUserLocation(newLocation)
            } else {
                /// A requested moon phase calculation is supposed to trigger  if users travel to new location with different time zone
                /// A hardcoded 10 km for now.
                if newLocation.distance(from: prevLocation!) > 20000 {
                    updateUserLocation(newLocation)
                }
            }
            
        }
    }

    @objc func refresh(_ sender: AnyObject) {
        // Code to refresh table view
        self.sendContactAPI(contactsArray: LocalContactHandler.instance.contactArray, showLoader: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.friendList.removeAll()
        self.setupFriendList()
        self.updateView()
        self.getUserStatus()
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
            inviteView.isHidden = true//false
        }
    }

    private func showIndicatorView() {
        SVProgressHUD.show()
        self.view.isUserInteractionEnabled = false
    }

    private func hideIndicatorView() {
        SVProgressHUD.dismiss()
        self.view.isUserInteractionEnabled = true
    }

    func loadNearyByPeopleAPI() {
        self.showIndicatorView()
        self.friendList = []
        let userId: String = CurrentSession.shared.user?.userId ?? ""
        let loginToken = CurrentSession.shared.accessToken

        let parameters: [String: Any] = [
            "UserId": userId,
            "Latitude": String(GLBLatitude),
            "Longitude": String(GLBLongitude),
            "Radius":"500000",
            "Unit":"Meter"
        ]

        let headers: [String: String] = ["Content-Type": "application/json",
                                          "Authorization": "Bearer " + loginToken!]
        print("parameters = \(parameters) \n url = \(nearbyContactUrl)")
        ServerCall.makeCallWitoutFile(nearbyContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in

            if let json = response {
            //    print(json)
                guard let statusCode = json["StatusCode"].string, statusCode != "401" else {
                    /// 401 code
                    //Utils.showAlertController(title: "Error", message: "Something went wrong. Please try again later.", viewController: self)
                    self.hideIndicatorView()
                    return
                }

                if let contacts = json["UserAboutMeData"].array {
                    if contacts.count > 0 {
                        var midConatct = [SwiftyJSON.JSON]()

                        for var items in contacts {
                            let dict = items.dictionary
                            var number = dict?["ContactsNumber"]?.string ?? ""
                            number = number.replacingOccurrences(of: " ", with: "")
                            items["ContactsNumber"] = JSON(number)
                            midConatct.append(items)
                        }

                        midConatct.forEach { contact in
                            let dict = contact.dictionary
                            var contact = FriendList()
                            contact.number = dict?["ContactsNumber"]?.string ?? ""
                            contact.name = dict?["ContactsName"]?.string ?? ""
                            contact.email = dict?["Email"]?.string ?? ""
                            contact.socialId = dict?["SocialId"]?.string ?? ""
                            contact.ContactsCnic = dict?["FoneMe"]?.string ?? ""
                            contact.userImage = dict?["ImageURL"]?.string ?? ""
                            contact.userId = dict?["UserID"]?.string ?? ""
                            contact.distance = dict?["Distance"]?.string ?? ""
                            contact.profession = dict?["Profession"]?.string ?? ""
                            if CurrentSession.shared.user?.userId != contact.userId {
                                self.friendList.append(contact)
                            }
                        }
                    }
                }
                
                self.getUserStatus()
                self.hideIndicatorView()

            } else {
                self.hideIndicatorView()
            }
        }
    }
    
    func sendContactAPI(contactsArray: [Contacts], showLoader: Bool) {
        if showLoader {
            showIndicatorView()
        } else {
            hideIndicatorView()
        }

        let userId = CurrentSession.shared.user?.userId ?? ""
        let loginToken = CurrentSession.shared.accessToken
        
        var contactList: [[String: Any]] = []
        for contact in contactsArray {
            let number = contact.number?.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")

            let parameter = ["ContactsName": contact.name ?? "",
                "ContactsNumber": number ?? ""
            ]

            contactList.append(parameter)
        }

        var parameters = [
             "UserId": userId,
             "Contacts": contactList,
             "Latitude": String (GLBLatitude) ,
             "Longitude": String (GLBLongitude) ,
             "Radius": "500000",
             "Unit": "Meter",
             "Page": 100
         ] as [String: Any]
        
        if showLoader || contactList.count == 0 {
            parameters = [
                "UserId": userId,
                "Latitude": String (GLBLatitude) ,
                "Longitude": String (GLBLongitude) ,
                "Radius": "500000",
                "Unit": "Meter",
                "Page": 100
           
            ] as [String: Any]
          }
        

        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]
        print("parameters = \(parameters) \n url = \(saveContactUrl)")
        ServerCall.makeCallWitoutFile(saveContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in

            self.refreshControl.endRefreshing()
            self.hideIndicatorView()

            if let json = response {
            //    print(json)
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

                if let contacts = json["Contacts"].array {
                    if contacts.count > 0 {
                        var midConatct = [SwiftyJSON.JSON]()
                        self.friendList = []
                        for var items in contacts {
                            let dict = items.dictionary
                            var number = dict?["ContactsNumber"]?.string ?? ""
                            number = number.replacingOccurrences(of: " ", with: "")
                            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""

                            items["ContactsNumber"] = JSON(number)
                            if !ContactsCnic.isEmpty {
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

                        self.setupFriendList()

                        self.getUserStatus()
                    } else {
                        self.setupFriendList()
                    }
                }
                self.updateView()
            } else {

                var mobilenumber: String?
                var isSocialLogin = false
                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {

                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                        mobilenumber = user.mobile
                        isSocialLogin = user.isSocialLogin ?? false
                    }
                }
                
                if let mobile = mobilenumber, mobile.isEmpty {
                    return
                }
                if isSocialLogin {
                    return
                }
                self.getAccessTokenAPI(mobileNumber: mobilenumber ?? "")
                
            }
        }
    }

    func getAccessTokenAPI(mobileNumber : String) {
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let parameters : [String : Any] = [
            "username": mobileNumber,
            "password" : "123456",
            "client_id" : ClientId,
            "grant_type" : "password"
        ]
        
        print("parameters = \(parameters) \n getAccessTokenUrl = \(getAccessTokenUrl)")

        
        Alamofire.request(getAccessTokenUrl, method: .post, parameters: parameters, encoding:  URLEncoding.httpBody, headers: headers).responseJSON { (response:DataResponse<Any>) in
            
            switch(response.result) {
            case.success(let data):

                let json = JSON(data)
                let accessToken = json["access_token"].string ?? ""
                //Call Local Contacts Function
                
                UserDefaults.standard.set(accessToken, forKey: "AccessToken")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                
           
            case.failure(let error):
                print("Not Success",error)
                //self.errorAlert("\(error)")
            }
        }
    }
    
    func setupFriendList() {
        self.friendList = CurrentSession.shared.friends
                
        if self.friendList.count == 0 {
            self.loadNearyByPeopleAPI()
        }
        
        var type = FriendList()
        type.name = "Invite Friends"
        type.type = "cell_custom"
        type.userImage = "invite_friend"
        self.friendList.insert(type, at: 0)
        
        type = FriendList()
        type.name = "Find People Nearby"
        type.type = "cell_custom"
        type.userImage = "location"
        self.friendList.insert(type, at: 0)
        
    }
    
    func getUserStatus() {
        if friendList.count > 0 {
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                let ids: [String] = friendList.map { $0.number ?? "" }
                let query = SBDMain.createApplicationUserListQuery()
                query?.userIdsFilter = ids
                query?.loadNextPage(completionHandler: { (users, error) in
                    if error != nil {
                        ///Utils.showAlertController(error: error!, viewController: self)
                        return
                    }

                    if let users = users, users.count > 0 {
                        self.users = users
                    }
                    DispatchQueue.main.async {
                        self.updateView()
                    }
                })
            }

        }
    }

    func get5AccessTokenAPI(mobileNumber: String) {

        self.showIndicatorView()

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

            self.hideIndicatorView()

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

    func inviteBtnTapped() {
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
        print("parameters = nil \n url = \(apiURL)")
        ServerCall.makeCallWitoutFile(apiURL, params: nil, type: Method.POST, currentView: nil, header: header) { (response) in
            let isAvailable = response?["response"] ?? false
            debugPrint(isAvailable)
            debugPrint(response ?? "")
            if isAvailable == true {
                let subscriptionArr = response?["subscriptions"].arrayObject
                let subscritpionobject = subscriptionArr?.last as? [String: Any]
                let subDateobject = subscritpionobject?["lastdate"] as? [String: Any]
                let dateExpiry = subDateobject?["date"] as? String ?? ""
                debugPrint("dateExpiry = \(dateExpiry)")
                let dateObj = Utility.sharedInstance.getDateFromString(dateExpiry, "yyyy-MM-dd HH:mm:ss") ?? Date()
                let diffreance = Utility.sharedInstance.diffranceBetweenDays(formatedStartDate: dateObj)
                debugPrint("diffreance = \(diffreance)")

                let subscriptionStatus = subscritpionobject?[SubscriptionStatus] as? String ?? ""
                let subscriptionId = subscritpionobject?[SubscriptionId] as? String ?? ""
                let subscriptionPlan = subscritpionobject?[SubscriptionPlan] as? String
                UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)
                UserDefaults.standard.set(subscriptionPlan, forKey: SubscriptionPlan)
                UserDefaults.standard.set(subscriptionId, forKey: SubscriptionId)
                UserDefaults.standard.set("\(diffreance)", forKey: SubscriptionDays)
                UserDefaults.standard.synchronize()
                if (subscriptionStatus.lowercased() != "active") && (diffreance < 0) {
                    self.openPlanListView()
                }

            } else {
                UserDefaults.standard.set("", forKey: SubscriptionStatus)
                UserDefaults.standard.set("", forKey: SubscriptionPlan)
                UserDefaults.standard.set("0", forKey: SubscriptionDays)
                UserDefaults.standard.synchronize()
                self.openPlanListView()
            }

        }

    }

    func openPlanListView() {
        /// Looks like we are disabling this feature
        return
        let desiredVC = UIStoryboard().loadPlanVC()
        desiredVC.modalPresentationStyle = .fullScreen
        topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)

    }

}


extension FriendTabVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredContacts.count
        }
        return friendList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocalContactTVC
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
                if contact.type == "cell_custom"
                {
                    cell = tableView.dequeueReusableCell(withIdentifier: "cell_custom", for: indexPath) as! LocalContactTVC
                    cell.nameLbl.text = contact.name
                    cell.userImage.image = UIImage(named: contact.userImage!)
                    
                    cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
                    cell.cellContentView.layer.borderWidth = 1.0
                    cell.cellContentView.layer.cornerRadius = 12.0
                    
                    return cell
                } else if contact.type == "empty_cell" {
                    return tableView.dequeueReusableCell(withIdentifier: "EmptyCellID", for: indexPath)
                }
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
        
        
        cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.cellContentView.layer.borderWidth = 1.0
        cell.cellContentView.layer.cornerRadius = 12.0
        return cell
        
        
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.showIndicatorView()
        if isFiltering, filteredContacts.count > 0 {
            let contact = filteredContacts[indexPath.row]
            let vc = UIStoryboard().loadUserDetailsVC()
            vc.isSearch = true
            self.getUserDetail(cnic: "", friend: contact.userId ?? "" ) { (user, success) in
                if success {
                    if let cell = tableView.cellForRow(at: indexPath) as? LocalContactTVC {
                        if cell.userImage.image != nil {
                            let imgdata = cell.userImage.image?.jpegData(compressionQuality: 0.5)
                            if self.checkUSERFRIEND(num: user?.phoneNumber ?? "") {
                                self.btnClickChat(user, img: imgdata, cont: contact)
                                
                                self.hideIndicatorView()
                                return
                                
                            }
                        }
                    }
                    self.hideIndicatorView()
                    vc.userDetails = user!
                    let nav = UINavigationController(rootViewController: vc)
                    nav.navigationBar.isHidden = true
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
                    
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
        else if friendList.count > 0 {
   
            let contact = friendList[indexPath.row]
            
            if contact.name == "Find People Nearby" {
                self.hideIndicatorView()
                let vc = UIStoryboard().loadNearByVC()
                self.navigationController?.pushViewController(vc, animated: true)
            } else if contact.name == "Invite Friends" {
                self.hideIndicatorView()
                self.inviteBtnTapped()
            } else {
                let vc = UIStoryboard().loadUserDetailsVC()
                self.getUserDetail(cnic: contact.ContactsCnic!, friend: contact.userId!) { (user, success) in
                    self.hideIndicatorView()
                    if success {
                        if let cell = tableView.cellForRow(at: indexPath) as? LocalContactTVC {
                            
                            if cell.userImage.image != nil
                            {
                                let imgdata = cell.userImage.image?.jpegData(compressionQuality: 0.5)
                                if  self.checkUSERFRIEND(num: user?.uniqueContact ?? "") {
                                    self.btnClickChat(user, img: imgdata, cont: contact)
                                    return
                                }
                            }
                        }
                        vc.userDetails = user!
                        let nav = UINavigationController(rootViewController: vc)
                        nav.navigationBar.isHidden = true
                        nav.modalPresentationStyle = .fullScreen
                        self.present(nav, animated: true, completion: nil)
                    } else {
                        self.hideIndicatorView()
                        self.showAlert("Error", " Can't get user information. Please try again.")
                    }
                }
            }


        }
    }
    
    @objc func btnCallClicked(_ sender: UIButton) {
        self.showIndicatorView()
        
        if isFiltering, filteredContacts.count > 0 {
            let contact = filteredContacts[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = false
            vc.recieverNumber = contact.number
            vc.name = contact.name ?? ""
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: "", friend: contact.userId ?? "") { (user, success) in
                if success {
                    self.hideIndicatorView()
                    guard let user = user else {
                        return
                    }
                    vc.userDetails = user
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
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
            self.getUserDetail(cnic: contact.ContactsCnic ?? "", friend: "") { (user, success) in
                if success {
                    
                    self.hideIndicatorView()
                    guard let user = user else {
                        return
                    }
                    vc.userDetails = user
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
            
        }
    }
    
    //MARK:- CHECK USER FRIEND STATUS : -
    func checkUSERFRIEND(num: String) -> Bool {
        if num.isEmpty { return false }
        return CurrentSession.shared.friends.first(where: { (num.comparePhoneNumber(number: $0.number) || num == $0.email ) }) != nil
    }
    
    
    @objc func btnVideoClicked(_ sender: UIButton) {
        self.showIndicatorView()
        
        if isFiltering {
            let contact = filteredContacts[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = true
            vc.recieverNumber = contact.number
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: "", friend: contact.userId ?? "") { (user, success) in
                if success {
                    self.hideIndicatorView()
                    guard let user = user else {
                        return
                    }
                    vc.userDetails = user
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
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
            self.getUserDetail(cnic: contact.ContactsCnic ?? "", friend: "") { (user, success) in
                if success {
                    self.hideIndicatorView()
                    guard let user = user else {
                        return
                    }
                    vc.userDetails = user
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.hideIndicatorView()
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
            self.userListQuery?.userIdsFilter = [userMd!.uniqueContact]
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

                    SVProgressHUD.dismiss()
                    if let error = error {
                        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
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
    
    private func searchByKeyword(_ keyword: String?) {
        isFiltering = true
        guard let searchText = keyword else {
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
        
        self.showIndicatorView()
        self.searchProfession(byCnic: searchText) { (users, success) in
            self.hideIndicatorView()
            if success {
                self.filteredContacts = users ?? []
                self.isFiltering = self.filteredContacts.count > 0
                if self.isFiltering == false {
                    self.showAlert("Not user found for this fone id.")
                }
                self.updateView()
            } else {
                self.showAlert("Something went wrong. Please try again later.")
            }
        }
    }
    func setCacheData() {
        var USER_ID: String?
        var USER_NAME: String?
        var mobileNumber: String = ""
        if let loginToken = UserDefaults.standard.string(forKey: "AccessToken"), !loginToken.isEmpty {
            do {
                let jwt = try decode(jwtToken: loginToken)
                print(jwt)
                USER_ID = jwt["uid"] as? String
                mobileNumber = jwt["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] as? String ?? ""
                if !(mobileNumber.isEmpty)
                {
                    mobileNumber.remove(at: mobileNumber.startIndex)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
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
            var headers = [String:String]()
            headers = ["AuthKey": "#phone@me!Us+O0"]
            headers = ["Content-Type": "application/json"]
            ServerCall.makeCallWitoutFile(checkCICN  + "/\(mobileNumber)", params: [:], type: Method.GET, currentView: nil, header: headers) { (response) in
                
                if let json = response {
                    let cnic = json.rawString()
                    self.getUserProfile(cnic: cnic ?? "") { model, success in
                        let user = User()
                        user.userId = model?.userId
                        user.name = model?.name
                        user.aboutme = model?.aboutme
                        user.coutryCode = model?.countryCode
                        user.mobile = model?.phoneNumber
                        user.email = model?.email
                        user.numberWithOutCode = model?.mobileNumberWithoutCode
                        
                        if let userProfileData = try? PropertyListEncoder().encode(user) {
                            UserDefaults.standard.set(userProfileData, forKey: key_User_Profile)
                            UserDefaults.standard.synchronize()
                            if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                                print(userProfileData)
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
                            }
                        }
                    }
                }
            }
        }
    }
}

extension FriendTabVC: UISearchBarDelegate {

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchByKeyword(searchBar.text)
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
            self.isFiltering = false
            self.filteredContacts.removeAll()
            self.updateView()
        }
    }
}

extension FriendTabVC: GroupChannelsUpdateListDelegate {

}

