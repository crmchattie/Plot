//
//  HeaderContainerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class HeaderContainerCell: UICollectionViewCell {
    let view: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = .label
        label.font = UIFont.title1.with(weight: .bold)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "See All"
        label.textColor = .systemBlue
        label.font = UIFont.body.with(weight: .regular)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
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
        view.addSubview(spinnerView)
        view.addSubview(subTitleLabel)
        
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        spinnerView.anchor(top: nil, leading: titleLabel.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
        spinnerView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        subTitleLabel.anchor(top: view.topAnchor, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = .label
        subTitleLabel.tintColor = .systemBlue
        subTitleLabel.isHidden = true
        
    }
}

class InterSectionHeader: UICollectionViewCell {
    
    let view: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Activity Type"
        label.textColor = .label
        label.font = UIFont.title2.with(weight: .bold)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "See All"
        label.textColor = .systemBlue
        label.font = UIFont.body.with(weight: .regular)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        view.addSubview(spinnerView)
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 5, left: 0, bottom: 5, right: 0))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subTitleLabel.anchor(top: view.topAnchor, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        spinnerView.anchor(top: nil, leading: titleLabel.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
        spinnerView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = .label
        subTitleLabel.tintColor = .systemBlue
    }
}

class TableViewHeader: UITableViewHeaderFooterView {
    
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
        label.textColor = .label
        label.font = UIFont.title2.with(weight: .bold)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "See All"
        label.textColor = .systemBlue
        label.font = UIFont.body.with(weight: .regular)
        label.isUserInteractionEnabled = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let spinnerView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(view)
        view.addSubview(titleLabel)
        view.addSubview(subTitleLabel)
        view.addSubview(spinnerView)
        view.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 15, bottom: 5, right: 15))
        titleLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subTitleLabel.anchor(top: view.topAnchor, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        spinnerView.anchor(top: nil, leading: titleLabel.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 10, bottom: 0, right: 0))
        spinnerView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(viewTap)                
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.textColor = .label
        subTitleLabel.tintColor = .systemBlue
        
    }
    
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        guard let sectionType = sectionType else {
            return
        }
        self.delegate?.viewTapped(sectionType: sectionType)
    }
}
