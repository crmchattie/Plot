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
    func bookmarkButtonTapped()
    func dotsButtonTapped()
    func segmentSwitched(segment: Int)
}

class ActivityDetailCell: UICollectionViewCell {
    
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultOrange, FalconPalette.defaultGreen, FalconPalette.defaultDarkBlue]
    var intColor: Int = 0
    
    var favAct = [String: [String]]()
    
    var typeString: String = ""
    
    var recipe: Recipe! {
        didSet {
            if let recipe = recipe {
                let recipeImage = "https://spoonacular.com/recipeImages/\(recipe.id)-636x393.jpg"
                imageView.sd_setImage(with: URL(string: recipeImage))
                imageURL = recipeImage
                typeString = "Recipe"
                setupViews()
            }
        }
    }
    
    var event: Event! {
        didSet {
            if let event = event {
                if let images = event.images, let image = images.first(where: { $0.width == 640 && $0.height == 427 }), let url = image.url {
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
                }
                typeString = "Event"
                setupViews()
            }
        }
    }
    
    var attraction: Attraction! {
        didSet {
            if let _ = attraction {
                typeString = "Attraction"
                setupViews()
            }
        }
    }
    
    var workout: Workout! {
        didSet {
            if let _ = workout {
                imageView.image = UIImage(named: "workout")!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.white
                imageView.backgroundColor = colors[intColor]
                imageURL = "workout"
                typeString = "Workout"
                setupViews()
            }
        }
    }
    
    var fsVenue: FSVenue! {
        didSet {
            if let fsVenue = fsVenue {
                if let image = fsVenue.bestPhoto, let prefix = image.photoPrefix, let suffix = image.suffix {
                    let url = prefix + "500x300" + suffix
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
                } else if let imageURL = imageURL {
                    imageView.image = UIImage(named: imageURL)!.withRenderingMode(.alwaysTemplate)
                    imageView.tintColor = UIColor.white
                    imageView.backgroundColor = colors[intColor]
                }
                typeString = "Place"
                setupViews()
            }
        }
    }
    
    var groupItem: GroupItem! {
        didSet {
            if let fsVenue = groupItem.venue {
                if let image = fsVenue.bestPhoto, let prefix = image.photoPrefix, let suffix = image.suffix {
                    let url = prefix + "500x300" + suffix
                    imageView.sd_setImage(with: URL(string: url))
                    imageURL = url
                } else {
                    imageView.image = UIImage(named: imageURL ?? "")!.withRenderingMode(.alwaysTemplate)
                    imageView.tintColor = UIColor.white
                    imageView.backgroundColor = colors[intColor]
                }
                typeString = "Place"
                setupViews()
            }
        }
    }
    
    var sygicPlace: SygicPlace! {
        didSet {
            if let _ = sygicPlace {
                imageView.image = UIImage(named: "sightseeing")!.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.white
                imageView.backgroundColor = colors[intColor]
                imageURL = "sightseeing"
            }
            typeString = "Place"
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
    
    let imageView = UIImageView(cornerRadius: 0)
    
    var imageURL: String?
    var bookmarkButtonImage: String?

    let bookmarkButton: UIButton = {
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
    
    var segmentedControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: ["Activity", "Calendar"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        return segmentControl
    }()
        
    var active: Bool = false
    var activeList: Bool = false
    
    func setupViews() {
        
        dotsButton.isHidden = !active || activeList
        segmentedControl.isHidden = activeList
                
        if let heartImage = bookmarkButtonImage {
            bookmarkButton.setImage(UIImage(named: heartImage), for: .normal)
            bookmarkButton.isHidden = false
        } else {
            bookmarkButton.isHidden = true
        }
        
        imageView.constrainHeight(231)
                        
        bookmarkButton.constrainWidth(40)
        bookmarkButton.constrainHeight(40)
        
        shareButton.constrainWidth(40)
        shareButton.constrainHeight(40)
        
        plusButton.constrainWidth(40)
        plusButton.constrainHeight(40)
        
        dotsButton.constrainWidth(40)
        dotsButton.constrainHeight(40)
        
        segmentedControl.setTitle(typeString, forSegmentAt: 0)
        segmentedControl.setTitle("Calendar", forSegmentAt: 1)
                
        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)

        segmentedControl.constrainHeight(30)
                
        let buttonStack = UIStackView(arrangedSubviews: [plusButton, shareButton, bookmarkButton, UIView(), dotsButton])
        buttonStack.isLayoutMarginsRelativeArrangement = true
        buttonStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 15)
                
        let stackView = VerticalStackView(arrangedSubviews: [
            imageView,
            buttonStack,
            segmentedControl,
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 15, right: 0))
        
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        dotsButton.addTarget(self, action: #selector(dotsButtonTapped), for: .touchUpInside)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        plusButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        shareButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        bookmarkButton.tintColor = ThemeManager.currentTheme().generalTitleColor
        dotsButton.tintColor = ThemeManager.currentTheme().generalTitleColor

    }
    
    @objc func plusButtonTapped() {
        self.delegate?.plusButtonTapped()
    }
    
    @objc func shareButtonTapped() {
        self.delegate?.shareButtonTapped()
    }

    @objc func bookmarkButtonTapped() {
        bookmarkButtonImage = (bookmarkButtonImage == "bookmark") ? "bookmark-filled" : "bookmark"
        bookmarkButton.setImage(UIImage(named: bookmarkButtonImage!), for: .normal)
        self.delegate?.bookmarkButtonTapped()
    }
    
    @objc func dotsButtonTapped() {
        self.delegate?.dotsButtonTapped()
    }
    
    @IBAction func action(_ sender: UISegmentedControl) {
        self.delegate?.segmentSwitched(segment: sender.selectedSegmentIndex)
    }
    
}
