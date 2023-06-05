//
//  IdealMatchCell.swift
//  Fone
//
//  Created by Dong IT. Nguyen Van on 09/04/2023.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class IdealMatchCell: UICollectionViewCell {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var viewCOntainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func bindData(image: String, title: String) {
        lbTitle.text = title
        imgView.sd_setImage(with: URL(string: image))
    }

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
