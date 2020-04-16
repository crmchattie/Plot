//
//  CreateActivityViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/28/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import Eureka
import SplitRow
import ViewRow
import EventKit
import UserNotifications
import CodableFirebase


class CreateActivityViewController: FormViewController {
    var activity: Activity!
    var invitation: Invitation?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    var conversations = [Conversation]()
    var activities = [Activity]()
    var conversation: Conversation!
    let avatarOpener = AvatarOpener()
    var locationName : String = "locationName"
    var locationAddress = [String : [Double]]()
    var scheduleList = [Activity]()
    var purchaseList = [Purchase]()
    var purchaseDict = [User: Double]()
    var checklistDict = [String: [String : Bool]]()
    var scheduleIndex: Int = 0
    var purchaseIndex: Int = 0
    var startDateTime: Date?
    var endDateTime: Date?
    var userNames : [String] = []
    var userNamesString: String = ""
    var thumbnailImage: String = ""
    var activityID = String()
    let dispatchGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    // Participants with accepted invites
    var acceptedParticipant: [User] = []
    
    fileprivate var reminderDate: Date?
    
    var active = false
    var includeSubSections = true
    var sentActivity = false
    
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBarView = UIView()
        view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusBarView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            statusBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            statusBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        statusBarView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        setupMainView()
        
        if activity != nil {
            active = true
            if activity.activityID != nil {
                activityID = activity.activityID!
            }
            if let localName = activity.locationName, localName != "locationName", let localAddress = activity.locationAddress {
                locationName = localName
                locationAddress = localAddress
            }
            if activity.schedule != nil {
                for schedule in activity.schedule! {
                    if schedule.name == "nothing" { continue }
                    scheduleList.append(schedule)
                    guard let localAddress = schedule.locationAddress else { continue }
                    for (key, value) in localAddress {
                        locationAddress[key] = value
                    }
                }
                sortSchedule()
            }
            if activity.purchases != nil {
                for purchase in activity.purchases! {
                    if purchase.name == "nothing" { continue }
                    purchaseList.append(purchase)
                }
            }
            if activity.checklist != nil && activity.checklist!["name"] == nil {
                checklistDict = activity.checklist!
            }
            setupRightBarButton(with: "Update")
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                //create new activityID for auto updating items (schedule, purchases, checklist)
                activityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(dictionary: ["activityID": activityID as AnyObject])
//                activity.activityType = newActivityType.rawValue.capitalized
                setupRightBarButton(with: "Create")
            }
        }
        
        initializeForm()
        
        var participantCount = self.acceptedParticipant.count
        // If user is creating this activity (admin)
        if activity.admin == nil || activity.admin == Auth.auth().currentUser?.uid {
            participantCount += 1
        }
        
        if participantCount > 1 {
            self.userNamesString = "\(participantCount) participants"
        } else {
            self.userNamesString = "1 participant"
        }
        
        if let inviteesRow: ButtonRow = self.form.rowBy(tag: "Participants") {
            inviteesRow.title = self.userNamesString
            inviteesRow.updateCell()
        }
        
        for user in self.acceptedParticipant {
            guard let currentUserID = Auth.auth().currentUser?.uid, let userID = user.id, currentUserID != userID else { continue }
            self.purchaseDict[user] = 0.00
            self.decimalRowFunc()
            self.purchaseBreakdown()
            self.updateDecimalRow()
        }
    }
    
    fileprivate func setupMainView() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Activity"
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    func setupRightBarButton(with title: String) {
        if title == "Create" || sentActivity {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = plusBarButton
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if !sentActivity {
            let dotsImage = UIImage(named: "dots")
            if #available(iOS 11.0, *) {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewActivity))
                
                let dotsBarButton = UIButton(type: .system)
                dotsBarButton.setImage(dotsImage, for: .normal)
                dotsBarButton.addTarget(self, action: #selector(goToExtras), for: .touchUpInside)
                                
                navigationItem.rightBarButtonItems = [plusBarButton, UIBarButtonItem(customView: dotsBarButton)]
            } else {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewActivity))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            }
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
            <<< ViewRow<UIImageView>("Activity Image")
                .cellSetup { (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor

                    //  Make the image view occupy the entire row:
                    cell.viewRightMargin = 0.0
                    cell.viewLeftMargin = 0.0
                    cell.viewTopMargin = 0.0
                    cell.viewBottomMargin = 0.0
                    
                    cell.height = { return CGFloat(44) }
                    
                    row.title = "Cover Photo"
                    cell.titleLeftMargin = 20.0
                    cell.titleLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
//                    //  Construct the view for the cell
                    cell.view = UIImageView()
                    cell.view!.contentMode = .scaleAspectFill //.scaleAspectFit
                    cell.view!.clipsToBounds = true
                    cell.contentView.addSubview(cell.view!)
                    
                    if self.active && self.activity.activityOriginalPhotoURL != "" && self.activity.activityOriginalPhotoURL != nil {
                        cell.height = { return CGFloat(300) }
                        row.title = nil
                        cell.view!.sd_setImage(with: URL(string:self.activity.activityOriginalPhotoURL!), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                        })
                        self.activityAvatarURL = self.activity.activityOriginalPhotoURL!
                        self.thumbnailImage = self.activity.activityThumbnailPhotoURL!

                    } else {
                        self.activityAvatarURL = ""
                    }
                }.onCellSelection { ViewCell, ViewRow in
                    self.openActivityPicture()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.titleLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Activity Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active {
                    $0.value = self.activity.name
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    $0.cell.textField.becomeFirstResponder()
                }
                }.onChange() { [unowned self] row in
                    self.activity.name = row.value
                    if row.value == nil {
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    } else {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
//            <<< TextAreaRow("Activity Name") {
//            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//            $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//            $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//            $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//            $0.placeholder = $0.tag
//            $0.textAreaHeight = .dynamic(initialTextViewHeight: 200)
//            if self.active {
//                $0.value = self.activity.name
//                self.navigationItem.rightBarButtonItem?.isEnabled = true
//            } else {
//                $0.cell.textView.becomeFirstResponder()
//            }
//            }.cellUpdate({ (cell, row) in
//                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
//                cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//            }).onChange() { [unowned self] row in
//                self.activity.name = row.value
//                if row.value == nil {
//                    self.navigationItem.rightBarButtonItem?.isEnabled = false
//                } else {
//                    self.navigationItem.rightBarButtonItem?.isEnabled = true
//                }
//            }
            
            <<< TextRow("Activity Type") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityType != "nothing" && self.activity.activityType != nil {
                    $0.value = self.activity.activityType
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                }.onChange() { [unowned self] row in
                    self.activity.activityType = row.value
                }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityDescription != "nothing" && self.activity.activityDescription != nil {
                    $0.value = self.activity.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }).onChange() { [unowned self] row in
                    self.activity.activityDescription = row.value
                }
            
            <<< ButtonRow("Photos") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                }.onCellSelection({ _,_ in
                    self.openPhotos()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.accessoryType = .disclosureIndicator
                    cell.textLabel?.textAlignment = .left
                    if self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
            
            <<< ButtonRow("Location") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active, let localName = activity.locationName, localName != "locationName" {
                    row.cell.accessoryType = .detailDisclosureButton
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = localName
                }
                }.onCellSelection({ _,_ in
                    self.openLocationFinder()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Location" {
                        cell.accessoryType = .disclosureIndicator
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else if let value = row.title, !value.isEmpty {
                        cell.accessoryType = .detailDisclosureButton
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    } else {
                        cell.accessoryType = .disclosureIndicator
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        cell.textLabel?.text = "Location"
                    }
                }
            
            <<< ButtonRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.acceptedParticipant.count > 0 {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = self.userNamesString
                }
                }.onCellSelection({ _,_ in
                    self.openParticipantsInviter()
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Participants" {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
            
//            <<< ActionSheetRow<String>("Transportation") {
//                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                $0.title = $0.tag
//                $0.selectorTitle = "How are you getting there?"
//                $0.options = ["None", "Car", "Flight", "Train", "Bus", "Subway", "Bike/Scooter", "Walk"]
//                if self.active && self.activity.transportation != "nothing" && self.activity.transportation != nil {
//                    $0.value = self.activity.transportation
//                }
//                }
//                .onPresent { from, to in
//                    to.popoverPresentationController?.permittedArrowDirections = .up
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//
//                }.onChange() { [unowned self] row in
//                    self.activity.transportation = row.value
//                }
            
            <<< SwitchRow("All-day") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if self.active {
                    $0.value = self.activity.allDay
                } else {
                    $0.value = false
                    self.activity.allDay = $0.value
                }
                }.onChange { [weak self] row in
                    self!.activity.allDay = row.value
                    
                    let startDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    let endDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    
                    if row.value ?? false {
                        startDate.dateFormatter?.dateStyle = .full
                        startDate.dateFormatter?.timeStyle = .none
                        endDate.dateFormatter?.dateStyle = .full
                        endDate.dateFormatter?.timeStyle = .none
                    }
                    else {
                        startDate.dateFormatter?.dateStyle = .full
                        startDate.dateFormatter?.timeStyle = .short
                        endDate.dateFormatter?.dateStyle = .full
                        endDate.dateFormatter?.timeStyle = .short
                    }
                    startDate.updateCell()
                    endDate.updateCell()
                    startDate.inlineRow?.updateCell()
                    endDate.inlineRow?.updateCell()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            
            //add Soon option to replace time; will require update to end time as well
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .full
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
                    
                    if self.activity.allDay == true {
                        $0.dateFormatter?.dateStyle = .full
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.dateStyle = .full
                        $0.dateFormatter?.timeStyle = .short
                    }
                    
                    $0.updateCell()
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
                    self.activity.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.startDateTime = $0.value
                }
                .onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    if row.value?.compare(endRow.value!) == .orderedDescending {
                        endRow.value = Date(timeInterval: 0, since: row.value!)
                        endRow.updateCell()
                    }
                    self!.activity.startDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    self!.startDateTime = row.value
                    if self!.active {
                        self!.scheduleReminder()
                    }
                }
                .onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
            }
            
            <<< DateTimeInlineRow("Ends"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.dateFormatter?.dateStyle = .full
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.value = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
                    if self.activity.allDay == true {
                        $0.dateFormatter?.dateStyle = .full
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.dateStyle = .full
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                    
                } else {
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    let timezone = TimeZone.current
                    let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                    $0.value = rounded.addingTimeInterval(seconds)
                    self.activity.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.endDateTime = $0.value
                }
                .onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        startRow.value = Date(timeInterval: 0, since: row.value!)
                        startRow.updateCell()
                    }
                    self!.activity.endDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    self!.endDateTime = row.value
                }
                .onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate { cell, dateRow in
                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
            }
            
            <<< AlertRow<EventAlert>("Reminder") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.selectorTitle = $0.tag
                if self.active && self.activity.reminder != nil {
                    if let value = self.activity.reminder {
                        $0.value = EventAlert(rawValue: value)
                    }
                } else {
                    $0.value = .None
                    if let reminder = $0.value?.description {
                        self.activity.reminder = reminder
                    }
                }
                $0.options = EventAlert.allValues
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
                }.onChange() { [unowned self] row in
                    if let reminder = row.value?.description {
                        self.activity.reminder = reminder
                        if self.active {
                            self.scheduleReminder()
                        }
                    }
                }

            <<< TextAreaRow("Notes") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.notes != "nothing" && self.activity.notes != nil {
                    $0.value = self.activity.notes
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }).onChange() { [unowned self] row in
                    self.activity.notes = row.value
                }
            
//            <<< ActionSheetRow<String>("Export") {
//                $0.cell.textLabel?.textAlignment = .center
//                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                $0.cell.textLabel?.textColor = FalconPalette.defaultBlue
//                $0.cell.detailTextLabel?.textColor = FalconPalette.defaultBlue
//                $0.title = "Export Activity to Calendar"
//                $0.selectorTitle = "Which Calendar?"
//                $0.options = ["iCal"]
////                $0.options = ["iCal", "Google Calendar", "Outlook"]
//                if self.active && self.activity.calendarExport == true {
//                    $0.value = "Exported"
//                }
//                }
//                .onPresent { from, to in
//                    to.popoverPresentationController?.permittedArrowDirections = .up
//                }.cellUpdate { cell, row in
//                    cell.textLabel?.textAlignment = .center
//                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//                    cell.textLabel?.textColor = FalconPalette.defaultBlue
//                    cell.detailTextLabel?.textColor = FalconPalette.defaultBlue
//                }.onChange({ row in
//                    if row.value == "iCal" {
//                        self.addEventToiCal()
//                        row.value = "Exported"
//                    } else if row.value == "Google Calendar" {
//                        row.value = "Exported"
//                    } else {
//                        row.value = "Exported"
//                    }
//                })
            
            <<< SegmentedRow<String>("sections"){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.hidden = Condition.init(booleanLiteral: !includeSubSections)
                    if #available(iOS 13.0, *) {
                        $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                    } else {
                        // Fallback on earlier versions
                    }
                    $0.options = ["Schedule", "Checklist", "Purchases"]
                    if includeSubSections {
                        $0.value = "Schedule"
                    } else {
                        $0.value = "Hidden"
                    }
                    }
                    .onCellSelection({_,_  in
                        if let indexPath = self.form.allRows.last?.indexPath {
                            self.tableView?.scrollToRow(at: indexPath, at: .none, animated: true)
                        }
                    })
            addSubSections()
    }
    
    func addSubSections() {
        //            add in schedule that will be a MultivaluedSection that will lead to another VC with a form that includes item name, start/end time, location, transportation and notes sections - sorted by date/time
        //            or add in a custom row that shows/hides point options (name, start/end time, location and notes sections)
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Schedule",
                               footer: "Add a new point in the schedule") {
                                $0.tag = "schedulefields"
                                $0.hidden = "$sections != 'Schedule'"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.title = "Add New Point"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            cell.height = { 60 }
                                        }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.scheduleIndex = index
                                    self.openSchedule()
                                    return ScheduleRow()
                                        .onCellSelection() { cell, row in
                                        self.scheduleIndex = index
                                        self.openSchedule()
                                        cell.cellResignFirstResponder()
    //                                            self.tableView.endEditing(true)
                                    }
                                }
                                
            }
                                for schedule in scheduleList {
                                    var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
                                    mvs.insert(ScheduleRow() {
                                        $0.value = schedule
                                        }.onCellSelection() { cell, row in
                                            self.scheduleIndex = row.indexPath!.row
                                            self.openSchedule()
                                            cell.cellResignFirstResponder()
    //                                                self.tableView.endEditing(true)
                                    }, at: mvs.count - 1)
                                    
                                }

    form +++
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
                           header: "Checklist",
                           footer: "Add a checklist item") {
                            $0.tag = "checklistfields"
                            $0.hidden = "$sections != 'Checklist'"
                            $0.addButtonProvider = { section in
                                return ButtonRow(){
                                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    $0.title = "Add New Item"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                        
                                }
                            }
                            $0.multivaluedRowToInsertAt = { index in
                                return SplitRow<TextRow, CheckRow>(){
                                    $0.rowLeftPercentage = 0.75
                                    $0.rowLeft = TextRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        $0.placeholder = "Item"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                    }
                                    
                                    $0.rowRight = CheckRow() {
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.cell.tintColor = FalconPalette.defaultBlue
                                        $0.value = false
                                        $0.cell.accessoryType = .checkmark
                                        $0.cell.tintAdjustmentMode = .dimmed
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.tintColor = FalconPalette.defaultBlue
                                            if row.value == false {
                                                cell.accessoryType = .checkmark
                                                cell.tintAdjustmentMode = .dimmed
                                            } else {
                                                cell.tintAdjustmentMode = .automatic
                                            }
                                    }
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    }.onChange() { _ in
                                        self.updateLists(type: "checklist")
                                }
                                
                            }
                            
    }
                                for (_, value) in checklistDict {
                                    var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                                    mvs.insert(SplitRow<TextRow, CheckRow>() {
                                        $0.rowLeftPercentage = 0.75
                                        $0.rowLeft = TextRow(){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                            $0.value = value.keys.first
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        }
                                        $0.rowRight = CheckRow() {
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            $0.cell.tintColor = FalconPalette.defaultBlue
                                            $0.value = value.values.first
                                            $0.cell.accessoryType = .checkmark
                                            $0.cell.tintAdjustmentMode = .dimmed
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.tintColor = FalconPalette.defaultBlue
                                                if row.value == false {
                                                    cell.accessoryType = .checkmark
                                                    cell.tintAdjustmentMode = .dimmed
                                                } else {
                                                    cell.tintAdjustmentMode = .automatic
                                                }
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        }.onChange() { _ in
                                            self.updateLists(type: "checklist")
                                    } , at: mvs.count - 1)
                                    
                                }

        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Purchases",
                               footer: "Add a purchase that can be split among participants") {
                                $0.tag = "purchasefields"
                                $0.hidden = "$sections != 'Purchases'"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        $0.title = "Add New Purchase"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            cell.height = { 60 }
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.purchaseIndex = index
                                    self.openPurchases()
                                    return PurchaseRow()
                                        .onCellSelection() { cell, row in
                                            self.purchaseIndex = index
                                            self.openPurchases()
                                            cell.cellResignFirstResponder()
    //                                                self.tableView.endEditing(true)
                                    }
                                    
                                }
            }
                                for purchase in purchaseList {
                                    var mvs = (form.sectionBy(tag: "purchasefields") as! MultivaluedSection)
                                    mvs.insert(PurchaseRow() {
                                        $0.value = purchase
                                        }.onCellSelection() { cell, row in
                                            self.purchaseIndex = row.indexPath!.row
                                            self.openPurchases()
                                            cell.cellResignFirstResponder()
    //                                                self.tableView.endEditing(true)
                                    }, at: mvs.count - 1)
                                    
                                }

                                form +++
                                    Section(header: "Balances",
                                            footer: "Positive Balance = Receipt; Negative Balance = Payment") {
                                                $0.tag = "Balances"
                                                $0.hidden = "$sections != 'Purchases'"
                                }
    }
    
    func decimalRowFunc() {
        var mvs = form.sectionBy(tag: "Balances")
        for user in acceptedParticipant {
            if let userName = user.name, let _ : DecimalRow = form.rowBy(tag: "\(userName)") {
                continue
            } else {
                purchaseDict[user] = 0.00
                if let mvsValue = mvs {
                    mvs?.insert(DecimalRow(user.name) {
                        $0.hidden = "$sections != 'Purchases'"
                        $0.tag = user.name
                        $0.useFormatterDuringInput = true
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.title = user.name
                        $0.value = 0.00
                        $0.baseCell.isUserInteractionEnabled = false
                        let formatter = CurrencyFormatter()
                        formatter.locale = .current
                        formatter.numberStyle = .currency
                        $0.formatter = formatter
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor

                    }, at: mvsValue.count)
                }
            }
        }
        for (key, _) in purchaseDict {
            if !acceptedParticipant.contains(key) {
                let sectionMVS : SegmentedRow<String> = form.rowBy(tag: "sections")!
                sectionMVS.value = "Purchases"
                sectionMVS.updateCell()
                purchaseDict[key] = nil
                if let decimalRow : DecimalRow = form.rowBy(tag: "\(key.name!)") {
                    mvs!.remove(at: decimalRow.indexPath!.row)
                }
            }
        }
    }
    
    func purchaseBreakdown() {
        purchaseDict = [User: Double]()
        for user in acceptedParticipant {
            purchaseDict[user] = 0.00
        }
        guard let currentUser = Auth.auth().currentUser else { return }
        for purchase in purchaseList {
            let costPerPerson = purchase.cost! / Double(purchase.participantsIDs!.count)
            if purchase.participantsIDs![0] == currentUser.uid {
                for ID in purchase.participantsIDs!{
                    if let user = acceptedParticipant.first(where: {$0.id == ID}) {
                        var value = purchaseDict[user] ?? 0.00
                        value += costPerPerson
                        purchaseDict[user] = value
                    }
                }
            } else {
                let ID = purchase.participantsIDs![0]
                if let user = acceptedParticipant.first(where: {$0.id == ID}) {
                    var value = purchaseDict[user] ?? 0.00
                    value -= costPerPerson
                    purchaseDict[user] = value
                }
            }
        }
    }
    
    func updateDecimalRow() {
        for (user, value) in purchaseDict {
            if let userName = user.name, let decimalRow : DecimalRow = form.rowBy(tag: "\(userName)") {
                decimalRow.value = value
                decimalRow.updateCell()
            }
        }
    }
    
    @objc(tableView:accessoryButtonTappedForRowWithIndexPath:) func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let latitude = locationAddress[locationName]?[0], let longitude = locationAddress[locationName]?[1] else {
            return
        }
        
        let ceo: CLGeocoder = CLGeocoder()
        let loc: CLLocation = CLLocation(latitude:latitude, longitude: longitude)
        var addressString : String = ""
        ceo.reverseGeocodeLocation(loc) { (placemark, error) in
            if error != nil {
                return
            }
            let place = placemark![0]
            if place.subThoroughfare != nil {
                addressString = addressString + place.subThoroughfare! + " "
            }
            if place.thoroughfare != nil {
                addressString = addressString + place.thoroughfare! + ", "
            }
            if place.locality != nil {
                addressString = addressString + place.locality! + ", "
            }
            if place.country != nil {
                addressString = addressString + place.country! + ", "
            }
            if place.postalCode != nil {
                addressString = addressString + place.postalCode!
            }
            
            let alertController = UIAlertController(title: self.locationName, message: addressString, preferredStyle: .alert)
            let mapAddress = UIAlertAction(title: "Map Address", style: .default) { (action:UIAlertAction) in
                self.goToMap()
            }
            let copyAddress = UIAlertAction(title: "Copy Address", style: .default) { (action:UIAlertAction) in
                let pasteboard = UIPasteboard.general
                pasteboard.string = addressString
            }
            let changeAddress = UIAlertAction(title: "Change Address", style: .default) { (action:UIAlertAction) in
                self.openLocationFinder()
            }
            let removeAddress = UIAlertAction(title: "Remove Address", style: .default) { (action:UIAlertAction) in
                if let locationRow: ButtonRow = self.form.rowBy(tag: "Location") {
                    self.locationAddress[self.locationName] = nil
                    if let localAddress = self.activity.locationAddress, localAddress[self.locationName] != nil {
                        self.activity.locationAddress![self.locationName] = nil
                    }
                    self.activity.locationName = "locationName"
                    self.locationName = "locationName"
                    locationRow.title = "Location"
                    locationRow.updateCell()
                }
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                print("You've pressed cancel")
                
            }
            alertController.addAction(mapAddress)
            alertController.addAction(copyAddress)
            alertController.addAction(changeAddress)
            alertController.addAction(removeAddress)
            alertController.addAction(cancelAlert)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }

    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let rowType = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if rowType is ScheduleRow {
                if self!.scheduleList.indices.contains(self!.scheduleIndex) {
                    if let scheduleLocationAddress = self!.scheduleList[rowNumber].locationAddress {
                        for (key, _) in scheduleLocationAddress {
                            self!.locationAddress[key] = nil
                        }
                    }
                    self!.scheduleList.remove(at: rowNumber)
                    self!.sortSchedule()
                    self!.updateLists(type: "schedule")
                }
            } else if rowType is PurchaseRow {
                if self!.purchaseList.indices.contains(self!.purchaseIndex) {
                    self!.purchaseList.remove(at: rowNumber)
                    self!.purchaseBreakdown()
                    self!.updateDecimalRow()
                }
                self!.updateLists(type: "purchases")
            } else {
                self!.updateLists(type: "checklist")
            }
        }
    }
    
    fileprivate func openActivityPicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpening(avatarView: viewRow.cell.view!, at: self,
                                         isEditButtonEnabled: true, title: .activity)
        
    }
    
    fileprivate func sortSchedule() {
        scheduleList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime!.int64Value < schedule2.startDateTime!.int64Value
        }
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            if mvs.count == 1 {
                return
            }
            for index in 0...mvs.count - 2 {
                let scheduleRow = mvs.allRows[index]
                scheduleRow.baseValue = scheduleList[index]
                scheduleRow.updateCell()
            }
        }
    }
    
    fileprivate func updateLists(type: String) {
        if type == "schedule" {
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            if scheduleList.isEmpty {
                activity.schedule = [Activity]()
                groupActivityReference.child("schedule").removeValue()
            } else {
                var firebaseScheduleList = [[String: AnyObject?]]()
                for schedule in scheduleList {
                    let firebaseSchedule = schedule.toAnyObject()
                    firebaseScheduleList.append(firebaseSchedule)
                }
                activity.schedule = scheduleList
                groupActivityReference.updateChildValues(["schedule": firebaseScheduleList as AnyObject])
            }
        } else if type == "purchases" {
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            if purchaseList.isEmpty {
                activity.purchases = [Purchase]()
                groupActivityReference.child("purchases").removeValue()
            } else {
                var firebasePurchaseList = [[String: AnyObject?]]()
                for purchase in purchaseList {
                    let firebasePurchase = purchase.toAnyObject()
                    firebasePurchaseList.append(firebasePurchase)
                }
                activity.purchases = purchaseList
                groupActivityReference.updateChildValues(["purchases": firebasePurchaseList as AnyObject])
            }
        } else {
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            if let mvs = (form.values()["checklistfields"] as? [Any?])?.compactMap({ $0 }) {
                if !mvs.isEmpty {
                    checklistDict = [String: [String : Bool]]()
                    var index = 1
                    for element in mvs {
                        let value = element as! SplitRowValue<Swift.String, Swift.Bool>
                        if let text = value.left, let state = value.right {
                            checklistDict["checklist_\(index)"] = [text : state]
                        }
                        index += 1
                    }
                    activity.checklist = checklistDict
                    groupActivityReference.updateChildValues(["checklist": checklistDict as AnyObject])
                } else {
                    activity.checklist = [String: [String : Bool]]()
                    groupActivityReference.child("checklist").removeValue()
                }
            }
        }
        let membersIDs = fetchMembersIDs()
        incrementBadgeForReciever(activityID: activityID, participantsIDs: membersIDs.0)
    }
    
    func addEventToiCal(completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event, completion: { (granted, error) in
            if (granted) && (error == nil) {
                if let nameRow: TextRow = self.form.rowBy(tag: "Activity Name"), let nameValue = nameRow.value {
                    let descriptiowRow: TextAreaRow = self.form.rowBy(tag: "Description")!
                    let timezone = TimeZone.current
                    let seconds = -TimeInterval(timezone.secondsFromGMT(for: Date()))
                    
                    let event = EKEvent(eventStore: eventStore)
                    event.title = nameValue
                    event.startDate = self.startDateTime?.addingTimeInterval(seconds)
                    event.endDate = self.endDateTime?.addingTimeInterval(seconds)
                    if let description = descriptiowRow.value {
                        event.notes = description
                    }
                    if self.locationName != "locationName" {
                        event.location = self.locationName
                    }
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    do {
                        try eventStore.save(event, span: .thisEvent)
                    } catch let e as NSError {
                        completion?(false, e)
                        return
                    }
                    completion?(true, nil)
                    guard let currentUserID = Auth.auth().currentUser?.uid else { return }
                    let userReference = Database.database().reference().child("user-activities").child(currentUserID).child(self.activityID).child(messageMetaDataFirebaseFolder)
                    let values:[String : Any] = ["calendarExport": true]
                    userReference.updateChildValues(values)
                }
            } else {
                completion?(false, error as NSError?)
            }
        })
    }
    
    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        guard activity.reminder! != "None" else {
            center.removePendingNotificationRequests(withIdentifiers: ["\(activityID)_Reminder"])
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(String(describing: activity.name!)) Reminder"
        content.sound = UNNotificationSound.default
        var formattedDate: (String, String) = ("", "")
        if let startDate = startDateTime, let endDate = endDateTime, let allDay = activity.allDay {
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay)
            content.subtitle = formattedDate.0
        }
        let reminder = EventAlert(rawValue: activity.reminder!)
        var reminderDate = startDateTime!.addingTimeInterval(reminder!.timeInterval)
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
        reminderDate = reminderDate.addingTimeInterval(-seconds)
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                    repeats: false)
        let identifier = "\(activityID)_Reminder"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)
            }
        })
    }
    
    @objc fileprivate func openPhotos() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = PhotosViewController(collectionViewLayout: UICollectionViewFlowLayout())
        destination.delegate = self
        destination.activityID = activityID
        if let imageURLs = activity.activityPhotos {
            destination.imageURLs = imageURLs
        }

        self.navigationController?.pushViewController(destination, animated: true)
//        let navigationViewController = UINavigationController(rootViewController: destination)
//        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
//        let navigationViewController = UINavigationController(rootViewController: destination)
//        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    //update so existing invitees are shown as selected
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        
        destination.ownerID = self.activity.admin
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty{
            destination.priorSelectedUsers = selectedFalconUsers
        }
        
        destination.delegate = self
        
        if self.selectedFalconUsers.count > 0 {
            let dispatchGroup = DispatchGroup()
            for user in self.selectedFalconUsers {
                dispatchGroup.enter()
                guard let currentUserID = Auth.auth().currentUser?.uid, let userID = user.id else {
                    dispatchGroup.leave()
                    continue
                }
                
                if userID == activity.admin {
                    if userID != currentUserID {
                        self.userInvitationStatus[userID] = .accepted
                    }
                    
                    dispatchGroup.leave()
                    continue
                }
                
                InvitationsFetcher.activityInvitation(forUser: userID, activityID: self.activity.activityID!) { (invitation) in
                    if let invitation = invitation {
                        self.userInvitationStatus[userID] = invitation.status
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                destination.userInvitationStatus = self.userInvitationStatus
                InvitationsFetcher.getAcceptedParticipant(forActivity: self.activity, allParticipants: self.selectedFalconUsers) { acceptedParticipant in
                    self.acceptedParticipant = acceptedParticipant
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            }
        } else {
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    @objc fileprivate func openSchedule() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        showActivityIndicator()
        if scheduleList.indices.contains(scheduleIndex) {
            let dispatchGroup = DispatchGroup()
            let scheduleItem = scheduleList[scheduleIndex]
            if let recipeString = scheduleItem.recipeID, let recipeID = Int(recipeString) {
                dispatchGroup.enter()
                Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                    let detailedRecipe = search
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = MealDetailViewController()
                        destination.activity = scheduleItem
                        destination.recipe = detailedRecipe
                        destination.detailedRecipe = detailedRecipe
                        destination.users = self.acceptedParticipant
                        destination.filteredUsers = self.acceptedParticipant
                        destination.umbrellaActivity = self.activity
                        destination.schedule = true
                        destination.delegate = self
                        self.hideActivityIndicator()
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                }
            } else if let eventID = scheduleItem.eventID {
                dispatchGroup.enter()
                Service.shared.fetchEventsSegment(size: "50", id: eventID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                    if let events = search?.embedded?.events {
                        let event = events[0]
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            let destination = EventDetailViewController()
                            destination.activity = scheduleItem
                            destination.event = event
                            destination.users = self.acceptedParticipant
                            destination.filteredUsers = self.acceptedParticipant
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.hideActivityIndicator()
                            self.navigationController?.pushViewController(destination, animated: true)
                        }
                    }
                }
            } else if let workoutID = scheduleItem.workoutID {
                var reference = Database.database().reference()
                let destination = WorkoutDetailViewController()
                dispatchGroup.enter()
                reference = Database.database().reference().child("workouts").child("workouts")
                reference.child(workoutID).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                        if let workout = try? FirebaseDecoder().decode(Workout.self, from: workoutSnapshotValue) {
                            dispatchGroup.leave()
                            destination.activity = scheduleItem
                            destination.workout = workout
                            destination.intColor = 0
                            destination.users = self.acceptedParticipant
                            destination.filteredUsers = self.acceptedParticipant
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.hideActivityIndicator()
                            self.navigationController?.pushViewController(destination, animated: true)
                        }
                    }
                  })
                { (error) in
                    print(error.localizedDescription)
                }
            } else if let attractionID = scheduleItem.attractionID {
                dispatchGroup.enter()
                Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                    let attraction = search?.embedded?.attractions![0]
                    dispatchGroup.leave()
                    dispatchGroup.notify(queue: .main) {
                        let destination = EventDetailViewController()
                        destination.activity = scheduleItem
                        destination.attraction = attraction
                        destination.users = self.acceptedParticipant
                        destination.filteredUsers = self.acceptedParticipant
                        destination.conversations = self.conversations
                        destination.umbrellaActivity = self.activity
                        destination.schedule = true
                        destination.delegate = self
                        self.hideActivityIndicator()
                        self.navigationController?.pushViewController(destination, animated: true)
                    }
                }
            } else {
                let destination = ScheduleViewController()
                destination.schedule = scheduleItem
                destination.users = acceptedParticipant
                destination.filteredUsers = acceptedParticipant
                destination.startDateTime = startDateTime
                destination.endDateTime = endDateTime
                if let scheduleLocationAddress = scheduleList[scheduleIndex].locationAddress {
                    for (key, _) in scheduleLocationAddress {
                        locationAddress[key] = nil
                    }
                }
                destination.delegate = self
                self.hideActivityIndicator()
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else {
            let destination = ActivityTypeViewController()
            destination.users = acceptedParticipant
            destination.filteredUsers = acceptedParticipant
            destination.umbrellaActivity = activity
            destination.schedule = true
            destination.delegate = self
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)

        }
    }
    
    @objc fileprivate func openPurchases() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = PurchasesViewController()
        destination.users = acceptedParticipant
        destination.filteredUsers = acceptedParticipant
        if purchaseList.indices.contains(purchaseIndex) {
            destination.purchase = purchaseList[purchaseIndex]
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func createNewActivity() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        if sentActivity {
            showActivityIndicator()
            let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: selectedFalconUsers)
            createActivity.createNewActivity()
            hideActivityIndicator()
            self.navigationController?.popViewController(animated: true)
        } else {
            showActivityIndicator()
           let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
           createActivity.createNewActivity()
           hideActivityIndicator()
           if self.conversation == nil {
               self.navigationController?.backToViewController(viewController: ActivityViewController.self)
           } else {
               self.navigationController?.backToViewController(viewController: ChatLogController.self)
           }
        }
        
        
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        // Only append current user when admin/creator of the activity
        if self.activity.admin == currentUserID {
            membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
            membersIDs.append(currentUserID)
        }
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
    func showActivityIndicator() {
        if let navController = self.navigationController {
            self.showSpinner(onView: navController.view)
        } else {
            self.showSpinner(onView: self.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    var activityAvatarURL = String() {
        didSet {
            print("activity avatar \(activityAvatarURL)")
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
            viewRow.cell.view!.showActivityIndicator()
            viewRow.cell.view!.sd_setImage(with: URL(string:activityAvatarURL), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                viewRow.cell.view!.hideActivityIndicator()
            })
        }
    }
    
    @objc func goToExtras() {
       let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Share Activity", style: .default, handler: { (_) in
            print("User click Edit button")
            self.shareActivity()
        }))

        
        if activity.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

            }))
        }
            
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap()
            }))
        }
        
        
           

       alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
           print("User click Dismiss button")
       }))

       self.present(alert, animated: true, completion: {
           print("completion block")
       })
        print("shareButtonTapped")
        
    }
    
    @objc func goToChat() {
        if activity!.conversationID != nil {
            if let convo = conversations.first(where: {$0.chatID == activity!.conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activity = activity
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
    
    @objc func goToMap() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = MapViewController()
        destination.locationAddress = locationAddress
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func shareActivity() {
        
        if let activity = activity, let name = activity.name {
            let imageName = "activityLarge.png"
            if let image = UIImage(named: imageName) {
                
                print("image")
                
                let data = compressImage(image: image)
                let aO = ["activityName": "\(name)",
                            "activityID": activityID,
                            "object": data] as [String: AnyObject]
                let activityObject = ActivityObject(dictionary: aO)
            
                let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)

                alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
                    print("User click Approve button")
                    let destination = ChooseChatTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.activityObject = activityObject
                    destination.users = self.users
                    destination.filteredUsers = self.filteredUsers
                    destination.conversations = self.conversations
                    destination.filteredConversations = self.conversations
                    destination.filteredPinnedConversations = self.conversations
                    self.present(navController, animated: true, completion: nil)
                    
                }))

                alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
                    print("User click Edit button")
                        // Fallback on earlier versions
                    let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
                    guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
                        else { return }
                    let shareContent: [Any] = [shareText, url]
                    let activityController = UIActivityViewController(activityItems: shareContent,
                                                                      applicationActivities: nil)
                    self.present(activityController, animated: true, completion: nil)
                    activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
                    Bool, arrayReturnedItems: [Any]?, error: Error?) in
                        if completed {
                            print("share completed")
                            return
                        } else {
                            print("cancel")
                        }
                        if let shareError = error {
                            print("error while sharing: \(shareError.localizedDescription)")
                        }
                    }
                    
                }))
                

                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
                    print("User click Dismiss button")
                }))

                self.present(alert, animated: true, completion: {
                    print("completion block")
                })
                print("shareButtonTapped")
            }
        

        }
        
    }
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child("user-activities").child(currentUserID).child(activityID).child(messageMetaDataFirebaseFolder).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
    
    func incrementBadgeForReciever(activityID: String?, participantsIDs: [String]) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let activityID = activityID else { return }
        for participantID in participantsIDs where participantID != currentUserID {
            runActivityBadgeUpdate(firstChild: participantID, secondChild: activityID)
            runUserBadgeUpdate(firstChild: participantID)
        }
    }

    func runActivityBadgeUpdate(firstChild: String, secondChild: String) {
        var ref = Database.database().reference().child("user-activities").child(firstChild).child(secondChild)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard snapshot.hasChild(messageMetaDataFirebaseFolder) else {
                ref = ref.child(messageMetaDataFirebaseFolder)
                ref.updateChildValues(["badge": 1])
                return
            }
            ref = ref.child(messageMetaDataFirebaseFolder).child("badge")
            ref.runTransactionBlock({ (mutableData) -> TransactionResult in
                var value = mutableData.value as? Int
                if value == nil { value = 0 }
                mutableData.value = value! + 1
                return TransactionResult.success(withValue: mutableData)
            })
        })
    }
}

extension CreateActivityViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}


extension CreateActivityViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = true
        if textView.textColor == FalconPalette.defaultBlue {
            textView.text = nil
            textView.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
        if textView.text.isEmpty {
            textView.text = "Description"
            textView.textColor = FalconPalette.defaultBlue
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
    }
    
}

extension CreateActivityViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        if let locationRow: ButtonRow = form.rowBy(tag: "Location") {
            self.locationAddress[self.locationName] = nil
            if self.activity.locationAddress != nil {
                self.activity.locationAddress![self.locationName] = nil
            }
            for (key, value) in locationAddress {
                var newKey = String()
                switch key {
                case let oldKey where key.contains("/"):
                    newKey = oldKey.replacingOccurrences(of: "/", with: "")
                case let oldKey where key.contains("."):
                    newKey = oldKey.replacingOccurrences(of: ".", with: "")
                case let oldKey where key.contains("#"):
                    newKey = oldKey.replacingOccurrences(of: "#", with: "")
                case let oldKey where key.contains("$"):
                    newKey = oldKey.replacingOccurrences(of: "$", with: "")
                case let oldKey where key.contains("["):
                    newKey = oldKey.replacingOccurrences(of: "[", with: "")
                    if newKey.contains("]") {
                        newKey = newKey.replacingOccurrences(of: "]", with: "")
                    }
                case let oldKey where key.contains("]"):
                    newKey = oldKey.replacingOccurrences(of: "]", with: "")
                default:
                    newKey = key
                }
                self.locationName = newKey
                self.activity.locationName = newKey
                self.locationAddress[newKey] = value
                if activity.locationAddress == nil {
                    self.activity.locationAddress = self.locationAddress
                } else {
                    self.activity.locationAddress![newKey] = value
                }
            }
            locationRow.title = locationName
            locationRow.updateCell()
        }
    }
}

extension CreateActivityViewController: UpdateScheduleDelegate {
    func updateSchedule(schedule: Activity) {
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            let scheduleRow = mvs.allRows[scheduleIndex]
            if let _ = schedule.name {
                scheduleRow.baseValue = schedule
                scheduleRow.updateCell()
                scheduleRow.reload()
                if scheduleList.indices.contains(scheduleIndex) {
                    scheduleList[scheduleIndex] = schedule
                } else {
                    scheduleList.append(schedule)
                }
                sortSchedule()
                if let localAddress = schedule.locationAddress {
                    for (key, value) in localAddress {
                        locationAddress[key] = value
                    }
                }
                setupRightBarButton(with: "Update")
                updateLists(type: "schedule")
            }
            else {
                mvs.remove(at: scheduleIndex)
            }
        }
    }
}

extension CreateActivityViewController: UpdatePurchasesDelegate {
    func updatePurchases(purchase: Purchase) {
        if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
            let purchaseRow = mvs.allRows[purchaseIndex]
            if purchase.name != "Purchase Name" {
                purchaseRow.baseValue = purchase
                purchaseRow.updateCell()
                if purchaseList.indices.contains(purchaseIndex) {
                    purchaseList[purchaseIndex] = purchase
                } else {
                    purchaseList.append(purchase)
                }
                updateLists(type: "purchases")
            }
            else {
                mvs.remove(at: purchaseIndex)
            }
            purchaseBreakdown()
            updateDecimalRow()
        }
    }
}

extension CreateActivityViewController: UpdateActivityPhotosDelegate {
    func updateActivityPhotos(activityPhotos: [String]) {
        activity.activityPhotos = activityPhotos
        if let photosRow: ButtonRow = form.rowBy(tag: "Photos") {
            if self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty {
                photosRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                photosRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        }
    }
}

extension CreateActivityViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?) {
        if let conversation = conversations.first(where: {$0.chatID == chatID}) {
            if conversation.activities != nil {
                   var activities = conversation.activities!
                   activities.append(activityID!)
                   let updatedActivities = ["activities": activities as AnyObject]
                   Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
               } else {
                   let updatedActivities = ["activities": [activityID!] as AnyObject]
                   Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
               }
           }
        let updatedConversationID = ["conversationID": chatID as AnyObject]
        Database.database().reference().child("activities").child(activityID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
        activity.conversationID = chatID
    }
}

extension CreateActivityViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        chatLogController?.activityID = activityID
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        if #available(iOS 11.0, *) {
        } else {
            self.chatLogController?.startCollectionViewAtBottom()
        }
        
        navigationController?.pushViewController(destination, animated: true)
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}

public extension Form {
    func valuesForFirebase(includeHidden: Bool = false) -> [String: Any?] {
        let rows = includeHidden ? self.allRows : self.rows
        return rows.filter({ $0.tag != nil })
            .reduce([:], { (dictionary, row) -> [String: Any?] in
                var dictionary = dictionary
                dictionary[row.tag!] = row.firebaseValue
                return dictionary
            })
    }
}

public extension Dictionary {
    func valuesForEureka(forForm form: Form) -> [String: Any?] {
        return self.reduce([:], { (dictionary, tuple) -> [String: Any?] in
            var dictionary = dictionary
            let row = form.rowBy(tag: tuple.key as! String)
            if row is SwitchRow || row is CheckRow {
                let typedValue = tuple.value as! Int
                dictionary[tuple.key as! String] = (typedValue == 1) ? true : false
            } else if row is DateRow || row is TimeRow || row is DateTimeRow {
                let typedValue = tuple.value as! TimeInterval
                dictionary[tuple.key as! String] = Date(timeIntervalSince1970: typedValue)
            } else {
                dictionary[tuple.key as! String] = tuple.value
            }
            return dictionary
        })
    }
}

private extension BaseRow {
    var firebaseValue: Any? {
        get {
            if self is SwitchRow || self is CheckRow {
                return (self.baseValue as! Bool) ? true : false
            } else if self is DateRow || self is TimeRow || self is DateTimeRow || self is DateTimeInlineRow {
                return NSNumber(value: Int((self.baseValue as! Date).timeIntervalSince1970))
            }
            else {
                if self.baseValue == nil {
                    return "nothing"
                } else {
                    return self.baseValue
                }
            }
        }
    }
}
