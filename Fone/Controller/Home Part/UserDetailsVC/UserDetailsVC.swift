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
import SVProgressHUD
import Alamofire

// @rackuka: introduce isFriendAdded - app specific property designating if button should let add friend OR depict that the friend is added

class UIFriendButton: UIButton {
    var isFriendAdded: Bool = false {
        didSet {
            self.isSelected = isFriendAdded
            self.isUserInteractionEnabled = !isFriendAdded
        }
    }
}
class UserDetailsVC: UIViewController {

    //MARK:-Outlets

    @IBOutlet weak var interestCollectionView: UICollectionView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblVideoCall: UILabel!
    @IBOutlet weak var lblChat: UILabel!
    @IBOutlet weak var lblVoiceCall: UILabel!
    @IBOutlet weak var btnVideoCall: UIButton!
    @IBOutlet weak var btnCall: UIButton!
    @IBOutlet weak var btnChat: UIButton!
    @IBOutlet weak var btnFriend: UIFriendButton!
 //   @IBOutlet weak var btnFonemeID: UIButton!
    @IBOutlet weak var foneId: UILabel!
    
    @IBOutlet weak var LbluserName: UILabel!
    @IBOutlet weak var lblAdress: UILabel!
    @IBOutlet weak var UserImage: UIImageView!
    @IBOutlet weak var lblAboutme: UILabel!
    @IBOutlet weak var lblprofession: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    
    //@IBOutlet weak var viewLoc: UIView!
    //@IBOutlet weak var viewDes: UIView!
   // @IBOutlet weak var viewLinks: UIView!
    @IBOutlet weak var lbLinks: UILabel!
    @IBOutlet weak var lblLinkView: UIView!
    
    var userDetails: UserDetailModel?
    var userListQuery: SBDApplicationUserListQuery?
    var isSearch = false
    var isFromLink = false
    var FoneID = ""
    var arrPic = [String]()
    var interestIds = [Int]()
    var tempInterests = [InterestsSubCategory]()
    var finalInterests = [InterestsSubCategory]()
    //107,32
    override func viewDidLoad() {
        super.viewDidLoad()
        lblLinkView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        lblLinkView.layer.borderWidth = 1.0
        lblLinkView.layer.cornerRadius = 12.0
        lblLinkView.backgroundColor = .clear
        /*
        viewDes.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        viewDes.layer.borderWidth = 1.0
        viewDes.layer.cornerRadius = 12.0
        
        viewLinks.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        viewLinks.layer.borderWidth = 1.0
        viewLinks.layer.cornerRadius = 12.0
         */
        
    }
    override func viewWillAppear(_ animated: Bool) {
    
        if isFromLink == true {
            SVProgressHUD.show()
            isFromLink = false

            self.getUserDetail(cnic: FoneID, friend: "") { (userModel, success) in
                if success {
                    SVProgressHUD.dismiss()
                    self.userDetails = userModel
                    self.UpdateDetails()
                    self.getProfilePreference()
                } else {
                    self.showAlert("Error"," Can't get user information. Please try again.")
                }
            }
        }
        else {
            
            self.UpdateDetails()
            self.getProfilePreference()
        }

    }

    //MARK:- Update Details
    func UpdateDetails() {
        var isContactAdded = false
        if let contact = userDetails?.uniqueContact {
            if let _ = CurrentSession.shared.friends.first(where: { (contact.comparePhoneNumber(number: $0.number)) || contact == $0.email }) {
                isContactAdded = true
            }
        }
        
        self.btnFriend.isFriendAdded = isContactAdded
        self.UserImage.sd_setImage(with: URL(string: userDetails?.imageUrl ?? ""), placeholderImage: UIImage(named: "ic_profile"))
        self.LbluserName.text = userDetails?.name ?? ""
       // self.btnFonemeID.setTitle(userDetails?.cnic?.cnicToLink, for: .normal)
        self.lblAboutme.text = self.userDetails?.aboutme ?? "Hey there! I am using Fone Messenger."
        self.lblprofession.text = self.userDetails?.profession ?? ""
        //viewLoc.isHidden = true

        self.lblAdress.text = ""
        if self.userDetails?.location != "" && self.userDetails?.location != nil && self.userDetails?.location != "null"
        {
            //viewLoc.isHidden = false
            self.lblAdress.text = self.userDetails?.location ?? ""
        }
        lbLinks.text = "fone.me/\(userDetails!.cnic!)"

    }
    
    func getProfilePreference() {
        
        let userID = self.userDetails?.userId
        let url = "\(getProfilePic)?UserId=\(userID ?? "")"
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default)
                .responseJSON { response in

                    switch response.result {

                    case .success(let json):
                        print(json)
                       
                        let data = json as! [String:Any]
                        let profileData = data["UserProfileData"] as? [String:Any]
                        self.arrPic = profileData?["Urls"] as? [String] ?? []
                        let interestIds = profileData?["PersonalInterestId"] as? String ?? ""
                        self.interestIds = interestIds.components(separatedBy: ",").compactMap { Int($0) }
                        self.getInterests()
                        self.collectionView.delegate = self
                        self.collectionView.dataSource = self
                    case .failure(let error):
                        print(error)
                    }
            }
    }

    @IBAction func btnClickBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func btnCopyBranchLink(_ sender: UIButton) {
        UIPasteboard.general.string = sender.titleLabel?.text ?? ""
        self.showToast(controller: self, message: "Fone id copied", seconds: 1)
    }

    @IBAction func btnLinksTapped(_ sender: Any) {
        if let user = self.userDetails {
            let vc = UIStoryboard().socialLinksVC()
            vc.user = user
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.showAlert("", "Oops!! Can't get user detail. Please try again later!")
        }
    }

    @IBAction func btnClickFriend(_ sender: UIButton) {
        SVProgressHUD.show()
        self.addFirend(foneId: (userDetails?.cnic)!, friendId: (userDetails?.userId)!, url: ("\(userDetails?.cnic?.cnicToLink ?? "")")) { (user, success) in
            if success {
                self.getContacts { finished in
                    SVProgressHUD.dismiss()
                    // @rackuka: reflect state change - now friend has been added
                    self.btnFriend.isFriendAdded = true
                    self.showAlert("Friend add successfully")
                }
            } else {
                SVProgressHUD.dismiss()
                self.showAlert("\(self.userDetails?.name ?? "User") is already your friend.")
            }
        }
    }

    @IBAction func btnClickVoiceCall(_ sender: UIButton) {

        // UserDefaults.standard.set(subscriptionStatus, forKey: SubscriptionStatus)

//        let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
//        if subscription.lowercased() == "active" {

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
//        } else {
//
//            self.show(message: "Please subscribe for app to use this feature.")
//        }

    }

    @IBAction func btnClickChat(_ sender: UIButton) {
        if let userDetail = self.userDetails,
            let query = SBDMain.createApplicationUserListQuery() {
            query.limit = 100
            query.userIdsFilter = [userDetail.uniqueContact]

            SVProgressHUD.show()
            query.loadNextPage {[weak self] users, error in
                guard let sSelf = self else { return }
                if let error = error {
                    SVProgressHUD.dismiss()
                    sSelf.showAlert("Error", error.localizedDescription)
                    return
                }
                if let users = users, let selectedUser = users.first {
                    SBDGroupChannel.createChannel(with: [selectedUser], isDistinct: true) {[weak self] channel, error in
                        guard let sSelf = self else { return }
                        SVProgressHUD.dismiss()
                        if let error = error {
                            sSelf.showAlert("Error", error.localizedDescription)
                            return
                        }

                        DispatchQueue.main.async {
                            let vc = UIStoryboard(name: "GroupChannel", bundle: nil).instantiateViewController(withIdentifier: "GrouplChatViewController") as! GroupChannelChatViewController
                            //vc.delegate = sSelf
                            vc.userDetails = sSelf.userDetails
                            vc.channel = channel
                            let nav = UINavigationController(rootViewController: vc)
                            nav.modalPresentationStyle = .fullScreen
                            sSelf.present(nav, animated: true, completion: nil)
                        }
                    }
                } else {
                    SVProgressHUD.dismiss()
                    sSelf.showAlert("Error", "Sorry, We couldn't start this conversation due to user not found. Please contact administrator for more information.")
                }
            }
        }
    }

    @IBAction func btnClickVideoCall(_ sender: UIButton) {
//        let subscription = UserDefaults.standard.object(forKey: SubscriptionStatus) as? String ?? ""
//      if subscription.lowercased() == "active" {
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
//              } else {
//
//            self.show(message: "Please subscribe for app to use this feature.")
//        }
    }

    func show(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UserDetailsVC: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return self.arrPic.count
        }else {
            return self.interestIds.count
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UserDetailImagesCell
            if let url = URL(string: self.arrPic[indexPath.row]) {
                cell.userImage.sd_setImage(with: url)
            }
            return cell
        }else {
            let interest = self.finalInterests[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! UserDetailInterestCell
            cell.interestName.text = interest.name
            return cell
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            let yourWidth = (collectionView.bounds.width)
            let yourHeight = CGFloat(418)
            return CGSize(width: yourWidth, height: yourHeight)
        }else {
            let yourWidth = (collectionView.bounds.width/5)
            let yourHeight = CGFloat(35)
            return CGSize(width: yourWidth, height: yourHeight)
        }

    }

}
extension UserDetailsVC {
    func getInterests(){
        Alamofire.request("https://test.zwilio.com/api/account/v1/getPersonalcategories",method: .get).responseJSON { response in
            
            if response.result.isSuccess {
                let value:JSON = JSON(response.result.value!)
                self.parseInterets(json: value["Categories"])
            }else {
                print("error")
            }
        }
    }
    func parseInterets(json:JSON) {
        for item in json {
            let subCat = item.1["SubCategoryList"].array ?? []
            for category in subCat {
                let id = category["Id"].int ?? 0
                let SubCategory = category["SubCategory"].string ?? ""
                if self.interestIds.contains(id) {
                    let data = InterestsSubCategory(id: id, name: SubCategory)
                    self.tempInterests.append(data)
                }
            }
        }
        self.finalInterests = self.tempInterests
        self.interestCollectionView.delegate = self
        self.interestCollectionView.dataSource = self
        self.interestCollectionView.reloadData()
    
    }
}
