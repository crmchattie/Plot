//
//  PlaceDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 7/11/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol PlaceDetailCellDelegate: AnyObject {
    func websiteTapped()
    func phoneNumberTapped()
}

class PlaceDetailCell: UICollectionViewCell {
    
    var fsVenue: FSVenue! {
        didSet {
            if let fsVenue = fsVenue {
                if let hours = fsVenue.hours, let status = hours.status {
                    statusLabel.text = "Today: \(status)"
                    hoursLabel.text = "Hours:"
                    if let timeframes = hours.timeframes {
                        for index in 0...timeframes.count - 1 {
                            if let days = timeframes[index].days, let timeframeOpen = timeframes[index].timeframeOpen {
                                if timeframeOpen.count == 2 {
                                    if let firstTime = timeframeOpen[0].renderedTime, let secondTime = timeframeOpen[1].renderedTime {
                                        switch index {
                                        case 0:
                                            monLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            monLabel.isHidden = false
                                        case 1:
                                            tuesLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            tuesLabel.isHidden = false
                                        case 2:
                                            wedLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            wedLabel.isHidden = false
                                        case 3:
                                            thursLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            thursLabel.isHidden = false
                                        case 4:
                                            friLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            friLabel.isHidden = false
                                        case 5:
                                            satLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            satLabel.isHidden = false
                                        case 6:
                                            sunLabel.text = "\(days): \(firstTime) - \(secondTime)"
                                            sunLabel.isHidden = false
                                        default: break
                                            
                                        }
                                    }
                                } else if let days = timeframes[index].days, let timeframeOpen = timeframes[index].timeframeOpen, let firstTime = timeframeOpen[0].renderedTime {
                                    switch index {
                                    case 0:
                                        monLabel.text = "\(days): \(firstTime)"
                                        monLabel.isHidden = false
                                    case 1:
                                        tuesLabel.text = "\(days): \(firstTime)"
                                        tuesLabel.isHidden = false
                                    case 2:
                                        wedLabel.text = "\(days): \(firstTime)"
                                        wedLabel.isHidden = false
                                    case 3:
                                        thursLabel.text = "\(days): \(firstTime)"
                                        thursLabel.isHidden = false
                                    case 4:
                                        friLabel.text = "\(days): \(firstTime)"
                                        friLabel.isHidden = false
                                    case 5:
                                        satLabel.text = "\(days): \(firstTime)"
                                        satLabel.isHidden = false
                                    case 6:
                                        sunLabel.text = "\(days): \(firstTime)"
                                        sunLabel.isHidden = false
                                    default: break
                                        
                                    }
                                }
                            }
                        }
                    }
                } else {
                    statusLabel.isHidden = true
                    hoursLabel.isHidden = true
                }
                if let attributes = fsVenue.attributes, let groups = attributes.groups, groups.count > 0 {
                    featuresLabel.text = "Features:"
                    for index in 0...groups.count - 1 {
                        if let name = groups[index].name, let items = groups[index].items {
                            let itemString = items.map { ($0.displayValue ?? "") }.joined(separator: ", ")
                            switch index {
                            case 0:
                                oneLabel.text = "\(name): \(itemString)"
                                oneLabel.isHidden = false
                            case 1:
                                twoLabel.text = "\(name): \(itemString)"
                                twoLabel.isHidden = false
                            case 2:
                                threeLabel.text = "\(name): \(itemString)"
                                threeLabel.isHidden = false
                            case 3:
                                fourLabel.text = "\(name): \(itemString)"
                                fourLabel.isHidden = false
                            case 4:
                                fiveLabel.text = "\(name): \(itemString)"
                                fiveLabel.isHidden = false
                            case 5:
                                sixLabel.text = "\(name): \(itemString)"
                                sixLabel.isHidden = false
                            case 6:
                                sevenLabel.text = "\(name): \(itemString)"
                                sevenLabel.isHidden = false
                            case 7:
                                eightLabel.text = "\(name): \(itemString)"
                                eightLabel.isHidden = false
                            default: break
                                
                            }
                        }
                    }
                } else {
                    featuresLabel.isHidden = true
                }
                if fsVenue.url == nil {
                    websiteLabel.isHidden = true
                    websiteView.isHidden = true
                    websiteView.isUserInteractionEnabled = false
                }
                if let contact = fsVenue.contact, let phoneNumber = contact.formattedPhone {
                    phoneNumberLabel.text = phoneNumber
                } else {
                    phoneLabel.isHidden = true
                    phoneView.isHidden = true
                    phoneView.isUserInteractionEnabled = false
                }
                setupViews()
            }
        }
    }
    
    weak var delegate: PlaceDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let websiteView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let webLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Website"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let websiteLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Website"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let phoneView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let phoneLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Phone Number"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let phoneNumberLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let hoursLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let monLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let tuesLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let wedLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let thursLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let friLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let satLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let sunLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let featuresLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let oneLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let twoLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let threeLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let fourLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let fiveLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let sixLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let sevenLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let eightLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
   
    func setupViews() {
        
        phoneView.constrainHeight(20)
        websiteView.constrainHeight(20)
        
        phoneView.addSubview(phoneLabel)
        phoneView.addSubview(phoneNumberLabel)
        phoneLabel.anchor(top: phoneView.topAnchor, leading: phoneView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        phoneNumberLabel.anchor(top: phoneView.topAnchor, leading: nil, bottom: nil, trailing: phoneView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        websiteView.addSubview(websiteLabel)
        websiteLabel.anchor(top: websiteView.topAnchor, leading: websiteView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
//        websiteLabel.centerXAnchor.constraint(equalTo: websiteView.centerXAnchor).isActive = true
        
        if !hoursLabel.isHidden && !featuresLabel.isHidden {
            let hoursStackView = VerticalStackView(arrangedSubviews:
                [monLabel, tuesLabel, wedLabel, thursLabel, friLabel, satLabel, sunLabel
                ], spacing: 10)
            hoursStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            hoursStackView.isLayoutMarginsRelativeArrangement = true
            
            let featuresStackView = VerticalStackView(arrangedSubviews:
                [oneLabel, twoLabel, threeLabel, fourLabel, fiveLabel, sixLabel, sevenLabel, eightLabel
                ], spacing: 10)
            featuresStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            featuresStackView.isLayoutMarginsRelativeArrangement = true
        
            let stackView = VerticalStackView(arrangedSubviews:
                [phoneView, websiteView, statusLabel, hoursLabel, hoursStackView, featuresLabel, featuresStackView
                ], spacing: 10)
            addSubview(stackView)
            stackView.fillSuperview(padding: .init(top: 2, left: 15, bottom: 20, right: 15))
        } else if !hoursLabel.isHidden {
            let hoursStackView = VerticalStackView(arrangedSubviews:
                [monLabel, tuesLabel, wedLabel, thursLabel, friLabel, satLabel, sunLabel
                ], spacing: 10)
            hoursStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            hoursStackView.isLayoutMarginsRelativeArrangement = true
                    
            let stackView = VerticalStackView(arrangedSubviews:
                [phoneView, websiteView, statusLabel, hoursLabel, hoursStackView
                ], spacing: 10)
            addSubview(stackView)
            stackView.fillSuperview(padding: .init(top: 2, left: 15, bottom: 20, right: 15))
        } else {
            let featuresStackView = VerticalStackView(arrangedSubviews:
                [oneLabel, twoLabel, threeLabel, fourLabel, fiveLabel, sixLabel, sevenLabel, eightLabel
                ], spacing: 10)
            featuresStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            featuresStackView.isLayoutMarginsRelativeArrangement = true
        
            let stackView = VerticalStackView(arrangedSubviews:
                [phoneView, websiteView, statusLabel, featuresLabel, featuresStackView
                ], spacing: 10)
            addSubview(stackView)
            stackView.fillSuperview(padding: .init(top: 2, left: 15, bottom: 20, right: 15))
        }
       
        let websiteGesture = UITapGestureRecognizer(target: self, action: #selector(websiteTapped(_:)))
        websiteView.addGestureRecognizer(websiteGesture)
        let phoneNumberGesture = UITapGestureRecognizer(target: self, action: #selector(phoneNumberTapped(_:)))
        phoneView.addGestureRecognizer(phoneNumberGesture)
            
    }
        
    @objc func websiteTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.websiteTapped()
    }
    
    @objc func phoneNumberTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.phoneNumberTapped()
    }
}
