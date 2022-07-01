//
//  HeaderCell.swift
//  Plot
//
//  Created by Cory McHattie on 9/27/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

protocol HeaderCellDelegate: AnyObject {
    func viewTapped(sectionType: SectionType)
}

class HeaderCell: UICollectionReusableView {
    
    weak var delegate: HeaderCellDelegate?
    
    var sectionType: SectionType!
    
    let view: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = .boldSystemFont(ofSize: 25)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "See All"
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 18)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
                        
        addSubview(view)
        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 15, bottom: 0, right: 15))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subTitleLabel.anchor(top: view.topAnchor, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(CompositionalHeader.viewTapped(_:)))
        view.addGestureRecognizer(viewTap)
        
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        subTitleLabel.tintColor = .systemBlue
        
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let sectionType = sectionType else {
            return
        }
        self.delegate?.viewTapped(sectionType: sectionType)
    }
}
