//
//  ActivityExpandedDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 4/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivityExpandedDetailCellDelegate: class {
    func locationViewTapped(labelText: String)
    func infoViewTapped()
    func participantsViewTapped(labelText: String)
    func startViewTapped(isHidden: String)
    func endViewTapped(isHidden: String)
    func startDateChanged(startDate: Date)
    func endDateChanged(endDate: Date)
    func reminderViewTapped(labelText: String)
}

class ActivityExpandedDetailCell: UICollectionViewCell {
    
    var recipe: Recipe! {
        didSet {
            if let _ = recipe {
                extraLabel.text = nil
                extraLabel.isHidden = true
                setupViews()

            }
        }
    }
    
    var event: Event! {
        didSet {
            if let _ = event {
                extraLabel.text = "Other Dates:"
                setupViews()
            }
        }
    }
    
    var attraction: Attraction! {
        didSet {
            if attraction != nil {
                extraLabel.text = "Other Dates:"
                setupViews()
            }
        }
    }
    
    var workout: Workout! {
        didSet {
            if let _ = workout {                
                extraLabel.text = "Workout Preview:"
                setupViews()

            }
        }
    }
    
    var fsVenue: FSVenue! {
        didSet {
            if let _ = recipe {
                extraLabel.text = nil
                extraLabel.isHidden = true
                setupViews()

            }
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
    
    let locationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let locationInfoView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            let smallConfiguration = UIImage.SymbolConfiguration(scale: .small)
            imageView.image = UIImage(systemName: "info.circle", withConfiguration: smallConfiguration)!.withRenderingMode(.alwaysTemplate)
        } else {
            imageView.image = UIImage(named: "info")!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = FalconPalette.defaultBlue
        }
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let locationArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalSubtitleColor
        return imageView
    }()
    
    let participantsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let participantsLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let participantsArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalSubtitleColor
        return imageView
    }()
    
    let startDateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let startLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Starts"
        return label
    }()
    
    let startDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let startDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = .clear
        datePicker.tintColor = .clear
        datePicker.datePickerMode = UIDatePicker.Mode.dateAndTime
        datePicker.minuteInterval = 5
        datePicker.isHidden = true
        datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return datePicker
    }()
    
    let endDateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let endLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Ends"
        return label
    }()
    
    let endDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
    
    let endDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = .clear
        datePicker.tintColor = .clear
        datePicker.datePickerMode = UIDatePicker.Mode.dateAndTime
        datePicker.minuteInterval = 5
        datePicker.isHidden = true
        datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        return datePicker
    }()
    
    let reminderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let leftReminderLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "Reminder"
        label.numberOfLines = 1
        return label
    }()
    
    let rightReminderLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "None"
        label.numberOfLines = 1
        return label
    }()
    
    let extraLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        return label
    }()
   
    func setupViews() {
        
            
        if locationLabel.text == "Location" {
            locationLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
            locationInfoView.isHidden = true
        } else {
            locationLabel.textColor = ThemeManager.currentTheme().generalTitleColor
            locationInfoView.isHidden = false
        }
        
        locationView.constrainHeight(30)
        locationArrowView.constrainWidth(16)
        locationArrowView.constrainHeight(16)
        locationInfoView.constrainWidth(30)
        locationInfoView.constrainHeight(30)
        
        participantsView.constrainHeight(30)
        participantsArrowView.constrainWidth(16)
        participantsArrowView.constrainHeight(16)
        
        startDateView.constrainHeight(30)
        startDatePicker.constrainHeight(200)
        
        endDateView.constrainHeight(30)
        endDatePicker.constrainHeight(200)
        
        reminderView.constrainHeight(30)
        
        locationView.addSubview(locationLabel)
        locationView.addSubview(locationArrowView)
        locationView.addSubview(locationInfoView)
        locationLabel.anchor(top: locationView.topAnchor, leading: locationView.leadingAnchor, bottom: nil, trailing: locationInfoView.leadingAnchor, padding: .init(top: 0, left: 15, bottom: 0, right: 0))
        locationArrowView.anchor(top: nil, leading: nil, bottom: nil, trailing: locationView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        locationArrowView.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor).isActive = true
        locationInfoView.anchor(top: nil, leading: nil, bottom: nil, trailing: locationArrowView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        locationInfoView.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor).isActive = true
        
        participantsView.addSubview(participantsLabel)
        participantsView.addSubview(participantsArrowView)
        participantsLabel.anchor(top: participantsView.topAnchor, leading: participantsView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 15, bottom: 0, right: 0))
        participantsArrowView.anchor(top: nil, leading: nil, bottom: nil, trailing: participantsView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        participantsArrowView.centerYAnchor.constraint(equalTo: participantsLabel.centerYAnchor).isActive = true
        
        startDateView.addSubview(startLabel)
        startDateView.addSubview(startDateLabel)
        startLabel.anchor(top: startDateView.topAnchor, leading: startDateView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 15, bottom: 0, right: 0))
        startDateLabel.anchor(top: startDateView.topAnchor, leading: nil, bottom: nil, trailing: startDateView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        
        endDateView.addSubview(endLabel)
        endDateView.addSubview(endDateLabel)
        endLabel.anchor(top: endDateView.topAnchor, leading: endDateView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 15, bottom: 0, right: 0))
        endDateLabel.anchor(top: endDateView.topAnchor, leading: nil, bottom: nil, trailing: endDateView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        
        reminderView.addSubview(leftReminderLabel)
        reminderView.addSubview(rightReminderLabel)
        leftReminderLabel.anchor(top: reminderView.topAnchor, leading: reminderView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 15, bottom: 0, right: 0))
        rightReminderLabel.anchor(top: reminderView.topAnchor, leading: nil, bottom: nil, trailing: reminderView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 15))
        
        let extraLabelStackView = UIStackView(arrangedSubviews: [extraLabel])
        extraLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        extraLabelStackView.isLayoutMarginsRelativeArrangement = true
        
        let stackView = VerticalStackView(arrangedSubviews: [
            locationView,
            participantsView,
            startDateView,
            startDatePicker,
            endDateView,
            endDatePicker,
            reminderView,
            extraLabelStackView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        
        let locationViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.locationViewTapped(_:)))
        locationView.addGestureRecognizer(locationViewTapped)
        
        let infoViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.infoViewTapped(_:)))
        locationInfoView.addGestureRecognizer(infoViewTapped)
        
        let participantsViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.participantsViewTapped(_:)))
        participantsView.addGestureRecognizer(participantsViewTapped)
        
        let startViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.startViewTapped(_:)))
        startDateView.addGestureRecognizer(startViewTapped)
        
        startDatePicker.addTarget(self, action: #selector(startDatePickerChanged(picker:)), for: .valueChanged)
        
        let endViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.endViewTapped(_:)))
        endDateView.addGestureRecognizer(endViewTapped)
        
        endDatePicker.addTarget(self, action: #selector(endDatePickerChanged(picker:)), for: .valueChanged)
        
        let reminderViewTapped = UITapGestureRecognizer(target: self, action: #selector(ActivityExpandedDetailCell.reminderViewTapped(_:)))
        reminderView.addGestureRecognizer(reminderViewTapped)
            
    }
        
    @objc func locationViewTapped(_ sender: UITapGestureRecognizer) {
        guard let labelText = locationLabel.text else {
            return
        }
        
        print("locationLabel \(labelText)")
        if labelText == "Location" {
            locationLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
            locationInfoView.isHidden = true
        } else {
            locationLabel.textColor = ThemeManager.currentTheme().generalTitleColor
            locationInfoView.isHidden = false
        }
        
        self.delegate?.locationViewTapped(labelText: labelText)
    }
    
    @objc func infoViewTapped(_ sender: UITapGestureRecognizer) {
        self.delegate?.infoViewTapped()
        
    }
    
    @objc func participantsViewTapped(_ sender: UITapGestureRecognizer) {
        guard let labelText = participantsLabel.text else {
            return
        }
        self.delegate?.participantsViewTapped(labelText: labelText)
    }
    
    @objc func startDatePickerChanged(picker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        startDateLabel.text = dateFormatter.string(from: picker.date)
        self.delegate?.startDateChanged(startDate: picker.date)
        
        if picker.date > endDatePicker.date {
            endDateLabel.text = dateFormatter.string(from: picker.date)
            endDatePicker.date = picker.date
        }
    }
    
    @objc func endDatePickerChanged(picker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        endDateLabel.text = dateFormatter.string(from: picker.date)
        self.delegate?.endDateChanged(endDate: picker.date)
        
        if picker.date < startDatePicker.date {
            startDateLabel.text = dateFormatter.string(from: picker.date)
            startDatePicker.date = picker.date
        }
    }
    
    @objc func startViewTapped(_ sender: UITapGestureRecognizer) {
        startDatePicker.isHidden = !startDatePicker.isHidden
        if !startDatePicker.isHidden {
            startDateLabel.textColor = FalconPalette.defaultBlue
            endDatePicker.isHidden = true
        } else {
            startDateLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        self.delegate?.startViewTapped(isHidden: "\(startDatePicker.isHidden)")
    }
    
    @objc func endViewTapped(_ sender: UITapGestureRecognizer) {
        endDatePicker.isHidden = !endDatePicker.isHidden
        if !endDatePicker.isHidden {
            endDateLabel.textColor = FalconPalette.defaultBlue
            startDatePicker.isHidden = true
        } else {
            endDateLabel.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        self.delegate?.startViewTapped(isHidden: "\(endDatePicker.isHidden)")
    }
    
    @objc func reminderViewTapped(_ sender: UITapGestureRecognizer) {
        guard let labelText = rightReminderLabel.text else {
            return
        }
        self.delegate?.reminderViewTapped(labelText: labelText)
    }
}
