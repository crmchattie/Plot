//
//  SearchHeader.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class SearchHeader: UICollectionReusableView {
    
    let verticalController = VerticalController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(verticalController.view)
        verticalController.view.fillSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
