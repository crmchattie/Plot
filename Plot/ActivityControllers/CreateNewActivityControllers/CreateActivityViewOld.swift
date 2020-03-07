//
//  CreateActivityViewOld.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/19/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class CreateActivityViewOld: UIView {

    var activityName: UITextField = {
        let name = UITextField()
        name.font = UIFont.systemFont(ofSize: 16)
        name.enablesReturnKeyAutomatically = true
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .left
        name.attributedPlaceholder = NSAttributedString(string: "Name of Activity", attributes: [NSAttributedString.Key.foregroundColor: FalconPalette.defaultBlue])
        name.borderStyle = .roundedRect
        name.returnKeyType = .done
        name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        name.textColor = ThemeManager.currentTheme().generalTitleColor
        name.backgroundColor = .clear
        //        name.layer.masksToBounds = true
        //        name.layer.borderWidth = 1
        //        name.layer.borderColor = UIColor(red:230/255, green:230/255, blue:230/255, alpha:1).cgColor
        //        name.layer.cornerRadius = 5
        
        
        return name
    }()
    
    var activityType: UITextField = {
        let name = UITextField()
        name.font = UIFont.systemFont(ofSize: 16)
        name.enablesReturnKeyAutomatically = true
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .left
        name.attributedPlaceholder = NSAttributedString(string: "Type of Activity", attributes: [NSAttributedString.Key.foregroundColor: FalconPalette.defaultBlue])
        name.borderStyle = .roundedRect
        name.returnKeyType = .done
        name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        name.textColor = ThemeManager.currentTheme().generalTitleColor
        name.backgroundColor = .clear
        
        
        return name
    }()
    
    var activityParticipantsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red:230/255, green:230/255, blue:230/255, alpha:1).cgColor
        view.layer.cornerRadius = 5
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    let addParticipantsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Invitees"
        label.numberOfLines = 1
        label.textColor = FalconPalette.defaultBlue
        label.textAlignment = .left
        
        return label
    }()
    
    //    var activityLocationView: UIView = {
    //        let view = UIView()
    //        view.translatesAutoresizingMaskIntoConstraints = false
    //        view.contentMode = .scaleAspectFill
    //        view.layer.masksToBounds = true
    //        view.layer.borderWidth = 1
    //        view.layer.borderColor = UIColor(red:230/255, green:230/255, blue:230/255, alpha:1).cgColor
    //        view.layer.cornerRadius = 5
    //        view.isUserInteractionEnabled = true
    //
    //        return view
    //    }()
    
    //    let addLocationLabel: UILabel = {
    //        let label = UILabel()
    //        label.translatesAutoresizingMaskIntoConstraints = false
    //        label.text = "Location"
    //        label.numberOfLines = 1
    //        label.textColor = FalconPalette.defaultBlue
    //        label.textAlignment = .left
    //
    //        return label
    //    }()
    
    var activityLocation: UITextField = {
        let name = UITextField()
        name.font = UIFont.systemFont(ofSize: 16)
        name.enablesReturnKeyAutomatically = true
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textAlignment = .left
        name.attributedPlaceholder = NSAttributedString(string: "Location", attributes: [NSAttributedString.Key.foregroundColor: FalconPalette.defaultBlue])
        name.borderStyle = .roundedRect
        name.returnKeyType = .done
        name.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        name.textColor = ThemeManager.currentTheme().generalTitleColor
        name.backgroundColor = .clear
        
        
        return name
    }()
    
    
    lazy var activityImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red:230/255, green:230/255, blue:230/255, alpha:1).cgColor
        view.layer.cornerRadius = 5
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    let addPhotoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add Photo"
        label.numberOfLines = 1
        label.textColor = FalconPalette.defaultBlue
        label.textAlignment = .center
        
        return label
    }()
    
    let activityDescription: UITextView = {
        let activityDescription = UITextView()
        activityDescription.translatesAutoresizingMaskIntoConstraints = false
        activityDescription.layer.cornerRadius = 5
        activityDescription.layer.borderWidth = 1
        activityDescription.textAlignment = .left
        activityDescription.font = UIFont.systemFont(ofSize: 16)
        activityDescription.isScrollEnabled = false
        activityDescription.text = "Description"
        activityDescription.textContainerInset = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 0)
        activityDescription.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        activityDescription.backgroundColor = .clear
        activityDescription.textColor = FalconPalette.defaultBlue
        activityDescription.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        activityDescription.layer.borderColor = UIColor(red:230/255, green:230/255, blue:230/255, alpha:1).cgColor
        activityDescription.textContainer.lineBreakMode = .byTruncatingTail
        activityDescription.returnKeyType = .done
        
        return activityDescription
    }()
    
    //    let activityDescriptionPlaceholderLabel: UILabel = {
    //        let activityDescriptionPlaceholderLabel = UILabel()
    //        activityDescriptionPlaceholderLabel.text = "Description"
    //        activityDescriptionPlaceholderLabel.font = UIFont.systemFont(ofSize: 16)//(activityDescription.font!.pointSize - 1)
    //        activityDescriptionPlaceholderLabel.sizeToFit()
    //        activityDescriptionPlaceholderLabel.textAlignment = .left
    //        activityDescriptionPlaceholderLabel.backgroundColor = .clear
    //        activityDescriptionPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
    //        activityDescriptionPlaceholderLabel.textColor = FalconPalette.defaultBlue
    //
    //        return activityDescriptionPlaceholderLabel
    //    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        addSubview(activityName)
        addSubview(activityType)
        addSubview(activityParticipantsView)
        activityParticipantsView.addSubview(addParticipantsLabel)
        //        addSubview(activityLocationView)
        //        activityLocationView.addSubview(addLocationLabel)
        addSubview(activityLocation)
        addSubview(addPhotoLabel)
        addSubview(activityImageView)
        addSubview(activityDescription)
        //        activityDescription.addSubview(activityDescriptionPlaceholderLabel)
        
        
        NSLayoutConstraint.activate([
            activityName.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            activityType.topAnchor.constraint(equalTo: activityName.bottomAnchor, constant: 10),
            
            activityParticipantsView.topAnchor.constraint(equalTo: activityType.bottomAnchor, constant: 10),
            activityParticipantsView.widthAnchor.constraint(equalToConstant: 100),
            activityParticipantsView.heightAnchor.constraint(equalToConstant: 30),
            
            addParticipantsLabel.heightAnchor.constraint(equalTo: activityParticipantsView.heightAnchor),
            
            //            activityLocationView.topAnchor.constraint(equalTo: activityParticipantsView.bottomAnchor, constant: 10),
            //            activityLocationView.widthAnchor.constraint(equalToConstant: 100),
            //            activityLocationView.heightAnchor.constraint(equalToConstant: 30),
            
            
            //            addLocationLabel.heightAnchor.constraint(equalTo: activityLocationView.heightAnchor),
            
            activityLocation.topAnchor.constraint(equalTo: activityParticipantsView.bottomAnchor, constant: 10),
            
            activityImageView.topAnchor.constraint(equalTo: activityLocation.bottomAnchor, constant: 10),
            //            activityImageView.widthAnchor.constraint(equalToConstant: 200),
            activityImageView.heightAnchor.constraint(equalToConstant: 200),
            
            addPhotoLabel.topAnchor.constraint(equalTo: activityImageView.topAnchor),
            addPhotoLabel.widthAnchor.constraint(equalTo: activityImageView.widthAnchor),
            addPhotoLabel.heightAnchor.constraint(equalTo: activityImageView.heightAnchor),
            
            activityDescription.topAnchor.constraint(equalTo: activityImageView.bottomAnchor, constant: 10),
            //            activityDescriptionPlaceholderLabel.centerXAnchor.constraint(equalTo: activityDescription.centerXAnchor, constant: 0),
            //            activityDescriptionPlaceholderLabel.topAnchor.constraint(equalTo: activityImageView.bottomAnchor),
            //            activityDescriptionPlaceholderLabel.widthAnchor.constraint(equalTo: activityDescription.widthAnchor),
            //            activityDescriptionPlaceholderLabel.heightAnchor.constraint(equalTo: activityDescription.heightAnchor),
            ])
        
        
        //        activityDescriptionPlaceholderLabel.isHidden = !activityDescription.text!.isEmpty
        
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                activityName.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityName.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                activityType.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityType.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                activityParticipantsView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityParticipantsView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                addParticipantsLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 18),
                ////                addParticipantsLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                //                activityLocationView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                //                activityLocationView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                //                addLocationLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 18),
                activityLocation.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityLocation.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                activityImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityImageView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                addPhotoLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                addPhotoLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                activityDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
                activityDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                //                activityDescriptionPlaceholderLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 18),
                //                activityDescriptionPlaceholderLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
                ])
        } else {
            NSLayoutConstraint.activate([
                activityName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                activityName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                activityType.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                activityType.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                activityParticipantsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                activityParticipantsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                addParticipantsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                //                addParticipantsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                activityImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                activityImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                //                activityLocationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                //                activityLocationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                //                addLocationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                activityLocation.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                activityLocation.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                addPhotoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                addPhotoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                activityDescription.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                activityDescription.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                //                activityDescriptionPlaceholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
                //                activityDescriptionPlaceholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                ])
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

