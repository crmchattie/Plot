//
//  WorkoutDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol WorkoutDetailCellDelegate: class {
    func viewTapped()
}

class WorkoutDetailCell: UICollectionViewCell {
    
    var workout: Workout! {
        didSet {
            if let notes = workout.notes {
                print("set notes")
                notesLabel.text = notes
            }
            setupViews()
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
    
    let notesLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    let clickView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()
   
    let getWorkoutLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "Go to Workout"
        label.numberOfLines = 1
        return label
    }()
   
    func setupViews() {
        
        clickView.constrainHeight(constant: 17)
        
        let labelStackView = UIStackView(arrangedSubviews: [notesLabel])
        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        
        clickView.addSubview(getWorkoutLabel)
        getWorkoutLabel.anchor(top: clickView.topAnchor, leading: clickView.leadingAnchor, bottom: nil, trailing: clickView.trailingAnchor, padding: .init(top: 0, left: 15, bottom: 0, right: 15))
        
        let stackView = VerticalStackView(arrangedSubviews:
            [labelStackView,
            clickView
            ], spacing: 2)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 10, right: 0))
       
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        clickView.addGestureRecognizer(viewGesture)
            
    }
        
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.viewTapped()
    }
}
