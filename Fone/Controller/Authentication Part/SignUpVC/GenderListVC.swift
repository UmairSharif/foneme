//
//  GenderListVC.swift
//  Fone
//
//  Created by Dong IT. Nguyen Van on 10/04/2023.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import SVProgressHUD

class GenderListVC: UIViewController {
    
    var phoneCode : String = ""
    var phoneNumber : String = ""
    var email : String = ""
    var name : String = ""
    var lastName : String = ""
    var user: User?
    var accessToken: String = ""
    var idGender: Int = 0
    var selectedDate: String?
    var user_id = ""
    
    @IBOutlet weak var tableView: UITableView!
    
    var data: [[String: Any]] = [] {
        didSet {
            idGender = data[0]["Id"] as! Int
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "GenderListCell", bundle: nil), forCellReuseIdentifier: "GenderListCell")
        tableView.dataSource = self
        tableView.delegate = self
        apiGetGenderList()
    }

    
    func apiGetGenderList() {
        SVProgressHUD.show()
        ServerCall.makeCallWitoutFile(getGenderList,
                                      params: [:],
                                      type: Method.GET, currentView: nil, header: ["Content-Type": "application/json"]) { (response) in
            SVProgressHUD.dismiss()
            if let json = response {
                print(json)
                let statusCode = json["StatusCode"].string ?? ""

                if statusCode == "200" || statusCode == "201"
                {
                    if let groups = json["dropDown"].array {
                        self.data = groups.map({ json in
                            return json.dictionaryObject ?? [:]
                        })
                    } else {
                        
                    }
                } else {
                    
                }
            }
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

    @IBAction func nextAction(_ sender: Any) {
        let vc = UIStoryboard().loadIdealMatchViewController()
        vc.email = email
        vc.phoneNumber = phoneNumber
        vc.phoneCode = phoneCode
        vc.name = name
        vc.lastName = lastName
        vc.user = user
        vc.accessToken = accessToken
        vc.idGender = idGender
        vc.selectedDate = selectedDate
        vc.user_id = self.user_id
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension GenderListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "GenderListCell", for: indexPath) as? GenderListCell {
            cell.bindData(title: data[indexPath.row]["Name"] as! String, selected: (data[indexPath.row]["Id"] as! Int) == idGender)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = data[indexPath.row]["Id"] as! Int
        self.idGender = id
        tableView.reloadData()
    }
}
