//
//  CreateGroupChannelViewControllerA.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/15/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import SwiftyJSON

class CreateGroupChannelViewControllerA: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, NotificationDelegate {
    var selectedUsers: [SBDUser] = []
    
    @IBOutlet weak var selectedUserListView: UICollectionView!
    @IBOutlet weak var selectedUserListHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    var users: [SBDUser] = []
    var allUsers: [SBDUser] = []
    var localUserInfo: [String:String] = [:]

    var userListQuery: SBDApplicationUserListQuery?
    var refreshControl: UIRefreshControl?
    var searchController: UISearchController?
    
    var okButtonItem: UIBarButtonItem?
    var cancelButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add Participants"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.okButtonItem = UIBarButtonItem(image: UIImage(named: "ic_next"), style: .plain, target: self, action: #selector(CreateGroupChannelViewControllerA.clickOkButton(_:)))
        self.okButtonItem?.tintColor = UIColor.black
        self.navigationItem.rightBarButtonItem = self.okButtonItem
        
        self.cancelButtonItem = UIBarButtonItem(image: UIImage(named: "ic_back_blk"), style: .plain, target: self, action: #selector(CreateGroupChannelViewControllerA.clickCancelCreateGroupChannel(_:)))
        
        self.cancelButtonItem?.tintColor = hexStringToUIColor(hex: "333333")
        self.navigationItem.leftBarButtonItem = self.cancelButtonItem
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.delegate = self
        if #available(iOS 13.0, *) {
            self.searchController?.searchBar.searchTextField.textColor = UIColor.white
        } else {

            // Fallback on earlier versions
        }
        self.searchController?.searchBar.placeholder = "Search"
        self.searchController?.searchBar.tintColor = .white
        self.searchController?.obscuresBackgroundDuringPresentation = false
        //self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        self.navigationController?.navigationBar.backgroundColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: hexStringToUIColor(hex: "333333")]
        
//        self.searchController?.searchBar.tintColor = hexStringToUIColor(hex: "0072F8")
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(SelectableUserTableViewCell.nib(), forCellReuseIdentifier: "SelectableUserTableViewCell")

        self.setupScrollView()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(CreateGroupChannelViewControllerA.refreshUserList), for: .valueChanged)
        
        self.tableView.refreshControl = self.refreshControl
        
        self.userListQuery = nil
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        //self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        self.refreshUserList()
        
        self.searchController?.searchBar.set(textColor: hexStringToUIColor(hex: "333333"))
        self.searchController?.searchBar.setTextField(color: .white)
        self.searchController?.searchBar.setPlaceholder(textColor: hexStringToUIColor(hex: "333333"))
        self.searchController?.searchBar.setSearchImage(color: hexStringToUIColor(hex: "0072F8"))
        self.searchController?.searchBar.setClearButton(color:  hexStringToUIColor(hex: "0072F8"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self] ).tintColor = .white
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setupScrollView() {
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
    }
    
    @objc func clickCancelCreateGroupChannel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func clickOkButton(_ sender: AnyObject) {
        
        var arrayIds = self.selectedUsers.map({ $0.userId })
//        let nicknames = self.selectedUsers.map({ $0.nickname })
//        var nickname = ""
        if arrayIds.count == 1 {
            if  let cUser = SBDMain.getCurrentUser() {
                arrayIds.append(cUser.userId)
               // nickname = "\(nicknames[0]), \(cUser.nickname)"
            }
            
            
            
//            let params = SBDGroupChannelParams()
//                      // params.coverImage = self.coverImageData
//                       params.add(selectedUsers)
//                       params.name = nickname
//                       params.data = ""
//                       params.isPublic = true
//            params.isDistinct = true
//
//        SBDGroupChannel.createChannel(with: params) { (sbdchanel, error) in


SBDGroupChannel.createChannel(withUserIds: arrayIds, isDistinct: true) { (sbdchanel, error) in
                
                if let _ = sbdchanel {
                    self.dismiss(animated: true) {

                    }
                    return
                }
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                    let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                    alert.addAction(actionCancel)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }else{
            performSegue(withIdentifier: "ConfigureGroupChannel", sender: self)
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.dismiss(animated: false) {
            if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
                cvc.openChat(channelUrl)
            }
        }
    }

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ConfigureGroupChannel", let destination = segue.destination as? CreateGroupChannelViewControllerB{
            destination.members = self.selectedUsers
        }
     }
    
    // MARK: - Load users
    @objc func refreshUserList() {
        self.loadUserListNextPage(true)
    }
    
    func loadUserListNextPage(_ refresh: Bool) {
        if refresh {
            self.userListQuery = nil
        }
        
        if self.userListQuery == nil {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            var arrayNumber = [String]()
            if let contactData = UserDefaults.standard.object(forKey: "Contacts") as? Data  {
                if let contacts = try? PropertyListDecoder().decode([JSON].self, from: contactData) {
                    if contacts.count > 0 {
                        for items in contacts {
                            let dict = items.dictionary
                            print(dict)
                            let number = dict?["ContactsNumber"]?.string ?? ""
                            let name = dict?["ContactsCnic"]?.string ?? ""
                            arrayNumber.append(number)
                            self.localUserInfo["\(number)"] = name;
                            self.localUserInfo["friendname" + "\(number)"] =  dict?["ContactsName"]?.string ?? ""

                        }
                    }
//                    key    String    "ContactsName"
                }

            }
            self.userListQuery?.limit = UInt(arrayNumber.count)
            print("arrayNumber = \(arrayNumber) === \(arrayNumber.count)");
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
                
                for user in users! {
                    if user.userId == SBDMain.getCurrentUser()?.userId {
                        continue
                    }
                    user.nickname = self.localUserInfo[user.userId]
                    user.friendName = self.localUserInfo["friendname" + user.userId]
                    self.users.append(user)
                    self.allUsers.append(user)
                    
                }
                
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        })
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: SelectedUserCollectionViewCell.cellReuseIdentifier(), for: indexPath)) as! SelectedUserCollectionViewCell
        
        cell.profileImageView.setProfileImageView(for: selectedUsers[indexPath.row])
        cell.nicknameLabel.text = selectedUsers[indexPath.row].friendName
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedUsers.remove(at: indexPath.row)
        //self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableUserTableViewCell") as! SelectableUserTableViewCell
        cell.user = self.users[indexPath.row]
        
        DispatchQueue.main.async {
            if let updateCell = tableView.cellForRow(at: indexPath) as? SelectableUserTableViewCell {
                updateCell.nicknameLabel.text = self.users[indexPath.row].friendName
                    //"fone.me/\(self.users[indexPath.row].nickname!)"
                updateCell.profileImageView.setProfileImageView(for: self.users[indexPath.row])
                
                if let user = self.users[exists: indexPath.row] {
                    if self.selectedUsers.contains(user) {
                        updateCell.selectedUser = true
                    } else {
                        updateCell.selectedUser = false
                    }
                }
                
            }
        }
        
        if self.users.count > 0 && indexPath.row == self.users.count - 1 {
            self.loadUserListNextPage(false)
        }
        
        cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.cellContentView.layer.borderWidth = 1.0
        cell.cellContentView.layer.cornerRadius = 12.0
        
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let user = self.users[exists: indexPath.row] {
            if self.selectedUsers.contains(user) {
                self.selectedUsers.removeObject(user)
            } else {
                self.selectedUsers.append(user)
            }
        }
        
        //self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        DispatchQueue.main.async {
            if self.selectedUsers.count > 0 {
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
                        if user.userId == SBDMain.getCurrentUser()!.userId {
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
