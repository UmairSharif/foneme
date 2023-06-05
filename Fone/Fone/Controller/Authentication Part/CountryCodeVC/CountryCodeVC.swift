//
//  CountryCodeVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreTelephony
import CountryPickerView


protocol CountryDataDelegate {
    func selectedCountry(countryName: String, countryCode: String,flag : UIImage)
}

class CountryCodeVC: UIViewController {

    //IBOutlets and Variables
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var countryTableView: UITableView!
    var delegate : CountryDataDelegate?
    var countryNameSearched = [Country]()
    var isFiltering = false
    let cpv = CountryPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        countryTableView.tableFooterView = UIView.init()
        countryTableView.reloadData()
        
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
    
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}


extension CountryCodeVC : UISearchBarDelegate {
    
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
        
        countryNameSearched = cpv.countries.filter({
            return $0.name.lowercased().contains(searchText.lowercased())
        })
        
        isFiltering = countryNameSearched.count > 0
        self.countryTableView.reloadData()
    }
}

extension CountryCodeVC : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            
            return countryNameSearched.count
        }
        else
        {
            return cpv.countries.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = countryTableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath) as! CountryCodeTVC
        if isFiltering
        {
            if countryNameSearched.count != 0
            {
                let selectCountry = countryNameSearched[indexPath.row]
                cell.countryNameLbl.text = selectCountry.name
                cell.countryCodeLbl.text = selectCountry.phoneCode
                cell.countryImage.image = selectCountry.flag
            }
        }
        else
        {
            let selectedCountry = cpv.countries[indexPath.row]
            cell.countryNameLbl.text = selectedCountry.name
            cell.countryCodeLbl.text = selectedCountry.phoneCode
            cell.countryImage.image = selectedCountry.flag
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFiltering
        {
            if countryNameSearched.count != 0
            {
                let selectCountry = countryNameSearched[indexPath.row]
                let country = selectCountry.name
                let code = selectCountry.phoneCode
                let flagImage = selectCountry.flag
                delegate?.selectedCountry(countryName: country, countryCode: code, flag: flagImage)
                self.dismiss(animated: true, completion: nil)
            }
        }
        else
        {
            let selectedCountry = cpv.countries[indexPath.row]
            let country = selectedCountry.name
            let code = selectedCountry.phoneCode
            let flagImage = selectedCountry.flag
            delegate?.selectedCountry(countryName: country, countryCode: code, flag: flagImage)
            self.dismiss(animated: true, completion: nil)
        }
    }
}

