//
//  InterestsHeaderReusableView.swift
//  Fone
//
//  Created by Anish on 6/15/23.
//  Copyright © 2023 Fone.Me. All rights reserved.
//

import UIKit

class InterestsHeaderReusableView: UICollectionReusableView {

    static let identifier = "InterestsHeaderReusableView"
    
    @IBOutlet weak var headerName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func configure(headerName:String) {
        self.headerName.text = headerName
    }
}
