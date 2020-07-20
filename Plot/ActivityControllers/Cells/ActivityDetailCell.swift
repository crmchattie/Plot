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
    func shareButtonTapped(activityObject: ActivityObject)
    func heartButtonTapped(type: Any)
    func dotsButtonTapped()
    func servingsUpdated(servings: Int)
}

class ActivityDetailCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
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
                let recipeImage = "https://spoonacular.com/recipeImages/\(recipe.id)-636x393.jpg"
                imageView.sd_setImage(with: URL(string: recipeImage))
                imageURL = recipeImage
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
                if let images = event.images, let image = images.first(where: { $0.width == 640 && $0.height == 427 }), let url = image.url {
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
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
                if let images = attraction.images, let image = images.first(where: { $0.width == 640 && $0.height == 427 }), let url = image.url {
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
                }
                subcategoryTextField.isUserInteractionEnabled = false
                setupViews()
            }
        }
    }
    
    var workout: Workout! {
        didSet {
            if let workout = workout {
                nameLabel.text = workout.title
                if let category = workout.tagsStr, let subcategory = workout.exercises?.count {
                    categoryLabel.text = category
                    subcategoryLabel.text = "Number of exercises: \(subcategory)"
                }
                imageView.image = UIImage(named: "workout")!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.white
                imageView.backgroundColor = colors[intColor]
                imageURL = "workout"
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
                if let image = fsVenue.bestPhoto, let prefix = image.photoPrefix, let suffix = image.suffix {
                    let url = prefix + "500x300" + suffix
                    print("url \(url)")
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
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
                if let image = fsVenue.bestPhoto, let prefix = image.photoPrefix, let suffix = image.suffix {
                    let url = prefix + "500x300" + suffix
                    print("url \(url)")
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
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
                imageView.image = UIImage(named: "sightseeing")!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.white
                imageView.backgroundColor = colors[intColor]
                imageURL = "sightseeing"
            }
            subcategoryTextField.isUserInteractionEnabled = false
            setupViews()
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
    
    var imageURL: String?
    var heartButtonImage: String?

    let heartButton: UIButton = {
        let button = UIButton(type: .system)
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
    
    let dotsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "dots"), for: .normal)
        button.tintColor = ThemeManager.currentTheme().generalTitleColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
    
    let imageView = UIImageView(cornerRadius: 0)
    
    var active: Bool = false
    var activeList: Bool = false
    
    func setupViews() {
        
        dotsButton.isHidden = !active || activeList
        
        subcategoryTextField.delegate = self
        
        if let heartImage = heartButtonImage {
            heartButton.setImage(UIImage(named: heartImage), for: .normal)
            heartButton.isHidden = false
        } else {
            heartButton.isHidden = true
        }
                        
        heartButton.constrainWidth(40)
        heartButton.constrainHeight(40)
        
        shareButton.constrainWidth(40)
        shareButton.constrainHeight(40)
        
        plusButton.constrainWidth(40)
        plusButton.constrainHeight(40)
        
        dotsButton.constrainWidth(40)
        dotsButton.constrainHeight(40)

        imageView.constrainHeight(231)
        
        subcategoryView.constrainHeight(17)
        
        subcategoryView.addSubview(subcategoryLabel)
        subcategoryView.addSubview(subcategoryTextField)
        subcategoryLabel.anchor(top: subcategoryView.topAnchor, leading: subcategoryView.leadingAnchor, bottom: subcategoryView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        subcategoryTextField.anchor(top: subcategoryView.topAnchor, leading: subcategoryLabel.trailingAnchor, bottom: subcategoryView.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let buttonStack = UIStackView(arrangedSubviews: [plusButton, shareButton, heartButton, UIView(), dotsButton])
        buttonStack.isLayoutMarginsRelativeArrangement = true
        buttonStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 15)
        
        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryView], spacing: 2)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        
        let stackView = VerticalStackView(arrangedSubviews: [
            imageView,
            buttonStack,
            labelStackView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        dotsButton.addTarget(self, action: #selector(dotsButtonTapped), for: .touchUpInside)
        
        let subcategoryViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityDetailCell.subcategoryViewTapped(_:)))
        subcategoryView.addGestureRecognizer(subcategoryViewTapped)

    }
    
    @objc func plusButtonTapped() {
        self.delegate?.plusButtonTapped()
    }
    
    @objc func shareButtonTapped() {
        if let recipe = recipe {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                print("categoryObject \(category)")
                let data = compressImage(image: image)
                activity = ["activityType": "recipe",
                            "activityName": "\(recipe.title)",
                            "activityTypeID": "\(recipe.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "recipe",
                            "activityName": "\(recipe.title)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(recipe.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        } else if let workout = workout {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "workout",
                            "activityName": "\(workout.title)",
                            "activityTypeID": "\(workout.identifier)",
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "activityImageURL": imageURL,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "workout",
                            "activityName": "\(workout.title)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(workout.identifier)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        } else if let event = event {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "event",
                            "activityName": "\(event.name)",
                            "activityTypeID": "\(event.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "event",
                            "activityName": "\(event.name)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(event.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        } else if let attraction = attraction {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "attraction",
                            "activityName": "\(attraction.name)",
                            "activityTypeID": "\(attraction.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "attraction",
                            "activityName": "\(attraction.name)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(attraction.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        } else if let fsVenue = fsVenue {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "event",
                            "activityName": "\(fsVenue.name)",
                            "activityTypeID": "\(fsVenue.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "event",
                            "activityName": "\(fsVenue.name)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(fsVenue.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        }
    }

    @objc func heartButtonTapped() {
        heartButtonImage = (heartButtonImage == "heart") ? "heart-filled" : "heart"
        heartButton.setImage(UIImage(named: heartButtonImage!), for: .normal)
        if let recipe = recipe {
            self.delegate?.heartButtonTapped(type: recipe)
        } else if let workout = workout {
            self.delegate?.heartButtonTapped(type: workout)
        } else if let event = event {
            self.delegate?.heartButtonTapped(type: event)
        } else if let attraction = attraction {
            self.delegate?.heartButtonTapped(type: attraction)
        } else if let fsVenue = fsVenue {
            self.delegate?.heartButtonTapped(type: fsVenue)
        }
        
    }
    
    @objc func dotsButtonTapped() {
        self.delegate?.dotsButtonTapped()
    }
    
    @objc func subcategoryViewTapped(_ sender: UITapGestureRecognizer) {
        subcategoryTextField.becomeFirstResponder()
    }
    
}

extension ActivityDetailCell: UITextFieldDelegate {
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
