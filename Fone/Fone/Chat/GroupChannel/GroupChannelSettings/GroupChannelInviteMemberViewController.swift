//
//  GroupChannelInviteMemberViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import SwiftyJSON

class GroupChannelInviteMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NotificationDelegate {
    @IBOutlet weak var selectedUserListView: UICollectionView!
    @IBOutlet weak var selectedUserListHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updatingIndicatorView: CustomActivityIndicatorView!
    var localUserInfo: [String:String] = [:]

    weak var delegate: GroupChannelInviteMemberDelegate?
    
    var selectedUsers: [String:SBDUser] = [:]
    var channel: SBDGroupChannel?
    var users: [SBDUser] = []
    var allUsers: [SBDUser] = []

    var userListQuery: SBDApplicationUserListQuery?
    var refreshControl: UIRefreshControl?
    var searchController: UISearchController?
    var okButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Invite Members"
        
        self.okButtonItem = UIBarButtonItem.init(title: "OK(0)", style: .plain, target: self, action: #selector(GroupChannelInviteMemberViewController.clickOkButton(_:)))
        self.navigationItem.rightBarButtonItem = self.okButtonItem
        
//        self.view.bringSubviewToFront(self.updatingIndicatorView)
//        self.updatingIndicatorView.isHidden = true
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(SelectableUserTableViewCell.nib(), forCellReuseIdentifier: "SelectableUserTableViewCell")
        
        self.selectedUserListView.contentInset = UIEdgeInsets.init(top: 0, left: 14, bottom: 0, right: 14)
        self.selectedUserListView.delegate = self
        self.selectedUserListView.dataSource = self
        self.selectedUserListView.register(SelectedUserCollectionViewCell.nib(), forCellWithReuseIdentifier: SelectedUserCollectionViewCell.cellReuseIdentifier())
        self.selectedUserListHeight.constant = 0
        self.selectedUserListView.isHidden = true
        
        self.selectedUserListView.showsHorizontalScrollIndicator = false
        self.selectedUserListView.showsVerticalScrollIndicator = false
        
        if let layout = self.selectedUserListView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(refreshUserList), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.delegate = self
        if #available(iOS 13.0, *) {
            self.searchController?.searchBar.searchTextField.textColor = UIColor.white
        } else {
            
            // Fallback on earlier versions
        }
        self.searchController?.searchBar.tintColor = .white
        self.searchController?.searchBar.placeholder = "User ID"
        self.searchController?.obscuresBackgroundDuringPresentation = false
      //  self.searchController?.searchBar.tintColor = hexStringToUIColor(hex: "0072F8")
        
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        self.userListQuery = nil
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        self.okButtonItem?.title = "OK\(Int(self.selectedUsers.count))"
        
        self.refreshUserList()
        
        
        self.searchController?.searchBar.set(textColor: .black)
        self.searchController?.searchBar.setTextField(color: .white)
        self.searchController?.searchBar.setPlaceholder(textColor: .black)
        self.searchController?.searchBar.setSearchImage(color: hexStringToUIColor(hex: "0072F8"))
        self.searchController?.searchBar.setClearButton(color:  hexStringToUIColor(hex: "0072F8"))
        
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        
        navigationController?.popViewController(animated: false)
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    @objc func refreshUserList() {
        self.loadUserListNextPage(refresh: false)
    }
    
    func loadUserListNextPage(refresh: Bool) {
        if refresh {
            self.userListQuery = nil
        }
        
        if self.userListQuery == nil {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery?.limit = 200
            
            var arrayNumber = [String]()
                    if let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data  {
                        if let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) {
                            if contacts.count > 0 {
                                for items in contacts
                                {
                                    let dict = items.dictionary
                                    let number = dict?["ContactsNumber"]?.string ?? ""
                                    let name = dict?["ContactsCnic"]?.string ?? ""
                                    arrayNumber.append(number)
                                    self.localUserInfo["\(number)"] = name;
                                    // FM-3 populate friendName
                                    // to use down the logic execution
                                    self.localUserInfo["friendname\(number)"] =  dict?["ContactsName"]?.string ?? ""
                                }
                            }
                        }

                    }
            self.userListQuery?.limit = UInt(arrayNumber.count)

            if arrayNumber.count > 0 {
                           self.userListQuery?.userIdsFilter = arrayNumber
                       }else {
                           self.userListQuery?.userIdsFilter = ["0"]
                       }
        }
        
        
        
        
        if self.userListQuery?.hasNext == false {
            return
        }
        
        self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                if refresh {
                    self.users.removeAll()
                    self.allUsers.removeAll()
                }
                
                for user in users ?? [] {
                    if user.userId == SBDMain.getCurrentUser()?.userId {
                        continue
                    }
                    user.nickname = self.localUserInfo[user.userId]
                    // FM-3. friendName
                    // this way we populate friendName from userdefaults (see how the self.localUserInfo is populated)
                    user.friendName = self.localUserInfo["friendname\(user.userId)"]
                    self.users.append(user)
                    self.allUsers.append(user)
                }
                
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    @objc func clickOkButton(_ sender: Any) {
        guard let channel = self.channel else { return }
        
        self.updatingIndicatorView.superViewSize = self.view.frame.size
        self.updatingIndicatorView.updateFrame()
        self.updatingIndicatorView.isHidden = false
        self.updatingIndicatorView.startAnimating()
        
        channel.invite(Array(self.selectedUsers.values) as [SBDUser]) { (error) in
            self.updatingIndicatorView.isHidden = true
            self.updatingIndicatorView.stopAnimating()
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                alert.addAction(actionCancel)
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            if let delegate = self.delegate {
                delegate.didInviteMembers()
            }
            
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            }
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: SelectedUserCollectionViewCell.cellReuseIdentifier(), for: indexPath)) as! SelectedUserCollectionViewCell
        
        let selectedUserKeys = self.selectedUsers.keys
        let key = Array(selectedUserKeys)[indexPath.row]
        
        cell.setModel(aUser: selectedUsers[key]!)
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedUserKeys = self.selectedUsers.keys
        let key = Array(selectedUserKeys)[indexPath.row]
        
        self.selectedUsers.removeValue(forKey: key)
        
        DispatchQueue.main.async {
            if self.selectedUsers.count == 0 {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListView.isHidden = true
            }
            collectionView.reloadData()
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableUserTableViewCell", for: indexPath) as! SelectableUserTableViewCell
        
        cell.user = self.users[indexPath.row]
        self.okButtonItem?.title = "OK (\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        DispatchQueue.main.async {
            if let updateCell = tableView.cellForRow(at: indexPath) as? SelectableUserTableViewCell {
                let user = self.users[indexPath.row]
                // FM-3.
                // use user.nickname to populate label instead of
                // user.friendName.
                // Reason - in the private channel settings screen
                // the nickname is used.
                // To move to user.friendName display need to do:
                // 1. Change private channel settings screen to show friend name instead of nickname
                // 2. use user.friendName below instead of nickname
                updateCell.nicknameLabel.text = user.nickname
                updateCell.profileImageView.setProfileImageView(for: user)
                
                if self.selectedUsers[user.userId] != nil {
                    updateCell.selectedUser = true
                }
                else {
                    updateCell.selectedUser = false
                }
            }
        }
        
        if self.users.count > 0 && indexPath.row == self.users.count - 1 {
            self.loadUserListNextPage(refresh: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = self.users[indexPath.row]
        if self.selectedUsers[user.userId] != nil {
            self.selectedUsers.removeValue(forKey: user.userId)
        }
        else {
            self.selectedUsers[user.userId] = user
        }
        
        self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        DispatchQueue.main.async {
            if self.selectedUsers.keys.count > 0 {
                self.selectedUserListHeight.constant = 70
                self.selectedUserListView.isHidden = false
            }
            else {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListView.isHidden = true
            }
            
            self.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)
            self.selectedUserListView.reloadData()
        }
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.refreshUserList()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
          /*  self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery?.userIdsFilter = [searchText]
            // self.userListQuery?.setMetaDataFilterWithKey("nickname_startswith", values: [searchText.lowercased()])
            self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    return
                }
                DispatchQueue.main.async {
                    self.users.removeAll()
                    for user in users ?? [] {
                        if user.userId == SBDMain.getCurrentUser()?.userId {
                            continue
                        }
                        self.users.append(user)
                    }
                    
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            })*/
            
           self.users = self.allUsers.filter({
                         return ($0.nickname?.lowercased().contains(searchText.lowercased()) ?? false)
                         })
                     
                     self.tableView.reloadData()
                     self.refreshControl?.endRefreshing()
                 } else {
                     self.users = self.allUsers;
                     self.tableView.reloadData()
                               self.refreshControl?.endRefreshing()
                 }
    }
    }

