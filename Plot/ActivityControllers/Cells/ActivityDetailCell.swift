//
//  ActivityDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 2/8/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivityDetailCellDelegate: class {
    func plusButtonTapped()
    func shareButtonTapped()
    func heartButtonTapped()
}

class ActivityDetailCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var recipe: Recipe! {
        didSet {
            nameLabel.text = recipe.title
            if let category = recipe.readyInMinutes, let subcategory = recipe.servings {
                categoryLabel.text = "Preparation time: \(category) mins"
                subcategoryLabel.text = "Servings: \(subcategory)"
            }
            let recipeImage = "https://spoonacular.com/recipeImages/\(recipe.id)-636x393.jpg"
                imageView.sd_setImage(with: URL(string: recipeImage))
        }
    }
    
    var event: Event! {
        didSet {
            nameLabel.text = "\(String(describing: event.name!))"
            if let startDateTime = event.dates?.start?.dateTime {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let date = dateFormatter.date(from:startDateTime)!
                let newDate = date.startDateTimeString()
                categoryLabel.text = "\(newDate) @ \(event.embedded?.venues?[0].name ?? "")"
            }
            if let minPrice = event.priceRanges?[0].min, let maxPrice = event.priceRanges?[0].max {
                let formatter = CurrencyFormatter()
                formatter.locale = .current
                formatter.numberStyle = .currency
                let minPriceString = formatter.string(for: minPrice)!
                let maxPriceString = formatter.string(for: maxPrice)!
                subcategoryLabel.text = "Price range: \(minPriceString) to \(maxPriceString)"
            } else {
                subcategoryLabel.text = ""
            }
            if let images = event.images, let image = images.first(where: { $0.width == 640 && $0.height == 427 }), let url = image.url {
                imageView.sd_setImage(with: URL(string: url))
            }
        }
    }
    
    var workout: Workout! {
        didSet {
            nameLabel.text = workout.title
            if let category = workout.workoutDuration, let subcategory = workout.exercises?.count {
                categoryLabel.text = "Duration: \(category) mins"
                subcategoryLabel.text = "Number of exercises: \(subcategory)"
            }
            imageView.image = UIImage(named: "workout")!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = UIColor.white
            imageView.backgroundColor = colors[intColor]
        }
    }
    
    weak var delegate: ActivityDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let heartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "heart"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "share"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    let imageView = UIImageView(cornerRadius: 0)
    
    func setupViews() {
                        
        heartButton.constrainWidth(constant: 40)
        heartButton.constrainHeight(constant: 40)
        
        shareButton.constrainWidth(constant: 40)
        shareButton.constrainHeight(constant: 40)
        
        plusButton.constrainWidth(constant: 40)
        plusButton.constrainHeight(constant: 40)

        imageView.constrainHeight(constant: 231)
        

        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel], spacing: 0)
        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        
        let stackView = VerticalStackView(arrangedSubviews: [
            imageView,
            UIStackView(arrangedSubviews: [plusButton, UIView()]),
            labelStackView
            ], spacing: 2)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        

    }
    
    @objc func plusButtonTapped() {
        self.delegate?.plusButtonTapped()
    }
    
    @objc func shareButtonTapped() {
        self.delegate?.shareButtonTapped()
    }

    @objc func heartButtonTapped() {
        self.delegate?.heartButtonTapped()
    }
    
}
