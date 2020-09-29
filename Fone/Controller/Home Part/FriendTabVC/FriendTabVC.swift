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

class FriendTabVC: UIViewController {
    
    //IBoutlet and Variables
    @IBOutlet weak var contactTVC : UITableView!
    @IBOutlet weak var searchBar : UISearchBar!
    @IBOutlet weak var inviteView : UIView!
    @IBOutlet weak var activityIndicator : NVActivityIndicatorView!
    var contactArray = [Contacts]()
    var friendList = [FriendList]()
    var filteredContacts = [FriendList]()
    var isFiltering = false
    let network = NetworkManager.sharedInstance
    var netStatus : Bool?
    var refreshControl = UIRefreshControl()
    
    
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
        if let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data {
            if let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) {
                if contacts.count > 0{
                    showLoader = false
                }
            }
        }
        
        
        // Get Contacts Friend List
        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: showLoader)
        network.reachability.whenReachable = { reachability in
            
            self.netStatus = true
            UserDefaults.standard.set("Yes", forKey: "netStatus")
            UserDefaults.standard.synchronize()
            
            // Get Contacts Friend List
            self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: showLoader)
        }
        
        network.reachability.whenUnreachable = { reachability in
            
            self.netStatus = false
            UserDefaults.standard.set("No", forKey: "netStatus")
            UserDefaults.standard.synchronize()
            let alertController = UIAlertController(title: "No Internet!", message: "Please connect your device to the internet.", preferredStyle: .alert)
            
            let action1 = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
                
            }
            
            alertController.addAction(action1)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        // Code to refresh table view
        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.getSubscriptionsForCustomer()
        isFiltering = false
        searchBar.text = ""
        loadDataFromCache()

    }
    
    func loadDataFromCache() {
        guard let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data else {
            return
        }
        guard let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) else {
            return
        }
        self.friendList.removeAll()
        
        if contacts.count == 0
        {
            self.inviteView.isHidden = false
        }
        else
        {
            self.inviteView.isHidden = true
        }
        for items in contacts
        {
            let dict = items.dictionary
            
            let number = dict?["ContactsNumber"]?.string ?? ""
            let name = dict?["ContactsName"]?.string ?? ""
            let userImage = dict?["Image"]?.string ?? ""
            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""
            let getData = FriendList(name: name, number: number,userImage : userImage,ContactsCnic: ContactsCnic)
            self.friendList.append(getData)
            
            
        }
        contactTVC.reloadData()
    }
    
    //    func removeSpecialCharsFromString(text: String) -> String {
    //        let okayChars = Set("1234567890+")
    //        return text.filter {okayChars.contains($0) }
    //    }
    
    func sendContactAPI(contactsArray : [Contacts], showLoader: Bool)
    {
        if showLoader {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        }else{
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
        
        //var result = [String: Any]()
        var userId : String?
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
            }
        }
        
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        var contactList = [[String:Any]]()
        
        for contact in contactsArray
        {
            
            let number = contact.number?.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            
            let parameter = ["ContactsName": contact.name ?? "",
                             "ContactsNumber": number ?? ""
            ]
            
            contactList.append(parameter)
        }
        
        //        let parameter = ["ContactsName": "Saru",
        //                "ContactsNumber": "+919638529701"
        //            ]
        //
        //         contactList.append(parameter)
        
        
        let parameters = [
            
            "UserId" : userId ?? "",
            "Contacts": contactList
            
            ] as [String:Any]
        // print(parameters)
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(saveContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            self.refreshControl.endRefreshing()
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            
            if let json = response {
                // print(json)
                let statusCode = json["StatusCode"].string ?? ""
                if statusCode == "401" {
                    var mobilenumber : String?
                    
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
                        
                        for items in contacts ?? [] {
                            let dict = items.dictionary
                            let number = dict?["ContactsNumber"]?.string ?? ""
                            
                            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""
                            
                            if (number.count > Min_Contact_Number_Lenght) && !(ContactsCnic.isEmpty) {
                                
                                midConatct.append(items)
                            }
                        }
                        
                        UserDefaults.standard.set(try? PropertyListEncoder().encode(midConatct), forKey: "Contacts")
                        UserDefaults.standard.synchronize()
                        if self.friendList.count == 0 {
                            if let chatvc = self.tabBarController?.viewControllers?[2] as? GroupChannelsViewController {
                                if chatvc.isViewLoaded {
                                    chatvc.refreshChannelList()
                                }
                            }
                        }
                        self.friendList.removeAll()
                    }
                }
                let contacts = json["Contacts"].array
                if contacts?.count == 0
                {
                    guard let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data
                        
                        else {
                            self.inviteView.isHidden = false
                            return
                    }
                    guard let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) else {
                        self.inviteView.isHidden = false
                        return
                    }
                    //                    if contacts.count > 0 {
                    self.inviteView.isHidden = true
                    //                    }
                    //                    else {
                    //                        self.inviteView.isHidden = false
                    //                    }
                    
                }
                else
                {
                    self.inviteView.isHidden = true
                    self.loadDataFromCache()
                }
            }else {
                
                var mobilenumber : String?
                
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
    
    func getAccessTokenAPI(mobileNumber : String)
    {
        
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let parameters : [String : Any] = [
            "username": mobileNumber,
            "password" : "123456",
            "client_id" : ClientId,
            "grant_type" : "password"
        ]
        
        Alamofire.request(getAccessTokenUrl, method: .post, parameters: parameters, encoding:  URLEncoding.httpBody, headers: headers).responseJSON { (response:DataResponse<Any>) in
            
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
                self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: false)
                
            case.failure(let error):
                print("Not Success",error)
                //self.errorAlert("\(error)")
                var mobilenumber : String?
                
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
    
    @IBAction func inviteBtnTapped(_ sender : UIButton)
    {
        //Set the default sharing message.
        let message = "Fone App"
        //Set the link to share.
        if let link = NSURL(string: "")
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    func getSubscriptionsForCustomer(){
        
        var mobilenumber = ""
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                mobilenumber = user.mobile ?? ""
            }
        }
        if mobilenumber == "+18888888888" {
            return;
        }
       // mobilenumber = "9199876543"
        let header  = ["Content-Type": "application/json"]
        // APIManager.sharedManager.request(getBrainTreePlans, method: Alamofire.HTTPMethod.post, parameters: nil, encoding:  JSONEncoding.default,
        let apiURL = "\(getSubscriptions_Customer)\(mobilenumber)"
        
        ServerCall.makeCallWitoutFile(apiURL, params: nil, type: Method.POST, currentView: nil, header: header) { (response) in
            let isAvilabel = response?["response"] ?? false
            print(isAvilabel)
            print(response)
            if isAvilabel == true {
                let subscriptionArr = response?["subscriptions"].arrayObject
                let subscritpionobject = subscriptionArr?.last as? [String:Any]
                let subDateobject = subscritpionobject?["lastdate"] as? [String:Any]
                let dateExpiry = subDateobject?["date"] as? String ?? ""
                print("dateExpiry = \(dateExpiry)")
                let dateObj = Utility.sharedInstance.getDateFromString(dateExpiry, "yyyy-MM-dd HH:mm:ss") ?? Date()
                let diffreance = Utility.sharedInstance.diffranceBetweenDays(formatedStartDate: dateObj)
                print("diffreance = \(diffreance)")

                let subscriptionStatus = subscritpionobject?[SubscriptionStatus] as? String  ?? ""
                let subscriptionId = subscritpionobject?[SubscriptionId] as? String  ?? ""
                let subscriptionPlan = subscritpionobject?[SubscriptionPlan] as? String
                UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)
                UserDefaults.standard.set(subscriptionPlan, forKey: SubscriptionPlan)
                UserDefaults.standard.set(subscriptionId, forKey: SubscriptionId)
                
                if (subscriptionStatus.lowercased() != "active") && (diffreance < 0) {
                self.openPlanListView()
                }

            }else {
                UserDefaults.standard.set("", forKey: SubscriptionStatus)
                UserDefaults.standard.set("", forKey: SubscriptionPlan)
                self.openPlanListView()
            }
           // self.openPlanListView()

        }
        
    }
    
    func openPlanListView() {
       
        let desiredVC = UIStoryboard().loadPlanVC()
        desiredVC.modalPresentationStyle = .fullScreen
        topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)

        //topViewController
        
    }
    
}


extension FriendTabVC :  UITableViewDelegate,UITableViewDataSource
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
        
        if isFiltering {
            
            if filteredContacts.count > 0 {
                let contact = filteredContacts[indexPath.row]
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.number
                cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            }else {
                return UITableViewCell()
            }
        }
        else
        {
            if friendList.count > 0
            {
                let contact = friendList[indexPath.row]
                
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.number
                cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            }else {
                return UITableViewCell()
            }
        }
        cell.btnCall.tag = indexPath.row
        cell.btnCall.addTarget(self, action:#selector(self.btnCallClicked(_:)) , for: .touchUpInside)
        cell.btnVideo.tag = indexPath.row
        cell.btnVideo.addTarget(self, action:#selector(self.btnVideoClicked(_:)) , for: .touchUpInside)
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
            vc.delegate = self
            self.getUserDetail(cnic: "", friend: contact.userId!) { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
        else if friendList.count > 0
        {
            let contact = friendList[indexPath.row]
            let vc = UIStoryboard().loadUserDetailsVC()
            vc.delegate = self
            self.getUserDetail(cnic: contact.ContactsCnic!, friend: "") { (user, success) in
                if success {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                    vc.userDetails = user!
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    @objc func btnCallClicked(_ sender:UIButton){
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
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
        else if friendList.count > 0{
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
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
            
        }
    }
    
    @objc func btnVideoClicked(_ sender:UIButton){
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
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
            
        }
        else{
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
                }else{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.view.isUserInteractionEnabled = true
                }
            }
            
        }
    }
}

extension FriendTabVC : UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isFiltering = true
        guard let searchText = searchBar.text else {
            isFiltering = false
            return
        }
        if searchText == "" {
            isFiltering = false
            self.filteredContacts.removeAll()
            self.contactTVC.reloadData()
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
                self.contactTVC.reloadData()
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
        
    }
    
}


extension FriendTabVC : AddFriendDelegate {
    func addFriendRefresh() {
        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray, showLoader: false)
    }
    
    
}
