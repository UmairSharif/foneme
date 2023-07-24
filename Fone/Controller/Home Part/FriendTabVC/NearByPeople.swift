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
import SVProgressHUD
import GoogleMobileAds

class NearByPeople : UIViewController
{
    //IBoutlet and Variables
    @IBOutlet weak var contactTVC: UITableView!
    @IBOutlet weak var discoverPeopleNearBy: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!

    /// Private variables
    private var friendList: [FriendList] = []
    private var searchedByProfessionContacts = [FriendList]()
    private var isSearchingByProfession = false
    private var users: [SBDUser] = []
    private var userListQuery: SBDApplicationUserListQuery?
    private var userDetails: UserDetailModel?
    private var interstitial: GADInterstitialAd?
    static let interstitial = "ca-app-pub-0169736027593374/2447488069"
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInterstitialAd(owner: self)
        self.setupSearchBarDelegate()
        self.discoverPeopleNearBy.layer.cornerRadius = 12.0;
        self.discoverPeopleNearBy.clipsToBounds = true
        self.loadNearyByPeopleAPI()
    }
    func loadInterstitialAd(owner:UIViewController){
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID:NearByPeople.interstitial,
                               request: request, completionHandler: { [self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            interstitial = ad
            interstitial?.fullScreenContentDelegate = owner as? any GADFullScreenContentDelegate
            showAdMobInterstitial(owner: self)

        })
    }
    
    func showAdMobInterstitial(owner:UIViewController) {
        if interstitial != nil {
            interstitial?.present(fromRootViewController: owner)

        } else {
            print("Ad wasn't ready")
        }
    }
    private func setupSearchBarDelegate() {
        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    private func showIndicatorView() {
        SVProgressHUD.show()
    }

    private func hideIndicatorView() {
        SVProgressHUD.dismiss()
        self.activityIndicator.isHidden = true
    }
    
    func loadNearyByPeopleAPI() {

        self.showIndicatorView()

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

        ServerCall.makeCallWitoutFile(nearbyContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in

            if let json = response {
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

            } else {
                self.hideIndicatorView()
            }
        }
    }
    
    func getUserStatus() {
        if friendList.count > 0 {
            let ids: [String] = friendList.map { $0.number ?? "" }
            let query = SBDMain.createApplicationUserListQuery()
            query?.userIdsFilter = ids
            query?.loadNextPage(completionHandler: { (users, error) in
                self.hideIndicatorView()
                guard error == nil else {
                    //Utils.showAlertController(error: error!, viewController: self)
                    self.contactTVC.reloadData()
                    return
                }

                if let users = users, users.count > 0 {
                    self.users = users
                }
                self.contactTVC.reloadData()
            })
        }
    }
    
    @objc func btnCallClicked(_ sender: UIButton) {
        SVProgressHUD.show()
        self.view.isUserInteractionEnabled = false

        if friendList.count > 0 {
            let contact = friendList[sender.tag]
            let vc = UIStoryboard().loadVideoCallVC()
            vc.isVideo = false
            vc.recieverNumber = contact.number
            vc.name = contact.name ?? ""
            vc.userImage = contact.userImage
            vc.DialerFoneID = contact.ContactsCnic ?? ""
            self.getUserDetail(cnic: contact.ContactsCnic ?? "", friend: "") { (user, success) in
                if success {
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    guard let user = user else {
                        return
                    }
                    vc.userDetails = user
                    vc.modalPresentationStyle = .fullScreen
                    NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                    self.present(vc, animated: true, completion: nil)
                } else {
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }

        }
    }
    
    @objc func btnVideoClicked(_ sender: UIButton) {
        SVProgressHUD.show()
        self.view.isUserInteractionEnabled = false

        let contact = friendList[sender.tag]
        let vc = UIStoryboard().loadVideoCallVC()
        vc.isVideo = true
        vc.recieverNumber = contact.number
        vc.userImage = contact.userImage
        vc.DialerFoneID = contact.ContactsCnic ?? ""
        self.getUserDetail(cnic: contact.ContactsCnic ?? "", friend: "") { (user, success) in
            if success {
                SVProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
                guard let user = user else {
                    return
                }
                vc.userDetails = user
                vc.modalPresentationStyle = .fullScreen
                NotificationHandler.shared.currentCallStatus = CurrentCallStatus.OutGoing
                self.present(vc, animated: true, completion: nil)
            } else {
                SVProgressHUD.dismiss()
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
    
    //MARK:- CHECK USER FRIEND STATUS : -
    func checkUSERFRIEND(num: String) -> Bool {
        if num.isEmpty { return false }
        return CurrentSession.shared.friends.first(where: { num.comparePhoneNumber(number: $0.number) }) != nil
    }
    
    @IBAction func backToView()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func updateView() {
        // if there is data for table view then show table view
        if (isSearchingByProfession && searchedByProfessionContacts.count > 0) || (!isSearchingByProfession && friendList.count > 0) {
            contactTVC.isHidden = false
            //inviteView.isHidden = true
            contactTVC.reloadData()
        } else {
            contactTVC.isHidden = true
            //inviteView.isHidden = true//false
        }
    }
    
    // MARK:- API Calling
    private func searchByProfession(_ keyword: String?) {
        isSearchingByProfession = true
        guard let searchText = keyword else {
            isSearchingByProfession = false
            updateView()
            return
        }
        
        if searchText == "" {
            isSearchingByProfession = false
            self.searchedByProfessionContacts.removeAll()
            updateView()
            return
        }

        self.showIndicatorView()
        self.searchProfession(byCnic: searchText) { (users, success) in
            self.hideIndicatorView()
            if success {
                self.searchedByProfessionContacts = users ?? []
                self.isSearchingByProfession = self.searchedByProfessionContacts.count > 0
                if self.isSearchingByProfession == false {
                    self.showAlert("Not user found for this fone id.")
                }
                self.updateView()
            } else {
                self.showAlert("Something went wrong. Please try again later.")
            }
        }
    }
}

extension NearByPeople: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isSearchingByProfession) {
            return searchedByProfessionContacts.count
        }
        return friendList.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocalContactTVC
        var contact = FriendList()
        //let contact = friendList[indexPath.row]
        
        if (isSearchingByProfession) {
            contact = searchedByProfessionContacts[indexPath.row]
        } else {
            contact = friendList[indexPath.row]
        }
        
        cell.contact = contact
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

        cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.cellContentView.layer.borderWidth = 1.0
        cell.cellContentView.layer.cornerRadius = 12.0
        return cell
        
        
        
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SVProgressHUD.show()
        self.view.isUserInteractionEnabled = false

        if friendList.count > 0
        {
            var contact = FriendList()
            if (isSearchingByProfession && searchedByProfessionContacts.count > 0) {
                contact = searchedByProfessionContacts[indexPath.row]
            } else {
                contact = friendList[indexPath.row]
            }
            
            let vc = UIStoryboard().loadUserDetailsVC()
            guard let contactCnic = contact.ContactsCnic else {
                SVProgressHUD.dismiss()
                self.view.isUserInteractionEnabled = true
                return
            }
            self.getUserDetail(cnic: contactCnic, friend: "") { (user, success) in
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
                    SVProgressHUD.dismiss()

                    vc.userDetails = user!
                    let nav = UINavigationController(rootViewController: vc)
                    nav.navigationBar.isHidden = true
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                } else {
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    self.showAlert("Error", " Can't get user information. Please try again.")
                }
            }
        }
    }
}

extension NearByPeople: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchByProfession(searchBar.text)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchingByProfession = false
        searchBar.text = ""
        self.view.endEditing(true)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchingByProfession = false
        guard let firstSubview = searchBar.subviews.first else { return }
        firstSubview.subviews.forEach {
            ($0 as? UITextField)?.clearButtonMode = .never
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearchingByProfession = false
        self.view.endEditing(true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.isSearchingByProfession = false
            self.searchedByProfessionContacts.removeAll()
            self.updateView()
        }
    }
}

extension NearByPeople: GroupChannelsUpdateListDelegate {

}
extension NearByPeople: GADFullScreenContentDelegate  ,GADAdLoaderDelegate{
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("adWillPresentFullScreenContent")
    }
    
    func adWillPresentFullScreenContent( ad: GADFullScreenPresentingAd) {
        print("adWillPresentFullScreenContent")
    }

    func ad( ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("didFailToPresentFullScreenContentWithError")
    }

    func adDidDismissFullScreenContent( ad: GADFullScreenPresentingAd) {
        print("adDidDismissFullScreenContent")

            //AdMobManager.shared.loadInterstitialAd(owner: self)
        self.loadInterstitialAd(owner: self)

        }



  //  }

    func adDidRecordImpression( ad: GADFullScreenPresentingAd) {
        print("adDidRecordImpression")
    }

    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        print("adDidRecordClick")
    }
}
