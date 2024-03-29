//
//  ActivitySubTypeCell.swift
//  Plot
//
//  Created by Cory McHattie on 1/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivitySubTypeCellDelegate: class {
    func plusButtonTapped(type: Any)
    func shareButtonTapped(activityObject: ActivityObject)
    func bookmarkButtonTapped(type: Any)
}

class ActivitySubTypeCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var favAct = [String: [String]]()
    
    var recipe: Recipe! {
        didSet {
            if let recipe = recipe {
                nameLabel.text = recipe.title
                if let category = recipe.readyInMinutes, let subcategory = recipe.servings {
                    categoryLabel.text = "Preparation time: \(category) mins"
                    subcategoryLabel.text = "Servings: \(subcategory)"
                }
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                setupViews()
            }
        }
    }
    
    var event: Event! {
        didSet {
            if let event = event {
                nameLabel.text = "\(event.name)"
                if let startDateTime = event.dates?.start?.dateTime, let date = startDateTime.toDate() {
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
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
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
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
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
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                setupViews()
            }
        }
    }
    
    var fsVenue: FSVenue! {
        didSet {
            if let fsVenue = fsVenue {
                nameLabel.text = fsVenue.name
                if let category = fsVenue.location?.formattedAddress?[0], let subcategory = fsVenue.categories?[0].shortName {
                    categoryLabel.text = category
                    subcategoryLabel.text = subcategory
                }
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
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
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                setupViews()
            }
        }
    }
    
    weak var delegate: ActivitySubTypeCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var imageURL: String?
    var bookmarkButtonImage: String?
    
    let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "bookmark"), for: .normal)
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
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }()

    let categoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        return label
    }()

    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        return label
    }()
    
    let imageView = UIImageView(cornerRadius: 8)

    
    func setupViews() {
                        
//        if let heartImage = bookmarkButtonImage {
//            bookmarkButton.setImage(UIImage(named: heartImage), for: .normal)
//            bookmarkButton.isHidden = false
//        } else {
//            bookmarkButton.isHidden = true
//        }
        
        imageView.tintColor = UIColor.white
        imageView.backgroundColor = colors[intColor]
        
        bookmarkButton.constrainWidth(40)
        bookmarkButton.constrainHeight(40)

        shareButton.constrainWidth(40)
        shareButton.constrainHeight(40)

        plusButton.constrainWidth(40)
        plusButton.constrainHeight(40)
        
        imageView.constrainWidth(75)
        imageView.constrainHeight(75)
        
        let buttonStackView = UIStackView(arrangedSubviews: [plusButton, shareButton, bookmarkButton, UIView()])
        buttonStackView.spacing = 2
        
        let stackView = UIStackView(arrangedSubviews: [imageView, VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel, buttonStackView], spacing: 2)])
        stackView.spacing = 16
        
        stackView.alignment = .center
        
        addSubview(stackView)
        stackView.fillSuperview()

//        imageView.constrainHeight(231)
        

//        let labelStackView = VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel, UIView()], spacing: 0)
//        labelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//        labelStackView.isLayoutMarginsRelativeArrangement = true
//
//        let stackView = VerticalStackView(arrangedSubviews: [
//            imageView,
//            UIStackView(arrangedSubviews: [plusButton, shareButton, bookmarkButton, UIView()]),
//            labelStackView
//            ], spacing: 2)
//        addSubview(stackView)
//        stackView.fillSuperview(padding: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        plusButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        shareButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        bookmarkButton.tintColor = ThemeManager.currentTheme().generalTitleColor
    }

    
    @objc func plusButtonTapped() {
        if let recipe = recipe {
            self.delegate?.plusButtonTapped(type: recipe)
        } else if let workout = workout {
            self.delegate?.plusButtonTapped(type: workout)
        } else if let event = event {
            self.delegate?.plusButtonTapped(type: event)
        } else if let attraction = attraction {
            self.delegate?.plusButtonTapped(type: attraction)
        }
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
        }
    }

    @objc func bookmarkButtonTapped() {
//        bookmarkButtonImage = (bookmarkButtonImage == "bookmark") ? "bookmark-filled" : "bookmark"
//        bookmarkButton.setImage(UIImage(named: bookmarkButtonImage!), for: .normal)
        if let recipe = recipe {
            self.delegate?.bookmarkButtonTapped(type: recipe)
        } else if let workout = workout {
            self.delegate?.bookmarkButtonTapped(type: workout)
        } else if let event = event {
            self.delegate?.bookmarkButtonTapped(type: event)
        } else if let attraction = attraction {
            self.delegate?.bookmarkButtonTapped(type: attraction)
        }
        
    }

}

