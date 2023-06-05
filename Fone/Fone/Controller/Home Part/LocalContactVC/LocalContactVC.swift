//
//  LocalContactVC.swift
//  Fone
//
//  Created by Bester on 08/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import ContactsUI
import NVActivityIndicatorView

protocol LocalContactDelegate {
    
    func sendNumber(number : String?)
}

struct FriendList  {
    
    var name : String?
    var number : String?
    var userImage : String?
    var ContactsCnic:String?
    var userId:String?
    var type:String?
    var distance:String?
}

class LocalContactVC: UIViewController {

    //IBoutlet and Variables
    @IBOutlet weak var contactTVC : UITableView!
    @IBOutlet weak var searchBar : UISearchBar!
    var contactArray = [Contacts]()
    var friendList = [FriendList]()
    var filteredContacts = [Contacts]()
    var isFiltering = false
    var logStatus : Bool?
    var delegate : LocalContactDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        let textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.contactTVC.tableFooterView = UIView.init()
        print(LocalContactHandler.instance.contactArray.count)
        self.contactArray = LocalContactHandler.instance.contactArray
        //Table View Reload
        self.contactTVC.reloadData()
//        // Get Contacts Friend List
//        self.sendContactAPI(contactsArray : LocalContactHandler.instance.contactArray)
        
        //Forcing View to light Mode
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        isFiltering = false
        searchBar.text = ""
        
    }
    
    func sendContactAPI(contactsArray : [Contacts])
    {
       
        var result = [String: Any]()
        
        var userId : String?
        
        if let userProfileData = UserDefaults.standard.object(forKey: key_User_Profile) as? Data {
            print(userProfileData)
            if let user = try? PropertyListDecoder().decode(User.self, from: userProfileData) {
                userId = user.userId
            }
        }
        let loginToken = UserDefaults.standard.string(forKey: "AccessToken")
        
        for i in 0..<contactsArray.count {
            let contact = contactsArray[i]
            let number = contact.number?.replacingOccurrences(of: " ", with: "")
            
            let material: [String: Any] = [
                "ContactsName": contact.name ?? "",
                "ContactsNumber": number ?? ""
            ]
            
            result["\(i)"] = material
        }
        
        let parameters = [
            
            "UserId" : userId ?? "",
            "Contacts": result
            
            ] as [String:Any]
        
       // print("params: \(parameters)")
        
        var headers = [String:String]()
        headers = ["Content-Type": "application/json",
                   "Authorization" : "bearer " + loginToken!]
        
        ServerCall.makeCallWitoutFile(saveContactUrl, params: parameters, type: Method.POST, currentView: nil, header: headers) { (response) in
            
            if let json = response {
                
              //  print(json)
                
                self.friendList.removeAll()
                let contacts = json["Contacts"].array
                if contacts?.count == 0
                {
                    //self.inviteView.isHidden = false
                }
                else
                {
                    //self.inviteView.isHidden = true
                    for items in contacts ?? []
                    {
                        let dict = items.dictionary
                        
                        let number = dict?["ContactsNumber"]?.string ?? ""
                        let ContactsCnic = dict?["ContactsCnic"]?.string ?? ""

                        if (number.count > Min_Contact_Number_Lenght) && !(ContactsCnic.isEmpty) {
                            let name = dict?["ContactsName"]?.string ?? ""
                            let userImage = dict?["Image"]?.string ?? ""
                            let getData = FriendList(name: name, number: number,userImage : userImage,ContactsCnic: ContactsCnic)
                            self.friendList.append(getData)
                        }
                        
                    }
                    
                    //Table View Reload
                    self.contactTVC.reloadData()
                }
            }
        }
    }

    @IBAction func backBtnTapped(_ sender : UIButton)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension LocalContactVC :  UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredContacts.count
        }
        else
        {
            return contactArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocalContactTVC
        
        if isFiltering {
            
            if filteredContacts.count != 0
            {
                let contact = filteredContacts[indexPath.row]
                
                cell.nameLbl.text = contact.name
                cell.phoneLbl.text = contact.number
                cell.userImage.sd_setImage(with: URL(string: ""), placeholderImage: UIImage(named: "ic_profile"))
            }
        
        }
        else
        {
            let contact = contactArray[indexPath.row]
            
            cell.nameLbl.text = contact.name
            cell.phoneLbl.text = contact.number
            cell.userImage.sd_setImage(with: URL(string: ""), placeholderImage: UIImage(named: "ic_profile"))
        }
        
        cell.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        cell.cellContentView.layer.borderWidth = 1.0
        cell.cellContentView.layer.cornerRadius = 12.0
        
       // cell.dotView.layer.cornerRadius = cell.dotView.frame.size.height / 2.0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isFiltering {
            if filteredContacts.count != 0
            {
                let contact = filteredContacts[indexPath.row]
                let vc = UIStoryboard().loadCallVC()
                vc.number = contact.number ?? ""
                if logStatus ?? false
                {
                     vc.selectedStatus = true
                     self.navigationController?.pushViewController(vc, animated: true)
                }
                else
                {
                    self.delegate?.sendNumber(number: contact.number)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        else
        {
            let contact = contactArray[indexPath.row]
            let vc = UIStoryboard().loadCallVC()
            vc.number = contact.number ?? ""
            if logStatus ?? false
            {
                 vc.selectedStatus = true
                 self.navigationController?.pushViewController(vc, animated: true)
            }
            else
            {
                 self.delegate?.sendNumber(number: contact.number)
                 self.navigationController?.popViewController(animated: true)
            }
        
        }
    }
}


extension LocalContactVC : UISearchBarDelegate {
    
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
        
        filteredContacts = contactArray.filter({
            return ($0.name?.lowercased().contains(searchText.lowercased()))!
        })
        
        isFiltering = filteredContacts.count > 0
        self.contactTVC.reloadData()
    }
}
