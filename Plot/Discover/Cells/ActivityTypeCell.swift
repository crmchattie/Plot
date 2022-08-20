//
//  ActivityTypeCell.swift
//  Plot
//
//  Created by Cory McHattie on 1/4/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivityTypeCellDelegate: AnyObject {
    func plusButtonTapped(type: AnyHashable)
    func shareButtonTapped(activityObject: ActivityObject)
    func bookmarkButtonTapped(type: Any)
    func mapButtonTapped(type: AnyHashable)
}

class ActivityTypeCell: UICollectionViewCell {
    
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
                mapButton.isHidden = true
                setupViews()
            }
        }
    }
    
    var event: TicketMasterEvent! {
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
                if let _ = event.embedded?.venues?[0].address?.line1, let _ = event.embedded?.venues?[0].location?.latitude, let _ = event.embedded?.venues?[0].location?.longitude {
                    mapButton.isHidden = false
                } else {
                    mapButton.isHidden = true
                }
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                setupViews()
            }
        }
    }
    
    var attraction: TicketMasterAttraction! {
        didSet {
            if let attraction = attraction {
                nameLabel.text = "\(attraction.name)"
                if let upcomingEvents = attraction.upcomingEvents?.total {
                    categoryLabel.text = "Total events: \(upcomingEvents)"
                }
                subcategoryLabel.text = ""
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                mapButton.isHidden = true
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
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                mapButton.isHidden = true
                setupViews()
            }
        }
    }
    
    var fsVenue: FSVenue! {
        didSet {
            if let fsVenue = fsVenue {
                nameLabel.text = fsVenue.name
                if let address = fsVenue.location?.formattedAddress?[0] {
                    categoryLabel.text = address
                }
                if let categories = fsVenue.categories, !categories.isEmpty, let subcategory = categories[0].shortName {
                    subcategoryLabel.text = subcategory
                }
                imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                setupViews()
            }
        }
    }
    
    var groupItem: GroupItem! {
        didSet {
            if let groupItem = groupItem, let fsVenue = groupItem.venue  {
                nameLabel.text = fsVenue.name
                if let address = fsVenue.location?.formattedAddress?[0] {
                    categoryLabel.text = address
                }
                if let categories = fsVenue.categories, !categories.isEmpty, let subcategory = categories[0].shortName {
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
    
    weak var delegate: ActivityTypeCellDelegate?
    
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
    
    let mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "map"), for: .normal)
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
                        
        if let heartImage = bookmarkButtonImage {
            bookmarkButton.setImage(UIImage(named: heartImage), for: .normal)
            bookmarkButton.isHidden = false
        } else {
            bookmarkButton.isHidden = true
        }
        
        imageView.tintColor = UIColor.white
        imageView.backgroundColor = colors[intColor]
        
        bookmarkButton.constrainWidth(35)
        bookmarkButton.constrainHeight(35)

        shareButton.constrainWidth(35)
        shareButton.constrainHeight(35)

        plusButton.constrainWidth(35)
        plusButton.constrainHeight(35)
        
        mapButton.constrainWidth(35)
        mapButton.constrainHeight(35)
        
        imageView.constrainWidth(75)
        imageView.constrainHeight(75)
        
        let buttonStackView = UIStackView(arrangedSubviews: [plusButton, shareButton, bookmarkButton, mapButton, UIView()])
        buttonStackView.spacing = 2
        
        let stackView = UIStackView(arrangedSubviews: [imageView, VerticalStackView(arrangedSubviews: [nameLabel, categoryLabel, subcategoryLabel, buttonStackView], spacing: 2)])
        stackView.spacing = 16
        
        stackView.alignment = .center
        
        addSubview(stackView)
        stackView.fillSuperview()
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = ThemeManager.currentTheme().generalTitleColor
        plusButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        shareButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        bookmarkButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        mapButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        recipe = nil
        workout = nil
        event = nil
        fsVenue = nil
        groupItem = nil
        sygicPlace = nil
        attraction = nil
        mapButton.isHidden = false
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
        } else if let fsVenue = fsVenue {
            self.delegate?.plusButtonTapped(type: fsVenue)
        } else if let groupItem = groupItem {
            self.delegate?.plusButtonTapped(type: groupItem)
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
        } else if let fsVenue = fsVenue {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "place",
                            "activityName": "\(fsVenue.name)",
                            "activityTypeID": "\(fsVenue.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "place",
                            "activityName": "\(fsVenue.name)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(fsVenue.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        } else if let groupItem = groupItem, let fsVenue = groupItem.venue {
            var activity = [String: AnyObject]()
            var activityObject: ActivityObject
            if let image = imageView.image, let imageURL = imageURL, let category = categoryLabel.text, let subcategory = subcategoryLabel.text {
                let data = compressImage(image: image)
                activity = ["activityType": "place",
                            "activityName": "\(fsVenue.name)",
                            "activityTypeID": "\(fsVenue.id)",
                            "activityImageURL": imageURL,
                            "activityCategory": category,
                            "activitySubcategory": subcategory,
                            "object": data] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            } else {
                activity = ["activityType": "place",
                            "activityName": "\(fsVenue.name)",
                            "activityCategory": "\(categoryLabel.text ?? "")",
                            "activitySubcategory": "\(subcategoryLabel.text ?? "")",
                            "activityTypeID": "\(fsVenue.id)"] as [String: AnyObject]
                activityObject = ActivityObject(dictionary: activity)
            }
            self.delegate?.shareButtonTapped(activityObject: activityObject)
        }
    }

    @objc func bookmarkButtonTapped() {
        bookmarkButtonImage = (bookmarkButtonImage == "bookmark") ? "bookmark-filled" : "bookmark"
        bookmarkButton.setImage(UIImage(named: bookmarkButtonImage!), for: .normal)
        if let recipe = recipe {
            self.delegate?.bookmarkButtonTapped(type: recipe)
        } else if let workout = workout {
            self.delegate?.bookmarkButtonTapped(type: workout)
        } else if let event = event {
            self.delegate?.bookmarkButtonTapped(type: event)
        } else if let attraction = attraction {
            self.delegate?.bookmarkButtonTapped(type: attraction)
        } else if let fsVenue = fsVenue {
            self.delegate?.bookmarkButtonTapped(type: fsVenue)
        } else if let groupItem = groupItem, let fsVenue = groupItem.venue {
            self.delegate?.bookmarkButtonTapped(type: fsVenue)
        }
        
    }
    
    @objc func mapButtonTapped() {
        if let recipe = recipe {
            self.delegate?.mapButtonTapped(type: recipe)
        } else if let workout = workout {
            self.delegate?.mapButtonTapped(type: workout)
        } else if let event = event {
            self.delegate?.mapButtonTapped(type: event)
        } else if let attraction = attraction {
            self.delegate?.mapButtonTapped(type: attraction)
        } else if let fsVenue = fsVenue {
            self.delegate?.mapButtonTapped(type: fsVenue)
        } else if let groupItem = groupItem {
            self.delegate?.mapButtonTapped(type: groupItem)
        }
    }

}

