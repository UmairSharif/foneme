//
//  GenderListCell.swift
//  Fone
//
//  Created by Dong IT. Nguyen Van on 10/04/2023.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class GenderListCell: UITableViewCell {

    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var lbGender: UILabel!
    @IBOutlet weak var icTick: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        viewContainer.layer.cornerRadius = 15
        viewContainer.borderWidth = 1
        viewContainer.borderColor = UIColor(hexString: "E8E6EA")
    }
    
    func bindData(title: String, selected: Bool = false) {
        lbGender.text = title
        if selected {
            viewContainer.backgroundColor = UIColor(hexString: "3E79ED")
            lbGender.textColor = UIColor.white
            icTick.image = UIImage(named: "check-small_white")
        } else {
            viewContainer.backgroundColor = UIColor.white
            lbGender.textColor = UIColor(hexString: "BABBC1")
            icTick.image = UIImage(named: "check-small_separator")
            
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
