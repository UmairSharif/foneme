//
//  LocalContactTVC.swift
//  Fone
//
//  Created by Bester on 08/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit

class LocalContactTVC: UITableViewCell {

    //IBOutlet and Variables
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var phoneLbl : UILabel!
    @IBOutlet weak var btnCall : UIButton!
    @IBOutlet weak var btnVideo : UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
