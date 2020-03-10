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
    
    weak var delegate: WorkoutDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let clickView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
   
    let getWorkoutLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.text = "Go to Workout"
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()
   
    func setupViews() {
        
        clickView.constrainHeight(constant: 13)
        addSubview(clickView)
        clickView.addSubview(getWorkoutLabel)

        clickView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        getWorkoutLabel.anchor(top: clickView.topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 5, bottom: 0, right: 0))
       
        let viewGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        clickView.addGestureRecognizer(viewGesture)
            
    }
        
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.viewTapped()
    }
}
