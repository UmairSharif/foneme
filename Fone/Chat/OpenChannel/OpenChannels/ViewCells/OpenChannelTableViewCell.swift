//
//  OpenChannelTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import SDWebImage

class OpenChannelTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var participantCountLabel: UILabel!
    @IBOutlet weak var operatorMarkImageView: UIImageView!
    @IBOutlet weak var contentChatView: UIView!

    public var channel: SBDOpenChannel? {
        didSet {

            guard let channel = channel else {
                return
            }
            
            self.channelNameLabel.text = channel.name
            if channel.participantCount > 1 {
                self.participantCountLabel.text = String(format: "%ld participants", channel.participantCount)
            } else {
                self.participantCountLabel.text = String(format: "1 participant")
            }

            var asOperator: Bool = false

            if let operators: [SBDUser] = channel.operators as? [SBDUser] {
                for op in operators {
                    if op.userId == SBDMain.getCurrentUser()?.userId {
                        asOperator = true
                        break
                    }
                }
            }
            if asOperator {
                self.operatorMarkImageView.image = UIImage(named: "img_icon_operator")
            }
            else {
                self.operatorMarkImageView.image = nil
            }

            var placeholderCoverImage: String?
            switch channel.name.count % 3 {
            case 0:
                placeholderCoverImage = "img_cover_image_placeholder_1"
                break
            case 1:
                placeholderCoverImage = "img_cover_image_placeholder_2"
                break
            case 2:
                placeholderCoverImage = "img_cover_image_placeholder_3"
                break
            default:
                placeholderCoverImage = "img_cover_image_placeholder_1"
                break
            }
            if let coverUrl = channel.coverUrl, let url = URL(string: coverUrl) {
                self.coverImage.sd_setImage(with: url, placeholderImage: UIImage(named: placeholderCoverImage!), options: .refreshCached, completed: nil)
            }
            else {
                self.coverImage.image = UIImage(named: placeholderCoverImage!)
            }

        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentChatView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.contentChatView.layer.borderWidth = 1.0
        self.contentChatView.layer.cornerRadius = 12.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
