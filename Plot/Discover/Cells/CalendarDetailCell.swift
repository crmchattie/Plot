//
//  CalendarDetailCell.swift
//  Plot
//
//  Created by Cory McHattie on 4/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol CalendarDetailCellDelegate: AnyObject {
    func locationViewTapped(labelText: String)
    func infoViewTapped()
    func participantsViewTapped(labelText: String)
    func startViewTapped(isHidden: String)
    func endViewTapped(isHidden: String)
    func startDateChanged(startDate: Date)
    func endDateChanged(endDate: Date)
    func reminderViewTapped(labelText: String)
    func nameChanged(labelText: String)
}

class CalendarDetailCell: UICollectionViewCell {
    
    weak var delegate: CalendarDetailCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
   
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameField: UITextField = {
        let textField = UITextField()
        textField.textColor = .label
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.placeholder = "Activity Name"
        textField.isUserInteractionEnabled = true
        textField.returnKeyType = .done
        textField.keyboardAppearance = .default
        textField.addDoneButtonOnKeyboard()
        textField.setRightPaddingPoints(15)
        textField.setLeftPaddingPoints(15)
        return textField
    }()
    
    let locationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let locationInfoView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        let smallConfiguration = UIImage.SymbolConfiguration(scale: .small)
        imageView.image = UIImage(systemName: "info.circle", withConfiguration: smallConfiguration)!.withRenderingMode(.alwaysTemplate)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let locationArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    let participantsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let participantsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let participantsArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    let startDateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let startLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Starts"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let startDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let startDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
            datePicker.tintColor = .systemBlue
            datePicker.sizeToFit()
        }
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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.text = "Ends"
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let endDateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let endDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
            datePicker.tintColor = .systemBlue
            datePicker.sizeToFit()
        }
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
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "Reminder"
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let rightReminderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "None"
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
   
    func setupViews() {
        
        nameField.delegate = self
                    
        if locationLabel.text == "Location" {
            locationLabel.textColor = .secondaryLabel
            locationInfoView.isHidden = true
        } else {
            locationLabel.textColor = .label
            locationInfoView.isHidden = false
        }
        
        nameField.constrainHeight(30)
                        
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
                
        let stackView = VerticalStackView(arrangedSubviews: [
            nameField,
            locationView,
            participantsView,
            startDateView,
            startDatePicker,
            endDateView,
            endDatePicker,
            reminderView
            ], spacing: 5)
        addSubview(stackView)
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let locationViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.locationViewTapped(_:)))
        locationView.addGestureRecognizer(locationViewTapped)
        
        let infoViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.infoViewTapped(_:)))
        locationInfoView.addGestureRecognizer(infoViewTapped)
        
        let participantsViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.participantsViewTapped(_:)))
        participantsView.addGestureRecognizer(participantsViewTapped)
        
        let startViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.startViewTapped(_:)))
        startDateView.addGestureRecognizer(startViewTapped)
        
        startDatePicker.addTarget(self, action: #selector(startDatePickerChanged(picker:)), for: .valueChanged)
        
        let endViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.endViewTapped(_:)))
        endDateView.addGestureRecognizer(endViewTapped)
        
        endDatePicker.addTarget(self, action: #selector(endDatePickerChanged(picker:)), for: .valueChanged)
        
        let reminderViewTapped = UITapGestureRecognizer(target: self, action: #selector(CalendarDetailCell.reminderViewTapped(_:)))
        reminderView.addGestureRecognizer(reminderViewTapped)
            
    }
        
    @objc func locationViewTapped(_ sender: UITapGestureRecognizer) {
        guard let labelText = locationLabel.text else {
            return
        }
        
        if labelText == "Location" {
            locationLabel.textColor = .secondaryLabel
            locationInfoView.isHidden = true
        } else {
            locationLabel.textColor = .label
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
            startDateLabel.textColor = .secondaryLabel
        }
        self.delegate?.startViewTapped(isHidden: "\(startDatePicker.isHidden)")
    }
    
    @objc func endViewTapped(_ sender: UITapGestureRecognizer) {
        endDatePicker.isHidden = !endDatePicker.isHidden
        if !endDatePicker.isHidden {
            endDateLabel.textColor = FalconPalette.defaultBlue
            startDatePicker.isHidden = true
        } else {
            endDateLabel.textColor = .secondaryLabel
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

extension CalendarDetailCell: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text == "" || textField.text == nil {
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            self.delegate?.nameChanged(labelText: text)
        }
    }
    
    
}
