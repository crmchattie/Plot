//
//  ExerciseDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/10/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ExerciseDetailCell: UICollectionViewCell {
    
    var count: Int = 0
    
    var exercise: Exercise! {
        didSet {
            var sets: String = exercise.sets!
            var reps: String = exercise.reps!
            numberLabel.text = "\(count)"
            nameLabel.text = exercise.name
            if sets == "0" {
                sets = "1 set"
                if reps == "0" {
                    reps = "- go to workout for more detail"
                } else {
                    reps = "- \(reps) \(exercise.repsType!)"
                }
            } else {
                sets = "\(sets) sets"
                if reps == "0" {
                    reps = "- go to workout for more detail"
                } else {
                    reps = "- \(reps) \(exercise.repsType!) each"
                }
            }
            detailLabel.text = "\(sets) \(reps)"
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
   
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
   
    func setupViews() {
        
        numberLabel.constrainWidth(25)
        
        let nameDetailStackView = VerticalStackView(arrangedSubviews: [nameLabel, detailLabel, UIView()], spacing: 2)
        nameDetailStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        nameDetailStackView.isLayoutMarginsRelativeArrangement = true
        
        let stackView = UIStackView(arrangedSubviews: [numberLabel, nameDetailStackView])
        stackView.spacing = 2
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 25, bottom: 15, right: 15))
       
            
    }
        
}
