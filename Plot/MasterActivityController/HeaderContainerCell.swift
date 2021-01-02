//
//  HeaderContainerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol HeaderContainerCellDelegate: class {
    func viewTapped(sectionType: SectionType)
}

class HeaderContainerCell: UICollectionReusableView {
    weak var delegate: HeaderContainerCellDelegate?
    
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
        label.font = .boldSystemFont(ofSize: 30)
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
                
        view.constrainHeight(30)
        
        addSubview(view)
        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 25, bottom: 0, right: 25))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subTitleLabel.anchor(top: view.topAnchor, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(CompositionalHeader.viewTapped(_:)))
        view.addGestureRecognizer(viewTap)
        
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        subTitleLabel.tintColor = .systemBlue
        subTitleLabel.isHidden = true
        
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let sectionType = sectionType else {
            return
        }
        self.delegate?.viewTapped(sectionType: sectionType)
    }
}
