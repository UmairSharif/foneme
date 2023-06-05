//
//  NearByPeople.swift
//  Fone
//
//  Created by Curiologix on 25/02/2022.
//  Copyright © 2022 Fone.Me. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView
import SwiftyJSON
import SendBirdSDK

class NearByPeople : UIViewController
{
    //IBoutlet and Variables
    @IBOutlet weak var contactTVC: UITableView!
    @IBOutlet weak var discoverPeopleNearBy: UIView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    var friendList = [FriendList]()
    var users = [SBDUser]()
    var userListQuery: SBDApplicationUserListQuery?
    var userDetails: UserDetailModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.discoverPeopleNearBy.layer.cornerRadius = 12.0;
        self.discoverPeopleNearBy.clipsToBounds = true
        self.loadNearyByPeopleAPI()
    }
    
    func loadNearyByPeopleAPI()
    {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false

        var userId: String = CurrentSession.shared.user?.userId ?? ""
        let loginToken = CurrentSession.shared.accessToken

        var parameters = [
            "UserId": userId,
            "Latitude": String(GLBLatitude), //"33.738132",
            "Longitude": String(GLBLongitude), //"72.798002",
            "Radius":"1600",
            "Unit":"KM"
        ] as [String: Any]

        print(parameters)
        print(nearbyContactUrl)
        var headers = [String: String]()
        headers = ["Content-Type": "application/json",
            "Authorization": "bearer " + loginToken!]

        ServerCall.makeCallWitoutFile(nearbyContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in

            //self.refreshControl.endRefreshing()
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
                    return
                }

                ///  print(json)
                if let contacts = json["UserAboutMeData"].array {
                    if contacts.count > 0 {
                        var midConatct = [SwiftyJSON.JSON]()

                        for var items in contacts
                        {
                            let dict = items.dictionary
                            var number = dict?["ContactsNumber"]?.string ?? ""
                            number = number.replacingOccurrences(of: " ", with: "")
                            let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""

                            //let json = JSON(number)
                            items["ContactsNumber"] = JSON(number)
                            //if (number.count > Min_Contact_Number_Lenght) && !(ContactsCnic.isEmpty) {
                                midConatct.append(items)
                           // }
                        }

                        midConatct.forEach { contact in
                            let dict = contact.dictionary
                            var contact = FriendList()
                            contact.number = dict?["ContactsNumber"]?.string ?? ""
                            contact.name = dict?["ContactsName"]?.string ?? ""
                            contact.ContactsCnic = dict?["FoneMe"]?.string ?? ""
                            contact.userImage = dict?["ImageURL"]?.string ?? ""
                            //contact.ContactsCnic = dict?["ContactsCnic"]?.string ?? ""
                            contact.userId = dict?["ContactsVT"]?.string ?? ""
                            contact.distance = dict?["Distance"]?.string ?? ""
                            self.friendList.append(contact)
                        }
                    }
                }
                
                self.getUSERSTATUS()
                self.contactTVC.reloadData()
            } else {

                var mobilenumber: String?

                if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
                    print(userProfileData)
                    if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                        mobilenumber = user.mobile
                    }
                }
                //self.getAccessTokenAPI(mobileNumber: mobilenumber ?? "")
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
            })
        }
    }
    
    @objc func btnCallClicked(_ sender: UIButton) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

        if friendList.count > 0 {
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
    
    @objc func btnVideoClicked(_ sender: UIButton) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

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
    
    //MARK:- CHECK USER FRIEND STATUS : -
    func checkUSERFRIEND(num: String) -> Bool {
        if num.isEmpty { return false }
        return CurrentSession.shared.friends.first(where: { num.comparePhoneNumber(number: $0.number) }) != nil
    }
    
    @IBAction func backToView()
    {
        self.navigationController?.popViewController(animated: true)
    }
}

extension NearByPeople: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocalContactTVC
//        cell.btnCall.isHidden = true
//        cell.btnVideo.isHidden = true
        
        if friendList.count > 0
        {
            let contact = friendList[indexPath.row]
            cell.nameLbl.text = contact.name
            cell.phoneLbl.text = contact.ContactsCnic?.cnicToLink
            cell.distance.text = contact.distance
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
        
//        cell.btnCall.tag = indexPath.row
//        cell.btnCall.addTarget(self, action: #selector(self.btnCallClicked(_:)), for: .touchUpInside)
//        cell.btnVideo.tag = indexPath.row
//        cell.btnVideo.addTarget(self, action: #selector(self.btnVideoClicked(_:)), for: .touchUpInside)
        
        
        cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.cellContentView.layer.borderWidth = 1.0
        cell.cellContentView.layer.cornerRadius = 12.0
        return cell
        
        
        
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.activityIndicator.startAnimating()
        self.activityIndicator.isHidden = false
        self.view.isUserInteractionEnabled = false

        if friendList.count > 0
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
}

extension NearByPeople: GroupChannelsUpdateListDelegate {

}
