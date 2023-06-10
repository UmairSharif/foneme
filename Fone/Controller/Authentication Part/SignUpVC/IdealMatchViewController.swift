//
//  IdealMatchViewController.swift
//  Fone
//
//  Created by Dong IT. Nguyen Van on 09/04/2023.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import SVProgressHUD
class IdealMatchViewController: UIViewController {
    
    var phoneCode : String = ""
    var phoneNumber : String = ""
    var email : String = ""
    var name : String = ""
    var lastName : String = ""
    var user: User?
    var accessToken: String = ""
    var idGender: Int = 0
    var idealMatchId: Int = 0
    var selectedDate: String?
    var user_id = ""
    
    @IBOutlet weak var collectionView: UICollectionView!
    var data: [[String: Any]] = [] {
        didSet {
            collectionView.reloadData()
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        getAPIMasterMatchInterest()
    }
    
    func configureUI() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width * 0.28, height: 130)
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout
        collectionView.register(.init(nibName: "IdealMatchCell", bundle: nil), forCellWithReuseIdentifier: "IdealMatchCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = false
    }
    
    func getAPIMasterMatchInterest() {
        SVProgressHUD.show()
        ServerCall.makeCallWitoutFile(getMasterMatchInterest,
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

    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionNext(_ sender: Any) {
        let vc = UIStoryboard().loadAddPhotosVC()
//        vc.email = email
//        vc.phoneNumber = phoneNumber
//        vc.phoneCode = phoneCode
//        vc.name = name
//        vc.lastName = lastName
//        vc.user = user
//        vc.accessToken = accessToken
//        vc.idGender = idGender
//        vc.idealMatchId = idealMatchId
//        vc.selectedDate = selectedDate
        vc.user_id = self.user_id
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension IdealMatchViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IdealMatchCell", for: indexPath) as? IdealMatchCell {
            let dic = self.data[indexPath.row]
            cell.bindData(image: dic["ImgUrl"] as! String, title: dic["Name"] as! String)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3.0 - 8, height: 130.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = data[indexPath.row]["Id"] as! Int
        self.idealMatchId = id
    }
}
