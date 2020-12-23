//
//  ActivitiesControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ActivitiesControllerCell: BaseContainerCell {
    
    var activitiesVC: ActivityViewController! {
        didSet {
            activitiesVC.activityView.tableView.reloadData()
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
            activitiesVC.view
            ], spacing: 0)
        
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 15, left: 5, bottom: 5, right: 10))
    }
    
}


