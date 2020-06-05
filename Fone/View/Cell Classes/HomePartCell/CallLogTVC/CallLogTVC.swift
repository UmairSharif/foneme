//
//  CallLogTVC.swift
//  Fone
//
//  Created by Bester on 04/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class CallLogTVC: UITableViewCell {

    //IBOutlet and Variables
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var countLbl : UILabel!
    @IBOutlet weak var callStatusLbl : UILabel!
    @IBOutlet weak var timeLbl : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
