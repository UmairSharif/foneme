//
//  LocalContactTVC.swift
//  Fone
//
//  Created by Bester on 08/01/2020.
//  Copyright © 2020 Optechno. All rights reserved.
//

import UIKit
import SDWebImage

class LocalContactTVC: UITableViewCell {

    //IBOutlet and Variables
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var phoneLbl : UILabel!
    @IBOutlet weak var btnCall : UIButton!
    @IBOutlet weak var btnVideo : UIButton!
    @IBOutlet weak var lastseen : UILabel!
    @IBOutlet weak var online : UILabel!
    @IBOutlet weak var distance : UILabel!
    @IBOutlet weak var cellContentView : UIView!

    var contact: FriendList? {
        didSet {
            self.nameLbl.text = contact?.name
            self.phoneLbl.text = contact?.ContactsCnic?.cnicToLink
            self.distance.text = contact?.distance
            if let userImage = contact?.userImage, let urlImage = URL(string: userImage) {
                self.userImage.sd_setImage(with: urlImage, placeholderImage: UIImage(named: "ic_profile"))
            } else {
                /// There is no profile picture.
                self.userImage.image = UIImage(named: "ic_profile")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }



}
