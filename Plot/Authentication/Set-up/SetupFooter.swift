//
//  SetupFooter.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import Foundation

let setupFooter = "SetupFooter"

class SetupFooter: UICollectionReusableView {
    
    var footerTitle = "Continue"
    
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get Started", for: .normal)
        button.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 8
        return button
    }()
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.setTitle("Continue", for: .normal)
        nextView.setTitleColor(.white, for: .normal)
        nextView.backgroundColor = .systemBlue
        nextView.layer.cornerRadius = 10
        return nextView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        backgroundColor = .systemGroupedBackground
        nextView.setTitle(footerTitle, for: .normal)
        addSubview(button)
        addSubview(nextView)
        
        let leftConstant: CGFloat = 15
        let rightConstant: CGFloat = -15
        let heightConstant: CGFloat = 50
        let spacingConstant: CGFloat = 10
        
        NSLayoutConstraint.activate([
            
            button.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: spacingConstant),
            button.rightAnchor.constraint(equalTo: rightAnchor, constant: rightConstant),
            button.leftAnchor.constraint(equalTo: leftAnchor, constant: leftConstant),
            nextView.heightAnchor.constraint(equalToConstant: heightConstant),
            
            nextView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: spacingConstant),
            nextView.rightAnchor.constraint(equalTo: button.rightAnchor),
            nextView.leftAnchor.constraint(equalTo: button.leftAnchor),
            nextView.heightAnchor.constraint(equalToConstant: heightConstant),
        ])
    }
}
