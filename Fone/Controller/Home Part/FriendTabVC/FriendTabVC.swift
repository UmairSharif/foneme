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
        
      
    override func viewDidLoad() {
    
        super.viewDidLoad()

        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
        
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
        

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
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
             
             let getData = FriendList(name: name, number: number,userImage : userImage)
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
            
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                       "Authorization" : "bearer " + loginToken!]
            
        ServerCall.makeCallWitoutFile(saveContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true


            if let json = response {
                
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
                }
                
                print(json)
                let contacts = json["Contacts"].array
                if contacts!.count > 0 {
//                    UserDefaults.standard.set(json["Contacts"], forKey: "ContactsTest")
                    
                    UserDefaults.standard.set(try? PropertyListEncoder().encode(contacts), forKey: "Contacts")
                    UserDefaults.standard.synchronize()
                    if self.friendList.count == 0 {
                        if let chatvc = self.tabBarController?.viewControllers?[2] as? GroupChannelsViewController {
                            if chatvc.isViewLoaded {
                                chatvc.refreshChannelList()
                            }
                        }
                    }
                }
                
                self.friendList.removeAll()

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
                    for items in contacts ?? []
                    {
                        let dict = items.dictionary
                            
                        let number = dict?["ContactsNumber"]?.string ?? ""
                        let name = dict?["ContactsName"]?.string ?? ""
                        let userImage = dict?["Image"]?.string ?? ""
                        
                        let getData = FriendList(name: name, number: number,userImage : userImage)
                        self.friendList.append(getData)
                    }
                    

                    //Table View Reload
                    self.contactTVC.reloadData()
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
                
            let contact = filteredContacts[indexPath.row]
                
            cell.nameLbl.text = contact.name
            cell.phoneLbl.text = contact.number
            cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        else
        {
            if friendList.count != 0
            {
                let contact = friendList[indexPath.row]
                
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.number
                cell.userImage.sd_setImage(with: URL(string: contact.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            }
        }
            
        return cell
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        if isFiltering {
                
            let contact = filteredContacts[indexPath.row]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.recieverNumber = contact.number
            vc.userImage = contact.userImage
            self.present(vc, animated: true, completion: nil)
        }
        else
        {
            let contact = friendList[indexPath.row]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.recieverNumber = contact.number
            vc.userImage = contact.userImage
            self.present(vc, animated: true, completion: nil)
        
        }
    }
}

extension FriendTabVC : UISearchBarDelegate {
        
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isFiltering = true
            
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
        guard let searchText = searchBar.text else {
            isFiltering = false
            return
        }
            
        filteredContacts = friendList.filter({
        return ($0.name?.lowercased().contains(searchText.lowercased()))!
            })
            
        isFiltering = filteredContacts.count > 0
        self.contactTVC.reloadData()
    }
}

