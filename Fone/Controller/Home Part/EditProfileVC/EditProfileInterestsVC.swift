//
//  EditProfileInterestsVC.swift
//  Fone
//
//  Created by Anish on 6/17/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD

protocol DidselectInterestsDelegate {
    func selectedIds(ids:[Int])
}


class EditProfileInterestsVC: UIViewController ,UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UISearchBarDelegate {

    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var tempInterests = [InterestsModel]()
    var finalInterests = [InterestsModel]()
    var selectedInterestsId = [Int]()
    var user_id = ""
    var delegate : DidselectInterestsDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.getInterests()
        collectionView.allowsMultipleSelection = true
        collectionView.register(UINib(nibName: "InterestsHeaderReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InterestsHeaderReusableView.identifier)
        self.search.delegate = self
        
    }
    

    //MARK: SEARCH
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        
        search.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            self.finalInterests = tempInterests
            self.collectionView.reloadData()
            return
        }
        
        let filteredInterests = tempInterests.filter { interest in
            let lowercasedSearchText = searchText.lowercased()
            let matchesName = interest.name.lowercased().contains(lowercasedSearchText)
            let matchesSubcategory = interest.subcategories.contains { subcategory in
                subcategory.name.lowercased().contains(lowercasedSearchText)
            }
            return matchesName || matchesSubcategory
        }
        
        self.finalInterests = filteredInterests
        self.collectionView.reloadData()
    }
    
    
    @IBAction func saveBtnTApped(_ sender: Any) {
        
        self.dismiss(animated: true) {
            self.delegate?.selectedIds(ids: self.selectedInterestsId)
        }
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
extension EditProfileInterestsVC {
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
