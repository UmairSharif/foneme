//
//  InterestsCollectionViewCell.swift
//  Fone
//
//  Created by Anish on 6/15/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class InterestsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var viewCOntainer : UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = UIColor(hexString: "3E79ED")
            nameLbl.textColor = .white
            UserDefaults.standard.set(true, forKey: "isSelected")
        }
    }
}
