//
//  SocialLinkView.swift
//  Fone
//
//  Created by Thu Le on 12/06/2021.
//  Copyright © 2021 Optechno. All rights reserved.
//

import UIKit

protocol SocialLinkViewDelegate: NSObjectProtocol {
    func socialLinkViewDidDelete(v: SocialLinkView)
    func socialLinkDidTap(v: SocialLinkView)
}

class SocialLinkView: UIView {
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tfUrl: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var btnDelete: UIButton!
    
    weak var delegate: SocialLinkViewDelegate?
    
    private var link: SocialLink!
    
    convenience init(socialLink: SocialLink) {
        self.init(frame: .zero)
        link = socialLink
        tfName.text = link.name
        tfUrl.text = link.url
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initial()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initial()
    }
    
    private func initial() {
        load(from: "SocialLinkView")
        
        self.tfUrl.isEnabled = false
        self.tfName.isEnabled = false
    }
    
    @IBAction func btnDeleteTapped(_ sender: Any) {
        self.delegate?.socialLinkViewDidDelete(v: self)
    }
    
    @IBAction func swValueChanged(_ sender: Any) {
        //self.tfUrl.isEnabled = `switch`.isOn
        //self.tfName.isEnabled = `switch`.isOn
    }
    
    @IBAction func btnCellTapped(_ sender: Any) {
        self.delegate?.socialLinkDidTap(v: self)
    }
    
    private func load(from xibName: String) -> Bool {
        guard let xibContents = Bundle.main.loadNibNamed(xibName, owner: self, options: nil),
              let view = xibContents.first as? UIView
        else { return false }
        
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        return true
    }
}
