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
            numberLabel.text = "\(count)"
            nameLabel.text = exercise.name
            if sets == "0" {
                sets = "1"
            }
            detailLabel.text = "\(sets) sets - \(exercise.reps!) \(exercise.repsType!) each"
        }
    }
    
    weak var delegate: WorkoutDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        return label
    }()
   
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Go to Workout"
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Go to Workout"
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 1
        return label
    }()
   
    func setupViews() {
        
        numberLabel.constrainWidth(constant: 25)
        
        let nameDetailStackView = VerticalStackView(arrangedSubviews: [nameLabel, detailLabel, UIView()], spacing: 2)
        nameDetailStackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        
        let stackView = UIStackView(arrangedSubviews: [numberLabel, nameDetailStackView])
        stackView.spacing = 2
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 15, left: 15, bottom: 15, right: 5))
       
            
    }
        
}
