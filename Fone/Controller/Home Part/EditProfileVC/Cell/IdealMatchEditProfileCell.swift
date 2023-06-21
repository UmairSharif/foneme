//
//  IdealMatchEditProfileCell.swift
//  Fone
//
//  Created by Anish on 6/7/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class IdealMatchEditProfileCell: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var viewCOntainer: UIView!
    @IBOutlet weak var matchName : UILabel!
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected {
                UIView.animate(withDuration: 0.3) { // for animation effect
                    self.viewCOntainer.backgroundColor = UIColor(hexString: "3E79ED").withAlphaComponent(0.2)
                    
                }
            }
            else {
                UIView.animate(withDuration: 0.3) { // for animation effect
                    self.viewCOntainer.backgroundColor = UIColor(hexString: "F9f9f9")
                    
                }
            }
        }
    }
}
