//
//  NewChatCNCTVC.swift
//  Fone
//
//  Created by Manish Chaudhary on 17/02/21.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit

class NewChatCNCTVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension NewChatCNCTVC: UITableViewDelegate,UITableViewDataSource
{
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
       return 2
   }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") else { return UITableViewCell() }
            return cell
        }
        else
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") else { return UITableViewCell() }
            return cell
        }
        
    }
    

    
}
