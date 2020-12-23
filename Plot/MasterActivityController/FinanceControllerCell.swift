//
//  FinanceControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

class FinanceControllerCell: BaseContainerCell {
    
    var financeVC: FinanceViewController! {
        didSet {
            financeVC.collectionView.reloadData()
            setupViews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func setupViews() {
        super.setupViews()
        layer.cornerRadius = 16
        
        let stackView = VerticalStackView(arrangedSubviews: [
            financeVC.view
            ], spacing: 0)
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 10, left: 5, bottom: 5, right: 10))
    }
    
}
