//
//  SummaryHKChartCell.swift
//  Plot
//
//  Created by Cory McHattie on 11/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import HealthKitUI

class SummaryHKChartCell: UICollectionViewCell {
        
    var summary: HKActivitySummary! {
        didSet {
            if let summary = summary {
                setupViews(summary: summary)
            }
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews(summary: HKActivitySummary) {
        // Create the view with a size of 200x200
//        let frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        let ringView = HKActivityRingView()

        // Update the view to display the current summary
        ringView.setActivitySummary(summary, animated: true)
        
        addSubview(ringView)
        ringView.fillSuperview()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
}
