//
//  InterestsViewController.swift
//  Fone
//
//  Created by Anish on 6/14/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD

class InterestsViewController: UIViewController ,UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

    @IBOutlet weak var collectionView: UICollectionView!
    
    var tempInterests = [InterestsModel]()
    var finalInterests = [InterestsModel]()
    var selectedInterestsId = [Int]()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.getInterests()
        collectionView.allowsMultipleSelection = true
        collectionView.register(UINib(nibName: "InterestsHeaderReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InterestsHeaderReusableView.identifier)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        let vc = UIStoryboard().loadAddPhotosVC()
        vc.email = email
        vc.phoneNumber = phoneNumber
        vc.phoneCode = phoneCode
        vc.name = name
        vc.lastName = lastName
        vc.user = user
        vc.accessToken = accessToken
        vc.idGender = idGender
        vc.idealMatchId = idealMatchId
        vc.selectedDate = selectedDate
        vc.user_id = self.user_id
        vc.interestsIds = self.selectedInterestsId
        self.navigationController?.pushViewController(vc, animated: true)
    }
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return finalInterests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalInterests[section].subcategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InterestsCollectionViewCell", for: indexPath) as! InterestsCollectionViewCell
        let subCategory = finalInterests[indexPath.section].subcategories[indexPath.item]
        cell.nameLbl.text = subCategory.name
        if self.selectedInterestsId.contains(subCategory.id){
            cell.viewCOntainer.backgroundColor = UIColor(hexString: "3E79ED")
            cell.nameLbl.textColor = UIColor.white
        }else {
            cell.viewCOntainer.backgroundColor = UIColor(hexString: "F5F5F5")
            cell.nameLbl.textColor = UIColor.black
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let name = finalInterests[indexPath.section].name
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InterestsHeaderReusableView.identifier, for: indexPath) as! InterestsHeaderReusableView
        header.configure(headerName: name)
       
        return header
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedCell = collectionView.cellForItem(at: indexPath) as? InterestsCollectionViewCell {
            selectedCell.isSelected = true
            selectedCell.viewCOntainer.backgroundColor = UIColor(hexString: "3E79ED") // Set the desired selected cell background color
            
            let id = finalInterests[indexPath.section].subcategories[indexPath.item].id
            if !selectedInterestsId.contains(id) {
                selectedInterestsId.append(id)
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let deselectedCell = collectionView.cellForItem(at: indexPath) as? InterestsCollectionViewCell {
            deselectedCell.isSelected = false
            deselectedCell.viewCOntainer.backgroundColor = UIColor(hexString: "F5F5F5") // Set the default cell background color
            deselectedCell.nameLbl.textColor = UIColor.black
            
            let id = finalInterests[indexPath.section].subcategories[indexPath.item].id
            if let index = selectedInterestsId.firstIndex(of: id) {
                selectedInterestsId.remove(at: index)
            }
        }
    }
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 100, height: 60)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let yourWidth = (collectionView.bounds.width/5.0)
        let yourHeight = CGFloat(40)
        return CGSize(width: yourWidth, height: yourHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 10
        
    }

}

extension InterestsViewController {
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
            
            let category = item.1["Category"].string ?? ""
            let subCat = item.1["SubCategoryList"].array ?? []
            var interestsSubs = [InterestsSubCategory]()
            interestsSubs.removeAll()
            for category in subCat {
                let id = category["Id"].int ?? 0
                let SubCategory = category["SubCategory"].string ?? ""
                interestsSubs.append(InterestsSubCategory(id: id, name: SubCategory))
            }
            let data = InterestsModel(name: category, subcategories: interestsSubs)
            self.tempInterests.append(data)
        }
        self.finalInterests = self.tempInterests
        self.collectionView.reloadData()
    
    }
}

struct InterestsModel {
    let name: String
    let subcategories: [InterestsSubCategory]
}

struct InterestsSubCategory {
    let id: Int
    let name: String
}
