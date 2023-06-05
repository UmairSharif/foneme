//
//  CategoryTableViewCell.swift
//  TTGTagSwiftExample
//
//  Created by Apple on 2/1/23.
//

import UIKit
import TTGTags

class CategoryTableViewCell: UITableViewCell {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var skillsView: UIView!
    weak var tagView: TTGTextTagCollectionView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addTagView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func resetCell(category: Category) {
        headerLabel.text = category.name
        resetTagView(skills: category.subcategories)
    }
    
    private func resetTagView(skills: [Subcategory]) {
        tagView?.removeAllTags()
        
        for skill in skills {
            let content = TTGTextTagStringContent(text: skill.name)
            content.textColor = UIColor.black
            content.textFont = UIFont.systemFont(ofSize: 12)
            
            let selectedContent = TTGTextTagStringContent(text: skill.name)
            selectedContent.textColor = UIColor.white
            selectedContent.textFont = UIFont.systemFont(ofSize: 12)
            
            let normalStyle = TTGTextTagStyle()
            normalStyle.backgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
            normalStyle.extraSpace = CGSize.init(width: 16, height: 16)
            normalStyle.cornerRadius = 16
            normalStyle.shadowOpacity = 0
            normalStyle.borderWidth = 0
            
            let selectedStyle = TTGTextTagStyle()
            selectedStyle.backgroundColor = UIColor(red: 63/255.0, green: 121/255.0, blue: 235/255.0, alpha: 1.0)
            selectedStyle.extraSpace = CGSize.init(width: 16, height: 16)
            selectedStyle.cornerRadius = 16
            selectedStyle.shadowOpacity = 0
            selectedStyle.borderWidth = 0
            
            let tag = TTGTextTag()
            tag.content = content
            tag.selectedContent = selectedContent
            tag.style = normalStyle
            tag.selectedStyle = selectedStyle
            
            tagView?.addTag(tag)
        }
        
        tagView?.reload()
    }
    
    private func addTagView() {
        let tagView = TTGTextTagCollectionView(frame: skillsView.bounds)
        self.skillsView.addSubview(tagView)
        NSLayoutConstraint.activate([
            tagView.leadingAnchor.constraint(equalTo: skillsView.leadingAnchor),
            tagView.topAnchor.constraint(equalTo: skillsView.topAnchor),
            tagView.trailingAnchor.constraint(equalTo: skillsView.trailingAnchor),
            tagView.bottomAnchor.constraint(equalTo: skillsView.bottomAnchor)
        ])
        tagView.translatesAutoresizingMaskIntoConstraints = false
        tagView.numberOfLines = 2
        tagView.scrollDirection = .horizontal
        tagView.showsHorizontalScrollIndicator = false
        self.tagView = tagView
    }
}
