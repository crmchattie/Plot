//
//  ActivityExpandedDetailCellDelegate.swift
//  Plot
//
//  Created by Cory McHattie on 4/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivityExpandedDetailCellDelegate: class {
    func servingsUpdated(servings: Int)
}

class ActivityExpandedDetailCell: UICollectionViewCell {
        
    var favAct = [String: [String]]()
    
    var recipe: Recipe! {
        didSet {
            if let recipe = recipe {
                nameLabel.text = recipe.title
                if let category = recipe.readyInMinutes, let subcategory = recipe.servings {
                    categoryLabel.text = "Preparation time: \(category) mins"
                    subcategoryLabel.text = "Servings: "
                    subcategoryTextField.text = "\(subcategory)"
                }
                setupViews()
            }
        }
    }
    
    var event: Event! {
        didSet {
            if let event = event {
                nameLabel.text = "\(event.name)"
                categoryLabel.text = "\(event.embedded?.venues?[0].name?.capitalized ?? "")"
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
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var attraction: Attraction! {
        didSet {
            if let attraction = attraction {
                nameLabel.text = "\(attraction.name)"
                if let upcomingEvents = attraction.upcomingEvents?.total {
                    categoryLabel.text = "Total events: \(upcomingEvents)"
                }
                subcategoryLabel.text = ""
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var workout: PreBuiltWorkout! {
        didSet {
            if let workout = workout {
                nameLabel.text = workout.title
                if let category = workout.tagsStr, let subcategory = workout.exercises?.count {
                    categoryLabel.text = category
                    subcategoryLabel.text = "Number of exercises: \(subcategory)"
                }
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var fsVenue: FSVenue! {
        didSet {
            if let fsVenue = fsVenue {
                nameLabel.text = fsVenue.name
                if let rating = fsVenue.rating {
                    categoryLabel.text = "Rating: \(rating)/10"
                }
                if let price = fsVenue.price, let tier = price.tier, let categories = fsVenue.categories, !categories.isEmpty, let category = categories[0].shortName {
                    var categoryText = ""
                    switch tier {
                    case 1:
                        categoryText = category + " - $"
                    case 2:
                        categoryText = category + " - $$"
                    case 3:
                        categoryText = category + " - $$$"
                    case 4:
                        categoryText = category + " - $$$$"
                    default:
                        categoryText = category
                    }
                    subcategoryLabel.text = categoryText
                }
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var groupItem: GroupItem! {
        didSet {
            if let fsVenue = groupItem.venue {
                nameLabel.text = fsVenue.name
                if let rating = fsVenue.rating {
                    categoryLabel.text = "Rating: \(rating)/10"
                }
                if let price = fsVenue.price, let tier = price.tier, let categories = fsVenue.categories, !categories.isEmpty, let category = categories[0].shortName {
                    var categoryText = ""
                    switch tier {
                    case 1:
                        categoryText = category + " - $"
                    case 2:
                        categoryText = category + " - $$"
                    case 3:
                        categoryText = category + " - $$$"
                    case 4:
                        categoryText = category + " - $$$$"
                    default:
                        categoryText = category
                    }
                    subcategoryLabel.text = categoryText
                }
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var sygicPlace: SygicPlace! {
        didSet {
            if let sygicPlace = sygicPlace {
                nameLabel.text = sygicPlace.name
                if let category = sygicPlace.nameSuffix, let subcategoryArray = sygicPlace.categories {
                    let subcategory = subcategoryArray.map({ String($0).capitalized }).joined(separator: ", ")
                    categoryLabel.text = category
                    subcategoryLabel.text = subcategory
                }
            }
            subcategoryTextField.isUserInteractionEnabled = false
            setupViews()
        }
    }
    
    weak var delegate: ActivityExpandedDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    let subcategoryView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    let subcategoryTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = ThemeManager.currentTheme().generalSubtitleColor
        textField.font = UIFont.preferredFont(forTextStyle: .subheadline)
        textField.isUserInteractionEnabled = true
        textField.keyboardType = .numberPad
        textField.returnKeyType = .done
        textField.keyboardAppearance = .default
        textField.addDoneButtonOnKeyboard()
        return textField
    }()

    func setupViews() {
                
        subcategoryTextField.delegate = self
        
        if subcategoryLabel.text == "" {
            subcategoryView.isHidden = true
        } else {
            subcategoryView.constrainHeight(17)
        }
        
        subcategoryView.addSubview(subcategoryLabel)
        subcategoryView.addSubview(subcategoryTextField)
        subcategoryLabel.anchor(top: subcategoryView.topAnchor, leading: subcategoryView.leadingAnchor, bottom: subcategoryView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subcategoryTextField.anchor(top: subcategoryView.topAnchor, leading: subcategoryLabel.trailingAnchor, bottom: subcategoryView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryView], spacing: 2)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        
        let stackView = VerticalStackView(arrangedSubviews: [
            labelStackView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 2, right: 0))
                
        let subcategoryViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.subcategoryViewTapped(_:)))
        subcategoryView.addGestureRecognizer(subcategoryViewTapped)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
    }
    
    @objc func subcategoryViewTapped(_ sender: UITapGestureRecognizer) {
        subcategoryTextField.becomeFirstResponder()
    }
    
}

extension ActivityExpandedDetailCell: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text == "" || textField.text == nil {
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.servingsUpdated(servings: Int(subcategoryTextField.text!)!)
    }
}
