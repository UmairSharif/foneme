//
//  EnterBirthDayVC.swift
//  Fone
//
//  Created by Dong IT. Nguyen Van on 11/04/2023.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class EnterBirthDayVC: UIViewController {
    
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
    
    @IBOutlet weak var calendarView: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hexString: "3E79ED")
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        }
    }
    
    @IBAction func actionNext(_ sender: Any) {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"

        selectedDate = formatter.string(from: calendarView.date)
        print("selectedDate: \(String(describing: selectedDate))")
        let vc = UIStoryboard().loadGenderListVC()
        vc.email = email
        vc.phoneNumber = phoneNumber
        vc.phoneCode = phoneCode
        vc.name = name
        vc.lastName = name
        vc.user = user
        vc.accessToken = accessToken
        vc.selectedDate = selectedDate
        vc.user_id = self.user_id
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func actionBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

