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
    @IBOutlet weak var callStatusImage : UIImageView!
    @IBOutlet weak var nameLbl : UILabel!
    @IBOutlet weak var countLbl : UILabel!
    @IBOutlet weak var callStatusLbl : UILabel!
    @IBOutlet weak var timeLbl : UILabel!
    @IBOutlet weak var cellContentView : UIView!
    @IBOutlet weak var dotView : UIView!

    private let dateFormatter = DateFormatter()

    public var callLog: CallLog? {
        didSet {

            guard let callLog = callLog else {
                return
            }

            if callLog.status == "Out Going" {
                self.callStatusLbl.text = "Out Going"
                self.callStatusImage.image = UIImage(named: "outgoing_call_ic")
                self.callStatusLbl.textColor = hexStringToUIColor(hex: "3E79ED")
            } else if callLog.status == "InComing" {
                self.callStatusLbl.text = "Incoming Call"
                self.callStatusImage.image = UIImage(named: "ic_incoming_call")
                self.callStatusLbl.textColor = hexStringToUIColor(hex: "229753")
            } else {
                self.callStatusLbl.text = "Missed Call"
                self.callStatusImage.image = UIImage(named: "missed_call_ic")
                self.callStatusLbl.textColor = hexStringToUIColor(hex: "FE1B37")
            }
            dateFormatter.timeZone = TimeZone(abbreviation: "MST")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            let date = dateFormatter.date(from: callLog.dateTime ?? "")

            if Calendar.current.isDateInToday(date ?? Date()) {
                dateFormatter.dateFormat = "hh:mm a"
                dateFormatter.timeZone = TimeZone.current
                let dateString = dateFormatter.string(from: date ?? Date())
                self.timeLbl.text = "Today, " + dateString

            } else if Calendar.current.isDateInYesterday(date ?? Date()) {
                dateFormatter.dateFormat = "hh:mm a"
                dateFormatter.timeZone = TimeZone.current
                let dateString = dateFormatter.string(from: date ?? Date())
                self.timeLbl.text = "Yesterday, " + dateString
            } else {
                dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
                dateFormatter.timeZone = TimeZone.current

                let dateString = dateFormatter.string(from: date ?? Date())
                self.timeLbl.text = dateString
            }
            self.nameLbl.text = callLog.name
            self.userImage.sd_setImage(with: URL(string: callLog.userImage ?? ""), placeholderImage: UIImage(named: "ic_profile"))
            self.countLbl.isHidden = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cellContentView.layer.borderColor = hexStringToUIColor(hex: "E8E8E8").cgColor
        self.cellContentView.layer.borderWidth = 1.0
        self.cellContentView.layer.cornerRadius = 12.0
        self.dotView.layer.cornerRadius = self.dotView.frame.size.height / 2.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
