//
//  DatePickerCell.swift
//  TCBRetail
//
//  Created by Chinh IT. Phung Van on 03/08/2021.
//

import UIKit

enum DatePickerCellType {
    case title
    case day
}

class DatePickerCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectBackgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.textAlignment = .center
        selectBackgroundView.clipsToBounds = true
    }
        
    func bind(_ type: DatePickerCellType, title: String,
              isWeekend: Bool, isSelect: Bool, isEnable: Bool) {
        titleLabel.text = title
        
        if type == .title {
            titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
            titleLabel.textColor = isWeekend ? UIColor(named: "ff3B30") : UIColor(named: "f5F5F5")
            selectBackgroundView.backgroundColor = UIColor(named: "333333")
        } else {
            titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
            if isSelect {
                selectBackgroundView.backgroundColor = isEnable ? UIColor(named: "0A84Ff") : UIColor(named: "333333")
                titleLabel.textColor = isEnable ? UIColor.white : UIColor(named: "616161")
            } else {
                selectBackgroundView.backgroundColor =  UIColor(named: "333333")
                titleLabel.textColor = isEnable ? UIColor(named: "f5F5F5") : UIColor(named: "616161")
            }
        }
    }

}
