//
//  FriendTVC.swift
//  Fone
//
//  Created by Bester on 15/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class FriendTVC: UITableViewCell {

    //IBOutlet and Variables
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var userImage : UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
