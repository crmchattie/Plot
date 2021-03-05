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
    var purchaseUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    var conversations = [Conversation]()
    var activities = [Activity]()
    var conversation: Conversation!
    let avatarOpener = AvatarOpener()
    var locationName : String = "locationName"
    var locationAddress = [String : [Double]]()
    var scheduleList = [Activity]()
    var purchaseList = [Transaction]()
    var purchaseDict = [User: Double]()
    var listList = [ListContainer]()
    var scheduleIndex: Int = 0
    var purchaseIndex: Int = 0
    var listIndex: Int = 0
    var grocerylistIndex: Int = -1
    var startDateTime: Date?
    var endDateTime: Date?
    var userNames : [String] = []
    var userNamesString: String = ""
    var thumbnailImage: String = ""
    var segmentRowValue: String = "Schedule"
    var activityID = String()
    let dispatchGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    // Participants with accepted invites
    var acceptedParticipant: [User] = []
    var weather: [DailyWeatherElement]!
    
    fileprivate var reminderDate: Date?
    
    var active = false
    var sentActivity = false
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
            title = "Event"
            active = true
            if activity.activityID != nil {
                activityID = activity.activityID!
            }
            if let localName = activity.locationName, localName != "locationName", let localAddress = activity.locationAddress {
                locationName = localName
                locationAddress = localAddress
                self.weatherRow()
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
            setupLists()
            setupRightBarButton(with: "Update")
            resetBadgeForSelf()
        } else {
            title = "New Event"
            if let currentUserID = Auth.auth().currentUser?.uid {
                //create new activityID for auto updating items (schedule, purchases, checklist)
                activityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(dictionary: ["activityID": activityID as AnyObject])
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
        
        purchaseUsers = self.acceptedParticipant
        
        if let currentUserID = Auth.auth().currentUser?.uid, self.activity.admin == currentUserID {
            let participantReference = Database.database().reference().child("users").child(currentUserID)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    self.purchaseUsers.append(user)
                    for user in self.purchaseUsers {
                        self.purchaseDict[user] = 0.00
                    }
                }
            })
        } else {
            for user in self.purchaseUsers {
                self.purchaseDict[user] = 0.00
            }
        }
        
        if let showExtras = activity.showExtras {
            if !showExtras, let segmentRow : SegmentedRow<String> = self.form.rowBy(tag: "sections") {
                self.segmentRowValue = segmentRow.value!
                segmentRow.value = "Hidden"
            } else if let segmentRow : SegmentedRow<String> = self.form.rowBy(tag: "sections") {
                segmentRow.value = self.segmentRowValue
            }
        }
    }
    
    fileprivate func setupMainView() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
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
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.leftBarButtonItem = cancelBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(createNewActivity))
            if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            } else {
                navigationItem.rightBarButtonItem = plusBarButton
            }
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
//            <<< ViewRow<UIImageView>("Activity Image")
//                .cellSetup { (cell, row) in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//
//                    //  Make the image view occupy the entire row:
//                    cell.viewRightMargin = 0.0
//                    cell.viewLeftMargin = 0.0
//                    cell.viewTopMargin = 0.0
//                    cell.viewBottomMargin = 0.0
//                    
//                    cell.height = { return CGFloat(44) }
//                    
//                    row.title = "Cover Photo"
//                    cell.titleLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    
////                    //  Construct the view for the cell
//                    cell.view = UIImageView()
//                    cell.view!.contentMode = .scaleAspectFill //.scaleAspectFit
//                    cell.view!.clipsToBounds = true
//                    cell.contentView.addSubview(cell.view!)
//                    
//                    if self.active && self.activity.activityOriginalPhotoURL != "" && self.activity.activityOriginalPhotoURL != nil {
//                        cell.height = { return CGFloat(300) }
//                        row.title = nil
//                        cell.view!.sd_setImage(with: URL(string:self.activity.activityOriginalPhotoURL!), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
//                        })
//                        self.activityAvatarURL = self.activity.activityOriginalPhotoURL!
//                        self.thumbnailImage = self.activity.activityThumbnailPhotoURL!
//
//                    } else {
//                        self.activityAvatarURL = ""
//                    }
//                }.onCellSelection { ViewCell, ViewRow in
//                    self.openActivityPicture()
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//            }
            
            <<< TextRow("Event Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< TextRow("Type") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityType != "nothing" && self.activity.activityType != nil {
                    $0.value = self.activity.activityType!
                }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange() { [unowned self] row in
                    self.activity.activityType = row.value
                }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityDescription != "nothing" && self.activity.activityDescription != nil {
                    $0.value = self.activity.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                }).onChange() { [unowned self] row in
                    self.activity.activityDescription = row.value
                }
            
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                if self.active && self.activity.category != nil {
                    row.title = self.activity.category?.capitalized
                } else {
                    row.title = "Uncategorized"
                }
            }.onCellSelection({ _, row in
                self.openCategory(value: row.title ?? "Category")
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
            <<< ButtonRow("Media") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                }.onCellSelection({ _,_ in
                    self.openMedia()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.accessoryType = .disclosureIndicator
                    cell.textLabel?.textAlignment = .left
                    if (self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty) && (self.activity.activityFiles == nil || self.activity.activityFiles!.isEmpty) {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
            
            <<< ButtonRow("Location") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Participants" {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
            
            <<< SwitchRow("All-day") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if self.active {
                    $0.value = self.activity.allDay
                } else {
                    $0.value = false
                    self.activity.allDay = false
                }
                }.onChange { [weak self] row in
                    self!.activity.allDay = row.value
                    
                    let startDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    let endDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    
                    if row.value ?? false {
                        startDate.dateFormatter?.timeStyle = .none
                        endDate.dateFormatter?.timeStyle = .none
                    }
                    else {
                        startDate.dateFormatter?.timeStyle = .short
                        endDate.dateFormatter?.timeStyle = .short
                    }
                    startDate.updateCell()
                    endDate.updateCell()
                    startDate.inlineRow?.updateCell()
                    endDate.inlineRow?.updateCell()
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            
            //add Soon option to replace time; will require update to end time as well
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: activity.startTimeZone ?? "UTC")
                    $0.value = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
                    if self.activity.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    $0.dateFormatter?.timeZone = .current
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.activity.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.startDateTime = $0.value
                }.onChange { [weak self] row in
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
                    self!.weatherRow()
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate { (cell, row) in
                        row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                        if #available(iOS 13.4, *) {
                            cell.datePicker.preferredDatePickerStyle = .wheels
                        }
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
                        }
                        if let startTimeZone = self?.activity.startTimeZone {
                            cell.datePicker.timeZone = TimeZone(identifier: startTimeZone)
                        } else if self!.active {
                            cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        } else {
                            cell.datePicker.timeZone = .current
                        }
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    if let timeZoneRow: LabelRow = self?.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = false
                        timeZoneRow.evaluateHidden()
                    }
                }.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            <<< LabelRow("startTimeZone") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = "Time Zone"
                row.hidden = true
                if active {
                    row.value = activity.startTimeZone ?? "UTC"
                } else {
                    row.value = TimeZone.current.identifier
                    activity.startTimeZone = TimeZone.current.identifier
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "startTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            <<< DateTimeInlineRow("Ends") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                if self.active {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: activity.endTimeZone ?? "UTC")
                    $0.value = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
                    if self.activity.allDay == true {
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.timeStyle = .short
                    }
                    $0.updateCell()
                } else {
                    $0.dateFormatter?.timeZone = .current
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.activity.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                }
                self.endDateTime = $0.value
                }.onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        startRow.value = Date(timeInterval: 0, since: row.value!)
                        startRow.updateCell()
                    }
                    self!.activity.endDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
                    self!.endDateTime = row.value
                    self!.weatherRow()
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
                inlineRow.cellUpdate { (cell, row) in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                    if let endTimeZone = self?.activity.endTimeZone {
                        cell.datePicker.timeZone = TimeZone(identifier: endTimeZone)
                    } else if self!.active {
                        cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    } else {
                        cell.datePicker.timeZone = .current
                    }
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                    let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                    if allRow.value ?? false {
                        cell.datePicker.datePickerMode = .date
                    }
                    else {
                        cell.datePicker.datePickerMode = .dateAndTime
                    }
                }
                cell.detailTextLabel?.textColor = cell.tintColor
                if let timeZoneRow: LabelRow = self?.form.rowBy(tag: "endTimeZone") {
                    timeZoneRow.hidden = false
                    timeZoneRow.evaluateHidden()
                }
                }.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone") {
                        timeZoneRow.hidden = true
                        timeZoneRow.evaluateHidden()
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    
                }
            
            <<< LabelRow("endTimeZone") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = "Time Zone"
                row.hidden = true
                if active {
                    row.value = activity.endTimeZone ?? "UTC"
                } else {
                    row.value = TimeZone.current.identifier
                    activity.endTimeZone = TimeZone.current.identifier
                }
                }.onCellSelection({ _,_ in
                    self.openTimeZoneFinder(startOrEndTimeZone: "endTimeZone")
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }
            
            <<< AlertRow<EventAlert>("Reminder") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.notes != "nothing" && self.activity.notes != nil {
                    $0.value = self.activity.notes
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                }).onChange() { [unowned self] row in
                    self.activity.notes = row.value
                }
        
        <<< SwitchRow("showExtras") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = "Show Extras"
                if let showExtras = activity.showExtras {
                    row.value = showExtras
                } else {
                    row.value = true
                    self.activity.showExtras = true
                }
            }.onChange { [weak self] row in
                self!.activity.showExtras = row.value
                if !row.value!, let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
                    self!.segmentRowValue = segmentRow.value!
                    segmentRow.value = "Hidden"
                } else if let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
                    segmentRow.value = self!.segmentRowValue
                }
                guard let currentUserID = Auth.auth().currentUser?.uid else { return }
                let userReference = Database.database().reference().child("user-activities").child(currentUserID).child(self!.activityID).child(messageMetaDataFirebaseFolder)
                let values:[String : Any] = ["showExtras": row.value ?? false]
                userReference.updateChildValues(values)
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
            
        <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.hidden = "$showExtras == false"
                if #available(iOS 13.0, *) {
                    $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                } else {
                    // Fallback on earlier versions
                }
                $0.options = ["Schedule", "Lists", "Transactions"]
                $0.value = "Schedule"
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }

        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Schedule",
                               footer: "Add an activity to the schedule") {
                                $0.tag = "schedulefields"
                                $0.hidden = "!$sections == 'Schedule'"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add Activity"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            cell.height = { 60 }
                                        }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.scheduleIndex = index
                                    self.openSchedule()
                                    return LabelRow("label"){ row in
                                        
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
                                    }, at: mvs.count - 1)
                                    
                                }

    form +++
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                           header: "Checklists",
                           footer: "Add a checklist") {
                            $0.tag = "listsfields"
                            $0.hidden = "$sections != 'Lists'"
                            $0.addButtonProvider = { section in
                                return ButtonRow(){
                                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                    $0.title = "Add Checklist"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                    }
                            }
                            $0.multivaluedRowToInsertAt = { index in
                                self.listIndex = index
                                self.openList()
                                return ButtonRow() { row in
                                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                row.title = "List"
                                }.onCellSelection({ _,_ in
                                    self.listIndex = index
                                    self.openList()
                                }).cellUpdate { cell, row in
                                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                    cell.textLabel?.textAlignment = .left
                                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                }
                            }
                            
    }

        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Transactions",
                               footer: "Add a transaction") {
                                $0.tag = "purchasefields"
                                $0.hidden = "$sections != 'Transactions'"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add Transaction"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                                    }
                                    
                                }
            }

//                                form +++
//                                    Section(header: "Balances",
//                                            footer: "Positive Balance = Owe; Negative Balance = Owed") {
//                                                $0.tag = "Balances"
//                                                $0.hidden = "$sections != 'Transactions'"
//                                }
    }
    
    func decimalRowFunc() {
        var mvs = form.sectionBy(tag: "Balances")
        for user in purchaseUsers {
            if let userName = user.name, let _ : DecimalRow = form.rowBy(tag: "\(userName)") {
                continue
            } else {
                purchaseDict[user] = 0.00
                if let mvsValue = mvs {
                    mvs?.insert(DecimalRow(user.name) {
                        $0.hidden = "$sections != 'Transactions'"
                        $0.tag = user.name
                        $0.useFormatterDuringInput = true
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor

                    }, at: mvsValue.count)
                }
            }
        }
        for (key, _) in purchaseDict {
            if !purchaseUsers.contains(key) {
                let sectionMVS : SegmentedRow<String> = form.rowBy(tag: "sections")!
                sectionMVS.value = "Transactions"
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
        for user in purchaseUsers {
            purchaseDict[user] = 0.00
        }
        for purchase in purchaseList {
            if let purchaser = purchase.admin {
                var costPerPerson: Double = 0.00
                if let purchaseRowCount = purchase.splitNumber {
                    costPerPerson = purchase.amount / Double(purchaseRowCount)
                } else if let participants = purchase.participantsIDs {
                    costPerPerson = purchase.amount / Double(participants.count)
                }
                // minus cost from purchaser's balance
                if let user = purchaseUsers.first(where: {$0.id == purchaser}) {
                    var value = purchaseDict[user] ?? 0.00
                    value -= costPerPerson
                    purchaseDict[user] = value
                }
                // add cost to non-purchasers balance
                if let participants = purchase.participantsIDs {
                    for ID in participants {
                        if let user = purchaseUsers.first(where: {$0.id == ID}), !purchaser.contains(ID) {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                // add cost to non-purchasers balance based on custom input
                } else {
                    for user in purchaseUsers {
                        if let ID = user.id, ID != purchaser {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                }
            }
        }
        updateDecimalRow()
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
        guard indexPath.row == 5, let latitude = locationAddress[locationName]?[0], let longitude = locationAddress[locationName]?[1] else {
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
                    if let recipeID = self!.scheduleList[rowNumber].recipeID {
                        self!.lookupRecipe(recipeID: Int(recipeID)!, add: false)
                    }
                    self!.scheduleList.remove(at: rowNumber)
                    self!.sortSchedule()
                    self!.updateLists(type: "schedule")
                }
            } else if rowType is PurchaseRow {
                if self!.purchaseList.indices.contains(self!.purchaseIndex) {
                    self!.purchaseList.remove(at: rowNumber)
//                    self!.purchaseBreakdown()
                }
                self!.updateLists(type: "purchases")
            } else if rowType is ButtonRow {
                if self!.listList.indices.contains(self!.listIndex) {
                    self!.listList.remove(at: rowNumber)
                }
                if rowNumber == self!.grocerylistIndex {
                    self!.grocerylistIndex = -1
                }
                self!.updateLists(type: "lists")
            }
        }
    }
    
    fileprivate func setupLists() {
        if activity.checklistIDs != nil {
            for checklistID in activity.checklistIDs! {
                dispatchGroup.enter()
                let checklistDataReference = Database.database().reference().child(checklistsEntity).child(checklistID)
                checklistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let checklistSnapshotValue = snapshot.value {
                        if let checklist = try? FirebaseDecoder().decode(Checklist.self, from: checklistSnapshotValue) {
                            var list = ListContainer()
                            list.checklist = checklist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.grocerylistID != nil {
            dispatchGroup.enter()
            let grocerylistDataReference = Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!)
            grocerylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), let grocerylistSnapshotValue = snapshot.value {
                    if let grocerylist = try? FirebaseDecoder().decode(Grocerylist.self, from: grocerylistSnapshotValue) {
                        var list = ListContainer()
                        list.grocerylist = grocerylist
                        self.listList.append(list)
                        self.grocerylistIndex = self.listList.count - 1
                    }
                }
                self.dispatchGroup.leave()
            })
        }
        if activity.packinglistIDs != nil {
            for packinglistID in activity.packinglistIDs! {
                dispatchGroup.enter()
                let packinglistDataReference = Database.database().reference().child(packinglistsEntity).child(packinglistID)
                packinglistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let packinglistSnapshotValue = snapshot.value {
                        if let packinglist = try? FirebaseDecoder().decode(Packinglist.self, from: packinglistSnapshotValue) {
                            var list = ListContainer()
                            list.packinglist = packinglist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.activitylistIDs != nil {
            for activitylistID in activity.activitylistIDs! {
                dispatchGroup.enter()
                let activitylistDataReference = Database.database().reference().child(activitylistsEntity).child(activitylistID)
                activitylistDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let activitylistSnapshotValue = snapshot.value {
                        if let activitylist = try? FirebaseDecoder().decode(Activitylist.self, from: activitylistSnapshotValue) {
                            var list = ListContainer()
                            list.activitylist = activitylist
                            self.listList.append(list)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        if activity.transactionIDs != nil {
            for transactionID in activity.transactionIDs! {
                dispatchGroup.enter()
                let dataReference = Database.database().reference().child(financialTransactionsEntity).child(transactionID)
                dataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), let snapshotValue = snapshot.value {
                        if let transaction = try? FirebaseDecoder().decode(Transaction.self, from: snapshotValue) {
                            self.purchaseList.append(transaction)
                        }
                    }
                    self.dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.listRow()
//            self.decimalRowFunc()
//            self.purchaseBreakdown()
        }
    }
    
    fileprivate func listRow() {
        for list in listList {
            if let groceryList = list.grocerylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = groceryList.name
                    self.grocerylistIndex = mvs.count - 1
                    print("grocerylistIndex \(self.grocerylistIndex)")
                    }.onCellSelection({ cell, row in
                        self.listIndex = row.indexPath!.row
                        print("listIndex \(self.listIndex)")
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
            } else if let checklist = list.checklist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = checklist.name
                    }.onCellSelection({ cell, row in
                        self.listIndex = row.indexPath!.row
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
            } else if let activitylist = list.activitylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = activitylist.name
                    }.onCellSelection({ cell, row in
                        self.listIndex = row.indexPath!.row
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
            } else if let packinglist = list.packinglist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = packinglist.name
                    }.onCellSelection({ cell, row in
                        self.listIndex = row.indexPath!.row
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                    }, at: mvs.count - 1)
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
            }, at: mvs.count - 1)
            
        }
    }
    
    fileprivate func weatherRow() {
        if let localName = activity.locationName, localName != "locationName", Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval) > Date(), Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval) < Date().addingTimeInterval(1296000) {
            var startDate = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
            var endDate = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
            if startDate < Date() {
                startDate = Date().addingTimeInterval(3600)
            }
            if endDate > Date().addingTimeInterval(1209600) {
                endDate = Date().addingTimeInterval(1209600)
            }
            let startDateString = startDate.toString(dateFormat: "YYYY-MM-dd") + "T24:00:00Z"
            let endDateString = endDate.toString(dateFormat: "YYYY-MM-dd") + "T00:00:00Z"
            if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let localAddress = activity.locationAddress, let latitude = localAddress[locationName]?[0], let longitude = localAddress[locationName]?[1] {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                Service.shared.fetchWeatherDaily(startDateTime: startDateString, endDateTime: endDateString, lat: latitude, long: longitude, unit: "us") { (search, err) in
                    if let weather = search {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            weatherRow.value = weather
                            weatherRow.updateCell()
                            weatherRow.cell.collectionView.reloadData()
                            self.weather = weather
                        }
                    } else if let index = weatherRow.indexPath?.item {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            let section = self.form.allSections[0]
                            section.remove(at: index)
                        }
                    }
                }
            } else if let localAddress = activity.locationAddress, let latitude = localAddress[locationName]?[0], let longitude = localAddress[locationName]?[1] {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                Service.shared.fetchWeatherDaily(startDateTime: startDateString, endDateTime: endDateString, lat: latitude, long: longitude, unit: "us") { (search, err) in
                    if let weather = search {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                        var section = self.form.allSections[0]
                        if let locationRow: ButtonRow = self.form.rowBy(tag: "Location"), let index = locationRow.indexPath?.item {
                            section.insert(WeatherRow("Weather") { row in
                                    row.value = weather
                                    row.updateCell()
                                    row.cell.collectionView.reloadData()
                                    self.weather = weather
                                }, at: index+1)
                            }
                        }
                    }
                }
            }
        } else if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let index = weatherRow.indexPath?.item {
            let section = self.form.allSections[0]
            section.remove(at: index)
            self.weather = [DailyWeatherElement]()
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
                scheduleRow.reload()
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
            var transactionIDs = [String]()
            for transaction in purchaseList {
                transactionIDs.append(transaction.guid)
            }
            if !transactionIDs.isEmpty {
                activity.transactionIDs = transactionIDs
                groupActivityReference.updateChildValues(["transactionIDs": transactionIDs as AnyObject])
            } else {
                activity.transactionIDs = nil
                groupActivityReference.child("transactionIDs").removeValue()
            }
        } else {
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            if listList.isEmpty {
                activity.checklistIDs = nil
                groupActivityReference.child("checklistIDs").removeValue()
                activity.grocerylistID = nil
                groupActivityReference.child("grocerylistID").removeValue()
                activity.packinglistIDs = nil
                groupActivityReference.child("packinglistIDs").removeValue()
                activity.activitylistIDs = nil
                groupActivityReference.child("activitylistIDs").removeValue()
            } else {
                var checklistIDs = [String]()
                var packinglistIDs = [String]()
                var activitylistIDs = [String]()
                var grocerylistID = "nothing"
                for list in listList {
                    if let checklist = list.checklist {
                        checklistIDs.append(checklist.ID!)
                    } else if let packinglist = list.packinglist {
                        packinglistIDs.append(packinglist.ID!)
                    } else if let grocerylist = list.grocerylist {
                        grocerylistID = grocerylist.ID!
                    } else if let activitylist = list.activitylist {
                        activitylistIDs.append(activitylist.ID!)
                    }
                }
                if !checklistIDs.isEmpty {
                    activity.checklistIDs = checklistIDs
                    groupActivityReference.updateChildValues(["checklistIDs": checklistIDs as AnyObject])
                } else {
                    activity.checklistIDs = nil
                    groupActivityReference.child("checklistIDs").removeValue()
                }
                if !activitylistIDs.isEmpty {
                    activity.activitylistIDs = activitylistIDs
                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    activity.activitylistIDs = nil
                    groupActivityReference.child("activitylistIDs").removeValue()
                }
                if grocerylistID != "nothing" {
                    activity.grocerylistID = grocerylistID
                    groupActivityReference.updateChildValues(["grocerylistID": grocerylistID as AnyObject])
                } else {
                    activity.grocerylistID = nil
                    groupActivityReference.child("grocerylistID").removeValue()
                }
                if !packinglistIDs.isEmpty {
                    activity.packinglistIDs = packinglistIDs
                    groupActivityReference.updateChildValues(["packinglistIDs": packinglistIDs as AnyObject])
                } else {
                    activity.packinglistIDs = nil
                    groupActivityReference.child("packinglistIDs").removeValue()
                }
            }
        }
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
        if let startDate = startDateTime, let endDate = endDateTime, let allDay = activity.allDay, let startTimeZone = activity.startTimeZone, let endTimeZone = activity.endTimeZone {
            formattedDate = timestampOfActivity(startDate: startDate, endDate: endDate, allDay: allDay, startTimeZone: startTimeZone, endTimeZone: endTimeZone)
            content.subtitle = formattedDate.0
        }
        let reminder = EventAlert(rawValue: activity.reminder!)
        let reminderDate = startDateTime!.addingTimeInterval(reminder!.timeInterval)
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
    
    fileprivate func openCategory(value: String) {
        let destination = ActivityCategoryViewController()
        destination.delegate = self
        if value != "Category" {
            destination.value = value
        }
        self.navigationController?.pushViewController(destination, animated: true)

        
    }
    
    fileprivate func openMedia() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = MediaViewController()
        destination.delegate = self
        destination.activityID = activityID
        if let imageURLs = activity.activityPhotos {
            destination.imageURLs = imageURLs
        }
        if let fileURLs = activity.activityFiles {
            destination.fileURLs = fileURLs
        }

        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    fileprivate func openTimeZoneFinder(startOrEndTimeZone: String) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = TimeZoneViewController()
        destination.delegate = self
        destination.startOrEndTimeZone = startOrEndTimeZone
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    //update so existing invitees are shown as selected
    fileprivate func openParticipantsInviter() {
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
        if !selectedFalconUsers.isEmpty {
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
    
    fileprivate func openSchedule() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if scheduleList.indices.contains(scheduleIndex) {
            showActivityIndicator()
            let dispatchGroup = DispatchGroup()
            let scheduleItem = scheduleList[scheduleIndex]
            if let recipeString = scheduleItem.recipeID, let recipeID = Int(recipeString) {
                dispatchGroup.enter()
                Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
                    if let detailedRecipe = search {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            let destination = RecipeDetailViewController()
                            destination.activity = scheduleItem
                            destination.recipe = detailedRecipe
                            destination.detailedRecipe = detailedRecipe
                            destination.users = self.acceptedParticipant
                            destination.filteredUsers = self.acceptedParticipant
                            destination.conversations = self.conversations
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.getParticipants(forActivity: scheduleItem) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    } else {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            self.hideActivityIndicator()
                            self.activityNotFoundAlert()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
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
                            destination.conversations = self.conversations
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.getParticipants(forActivity: scheduleItem) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    } else {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            self.hideActivityIndicator()
                            self.activityNotFoundAlert()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.dismiss(animated: true, completion: nil)
                            })
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
                        if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                            dispatchGroup.leave()
                            destination.activity = scheduleItem
                            destination.workout = workout
                            destination.intColor = 0
                            destination.users = self.acceptedParticipant
                            destination.filteredUsers = self.acceptedParticipant
                            destination.conversations = self.conversations
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.getParticipants(forActivity: scheduleItem) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    }
                  })
                { (error) in
                    print(error.localizedDescription)
                }
            } else if let attractionID = scheduleItem.attractionID {
                dispatchGroup.enter()
                Service.shared.fetchAttractionsSegment(size: "50", id: attractionID, keyword: "", classificationName: "", classificationId: "") { (search, err) in
                    if let attraction = search?.embedded?.attractions![0] {
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
                            self.getParticipants(forActivity: scheduleItem) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    } else {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            self.hideActivityIndicator()
                            self.activityNotFoundAlert()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
                    }
                }
            } else if let placeID = scheduleItem.placeID {
                dispatchGroup.enter()
                Service.shared.fetchFSDetails(id: placeID) { (search, err) in
                    if let place = search?.response?.venue {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            let destination = PlaceDetailViewController()
                            destination.activity = scheduleItem
                            destination.place = place
                            destination.users = self.acceptedParticipant
                            destination.filteredUsers = self.acceptedParticipant
                            destination.conversations = self.conversations
                            destination.umbrellaActivity = self.activity
                            destination.schedule = true
                            destination.delegate = self
                            self.getParticipants(forActivity: scheduleItem) { (participants) in
                                    destination.selectedFalconUsers = participants
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                            }
                        }
                    } else {
                        dispatchGroup.leave()
                        dispatchGroup.notify(queue: .main) {
                            self.hideActivityIndicator()
                            self.activityNotFoundAlert()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
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
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Activity", style: .default, handler: { (_) in
                if let _: LabelRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ScheduleViewController()
                destination.users = self.acceptedParticipant
                destination.filteredUsers = self.acceptedParticipant
                destination.delegate = self
                destination.startDateTime = self.startDateTime
                destination.endDateTime = self.endDateTime
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Existing Activity", style: .default, handler: { (_) in
                if let _: LabelRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
                let destination = ChooseActivityTableViewController()
                destination.needDelegate = true
                destination.movingBackwards = true
                destination.delegate = self
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                destination.activity = self.activity
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let _: LabelRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                    mvs.remove(at: mvs.count - 2)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    fileprivate func openPurchases() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if purchaseList.indices.contains(purchaseIndex) {
            let destination = FinanceTransactionViewController()
            destination.delegate = self
            destination.movingBackwards = true
            destination.users = purchaseUsers
            destination.filteredUsers = purchaseUsers
            destination.transaction = purchaseList[purchaseIndex]
            self.getParticipants(transaction: purchaseList[purchaseIndex]) { (participants) in
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "New Transaction", style: .default, handler: { (_) in
                let destination = FinanceTransactionViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.users = self.purchaseUsers
                destination.filteredUsers = self.purchaseUsers
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Existing Transaction", style: .default, handler: { (_) in
                let destination = ChooseTransactionTableViewController()
                destination.delegate = self
                destination.movingBackwards = true
                destination.existingTransactions = self.purchaseList
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
                    mvs.remove(at: self.purchaseIndex)
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    fileprivate func openList() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if listIndex == grocerylistIndex, let grocerylist = listList[listIndex].grocerylist {
            let destination = GrocerylistViewController()
            destination.grocerylist = grocerylist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let checklist = listList[listIndex].checklist {
            let destination = ChecklistViewController()
            destination.checklist = checklist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let activitylist = listList[listIndex].activitylist {
            let destination = ActivitylistViewController()
            destination.activitylist = activitylist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let packinglist = listList[listIndex].packinglist {
            let destination = PackinglistViewController()
            destination.packinglist = packinglist
            destination.delegate = self
            if let weather = self.weather {
                destination.weather = weather
            }
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let destination = ChecklistViewController()
            destination.delegate = self
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createNewActivity() {
        if !active || sentActivity {
            self.createActivity()
        } else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "Update Event", style: .default, handler: { (_) in
                print("User click Edit button")
                self.createActivity()
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Event", style: .default, handler: { (_) in
                print("User click Edit button")
                self.duplicateActivity()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            
        }
    }
    
    func createActivity() {
        if sentActivity {
            showActivityIndicator()
            let createActivity = ActivityActions(activity: activity, active: false, selectedFalconUsers: [])
            createActivity.createNewActivity()
            hideActivityIndicator()
            self.navigationController?.popViewController(animated: true)
        } else {
            showActivityIndicator()
            let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
            createActivity.createNewActivity()
            hideActivityIndicator()
            if active {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
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
        
//        if activity.conversationID == nil {
//            alert.addAction(UIAlertAction(title: "Connect Activity to a Chat", style: .default, handler: { (_) in
//                print("User click Approve button")
//                self.goToChat()
//
//            }))
//        } else {
//            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
//                print("User click Approve button")
//                self.goToChat()
//
//
//            }))
//        }
            
        if let localName = activity.locationName, localName != "locationName", let _ = activity.locationAddress {
            alert.addAction(UIAlertAction(title: "Go to Map", style: .default, handler: { (_) in
                print("User click Edit button")
                self.goToMap()
            }))
        }
        
//        alert.addAction(UIAlertAction(title: "Share Event", style: .default, handler: { (_) in
//            print("User click Edit button")
//            self.share()
//        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
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
        destination.sections = [.activity]
        var locations = [activity]
        
        if locationAddress.count > 1 {
            locations.append(contentsOf: scheduleList)
            destination.locations = [.activity: locations]
        } else {
            destination.locations = [.activity: locations]
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func share() {
        if let activity = activity, let name = activity.name {
            let imageName = "activityLarge"
            if let image = UIImage(named: imageName) {                
                let data = compressImage(image: image)
                let aO = ["activityName": "\(name)",
                            "activityID": activityID,
                            "activityImageURL": "\(imageName)",
                            "object": data] as [String: AnyObject]
                let activityObject = ActivityObject(dictionary: aO)
            
                let alert = UIAlertController(title: "Share Event", message: nil, preferredStyle: .actionSheet)

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
                

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    print("User click Dismiss button")
                }))

                self.present(alert, animated: true, completion: {
                    print("completion block")
                })
                print("shareButtonTapped")
            }
        

        }
        
    }
    
    func duplicateActivity() {
        
        if let activity = activity, let currentUserID = Auth.auth().currentUser?.uid {
            var newActivityID: String!
            
            newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
            
            let newActivity = activity.copy() as! Activity
            newActivity.activityID = newActivityID
            newActivity.admin = currentUserID
            newActivity.participantsIDs = nil
            newActivity.activityPhotos = nil
            newActivity.activityFiles = nil
            newActivity.activityOriginalPhotoURL = nil
            newActivity.activityThumbnailPhotoURL = nil
            newActivity.conversationID = nil
            
            if let scheduleList = newActivity.schedule {
                for schedule in scheduleList {
                    schedule.participantsIDs = nil
                }
            }
            
            self.showActivityIndicator()
            let createActivity = ActivityActions(activity: newActivity, active: !self.active, selectedFalconUsers: [])
            createActivity.createNewActivity()
            self.hideActivityIndicator()
            self.navigationController?.popViewController(animated: true)
            
        }
    }
    
    fileprivate func lookupRecipe(recipeID: Int, add: Bool) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Service.shared.fetchRecipesInfo(id: recipeID) { (search, err) in
            dispatchGroup.leave()
            dispatchGroup.notify(queue: .main) {
                if let recipe = search {
                    if add {
                        self.updateGrocerylist(recipe: recipe, add: true)
                    } else {
                        self.updateGrocerylist(recipe: recipe, add: false)
                    }
                }
            }
        }
    }
    
    fileprivate func updateGrocerylist(recipe: Recipe, add: Bool) {
        if self.activity.grocerylistID != nil, let grocerylist = listList[grocerylistIndex].grocerylist, grocerylist.ingredients != nil, let recipeIngredients = recipe.extendedIngredients {
            var glIngredients = grocerylist.ingredients!
            if let grocerylistServings = grocerylist.servings!["\(recipe.id)"], grocerylistServings != recipe.servings {
                grocerylist.servings!["\(recipe.id)"] = recipe.servings
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil && recipeIngredient.amount != nil  {
                                glIngredients[index].amount! +=  recipeIngredient.amount! - recipeIngredient.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                            }
                    }
                }
            } else if grocerylist.recipes!["\(recipe.id)"] != nil && add {
                return
            } else {
                if add {
                    if grocerylist.recipes != nil {
                        grocerylist.recipes!["\(recipe.id)"] = recipe.title
                        grocerylist.servings!["\(recipe.id)"] = recipe.servings
                    } else {
                        grocerylist.recipes = ["\(recipe.id)": recipe.title]
                        grocerylist.servings = ["\(recipe.id)": recipe.servings!]
                    }
                } else {
                    grocerylist.recipes!["\(recipe.id)"] = nil
                    grocerylist.servings!["\(recipe.id)"] = nil
                }
                for recipeIngredient in recipeIngredients {
                    if let index = glIngredients.firstIndex(where: {$0 == recipeIngredient}) {
                        if add {
                            glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! += recipeIngredient.amount ?? 0.0
                            }
                        } else {
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! -= recipeIngredient.amount ?? 0.0
                                if glIngredients[index].amount! == 0 {
                                    glIngredients.remove(at: index)
                                    continue
                                } else {
                                    glIngredients[index].recipe![recipe.title] = nil
                                }
                            }
                        }
                    } else {
                        if add {
                            var recIngredient = recipeIngredient
                            recIngredient.recipe = [recipe.title: recIngredient.amount ?? 0.0]
                            glIngredients.append(recIngredient)
                        }
                    }
                }
            }
            if glIngredients.isEmpty {
                let mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.remove(at: grocerylistIndex)
                listList.remove(at: grocerylistIndex)
                grocerylistIndex = -1
                self.activity.grocerylistID = nil
                
                let deleteGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: true, selectedFalconUsers: self.selectedFalconUsers)
                deleteGrocerylist.deleteGrocerylist()
                
            } else {
                grocerylist.ingredients = glIngredients
                let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: true, selectedFalconUsers: self.selectedFalconUsers)
                createGrocerylist.createNewGrocerylist()
                if listList.indices.contains(grocerylistIndex) {
                    listList[grocerylistIndex].grocerylist = grocerylist
                }
            }
        } else if let recipeIngredients = recipe.extendedIngredients, add, let currentUserID = Auth.auth().currentUser?.uid {
            let ID = Database.database().reference().child(userGrocerylistsEntity).child(currentUserID).childByAutoId().key ?? ""
            let grocerylist = Grocerylist(dictionary: ["name" : "\(activity.name ?? "") Grocery List"] as [String: AnyObject])
            
            var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
            mvs.insert(ButtonRow() { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = grocerylist.name
                self.grocerylistIndex = mvs.count - 1
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            
            grocerylist.ID = ID
            grocerylist.activityID = activityID
            
            grocerylist.ingredients = recipeIngredients
            for index in 0...grocerylist.ingredients!.count - 1 {
                grocerylist.ingredients![index].recipe = [recipe.title: grocerylist.ingredients![index].amount ?? 0.0]
            }
            grocerylist.recipes = ["\(recipe.id)": recipe.title]
            grocerylist.servings = ["\(recipe.id)": recipe.servings!]
            
            let createGrocerylist = GrocerylistActions(grocerylist: grocerylist, active: false, selectedFalconUsers: self.selectedFalconUsers)
            createGrocerylist.createNewGrocerylist()
                        
            var list = ListContainer()
            list.grocerylist = grocerylist
            listList.append(list)
            
            grocerylistIndex = listList.count - 1
            
            self.updateLists(type: "lists")
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
    
    func getParticipants(transaction: Transaction?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
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


//extension CreateActivityViewController: UITextViewDelegate {
//    
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = true
//        if textView.textColor == FalconPalette.defaultBlue {
//            textView.text = nil
//            textView.textColor = ThemeManager.currentTheme().generalTitleColor
//        }
//        
//        
//    }
//    
//    func textViewDidEndEditing(_ textView: UITextView) {
//        //        createActivityView.activityDescriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
//        if textView.text.isEmpty {
//            textView.text = "Description"
//            textView.textColor = FalconPalette.defaultBlue
//        }
//    }
//    
//    func textViewDidChange(_ textView: UITextView) {
//        
//    }
//    
//}

extension CreateActivityViewController: UpdateActivityCategoryDelegate {
    func update(value: String) {
        if let row: LabelRow = form.rowBy(tag: "Category") {
            row.title = value
            row.updateCell()
            self.activity.category = value
        }
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
                let newLocationName = key.removeCharacters()
                locationRow.title = newLocationName
                locationRow.updateCell()

                self.locationName = newLocationName
                self.locationAddress[newLocationName] = value
                
                self.activity.locationName = newLocationName
                if activity.locationAddress == nil {
                    self.activity.locationAddress = self.locationAddress
                } else {
                    self.activity.locationAddress![newLocationName] = value
                }
                self.weatherRow()
            }
        }
    }
}

extension CreateActivityViewController: UpdateTimeZoneDelegate {
    func updateTimeZone(startOrEndTimeZone: String, timeZone: TimeZone) {
        if startOrEndTimeZone == "startTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone"), let startRow: DateTimeInlineRow = self.form.rowBy(tag: "Starts") {
                startRow.dateFormatter?.timeZone = timeZone
                startRow.updateCell()
                startRow.inlineRow?.cell.datePicker.timeZone = timeZone
                startRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                activity.startTimeZone = timeZone.identifier
            }
        } else if startOrEndTimeZone == "endTimeZone" {
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone"), let endRow: DateTimeInlineRow = self.form.rowBy(tag: "Ends") {
                endRow.dateFormatter?.timeZone = timeZone
                endRow.updateCell()
                endRow.inlineRow?.cell.datePicker.timeZone = timeZone
                endRow.inlineRow?.updateCell()
                timeZoneRow.value = timeZone.identifier
                timeZoneRow.updateCell()
                activity.endTimeZone = timeZone.identifier
            }
        }
    }
}

extension CreateActivityViewController: UpdateScheduleDelegate {
    func updateSchedule(schedule: Activity) {
        if let _ = schedule.name {
            if scheduleList.indices.contains(scheduleIndex), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
                let scheduleRow = mvs.allRows[scheduleIndex]
                scheduleRow.baseValue = schedule
                scheduleRow.reload()
                scheduleList[scheduleIndex] = schedule
            } else {
                var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
                mvs.insert(ScheduleRow() {
                    $0.value = schedule
                    }.onCellSelection() { cell, row in
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_schedule", parameters: [
                    "schedule_name": schedule.name ?? "name" as NSObject,
                    "schedule_type": schedule.activityType ?? "basic" as NSObject
                ])
                scheduleList.append(schedule)
            }
            
            sortSchedule()
            if let localAddress = schedule.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            updateLists(type: "schedule")
        }
    }
    func updateIngredients(recipe: Recipe?, recipeID: String?) {
        if let recipe = recipe {
            updateGrocerylist(recipe: recipe, add: true)
        } else if let recipeID = recipeID {
            lookupRecipe(recipeID: Int(recipeID)!, add: true)
        }
    }
}

extension CreateActivityViewController: ChooseActivityDelegate {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let _ = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    participants.append(user)
                }
                
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(participants)
        }
    }
    
    func chosenActivity(mergeActivity: Activity) {
        if let _: LabelRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        if let _ = mergeActivity.name, let currentUserID = Auth.auth().currentUser?.uid {
            self.getParticipants(forActivity: mergeActivity) { (participants) in
                let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                deleteActivity.deleteActivity()
            }
            
            mergeActivity.participantsIDs = [currentUserID]
            mergeActivity.admin = currentUserID
            
            var mvs = (form.sectionBy(tag: "schedulefields") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = mergeActivity
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_schedule", parameters: [
                "schedule_name": mergeActivity.name ?? "name" as NSObject,
                "schedule_type": mergeActivity.activityType ?? "basic" as NSObject
            ])
            scheduleList.append(mergeActivity)
            
            sortSchedule()
            if let localAddress = mergeActivity.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
            updateLists(type: "schedule")
        }
    }
}

extension CreateActivityViewController: UpdateTransactionDelegate {
    func updateTransaction(transaction: Transaction) {
        if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
            let purchaseRow = mvs.allRows[purchaseIndex]
            if transaction.description != "Transaction Name" {
                purchaseRow.baseValue = transaction
                purchaseRow.updateCell()
                if purchaseList.indices.contains(purchaseIndex) {
                    purchaseList[purchaseIndex] = transaction
                } else {
                    purchaseList.append(transaction)
                }
                updateLists(type: "purchases")
            }
            else {
                mvs.remove(at: purchaseIndex)
            }
        }
    }
}

extension CreateActivityViewController: ChooseTransactionDelegate {
    func chosenTransaction(transaction: Transaction) {
        print("transaction \(transaction.description)")
        if let mvs = self.form.sectionBy(tag: "purchasefields") as? MultivaluedSection {
            let purchaseRow = mvs.allRows[purchaseIndex]
            if transaction.description != "Transaction Name" {
                purchaseRow.baseValue = transaction
                purchaseRow.updateCell()
                if purchaseList.indices.contains(purchaseIndex) {
                    purchaseList[purchaseIndex] = transaction
                } else {
                    purchaseList.append(transaction)
                }
                updateLists(type: "purchases")
            }
            else {
                mvs.remove(at: purchaseIndex)
            }
//            purchaseBreakdown()
        }
    }
}

extension CreateActivityViewController: UpdateChecklistDelegate {
    func updateChecklist(checklist: Checklist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if checklist.name != "CheckListName" {
                listRow.baseValue = checklist
                listRow.title = checklist.name
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].checklist = checklist
                } else {
                    var list = ListContainer()
                    list.checklist = checklist
                    listList.append(list)
                }
                updateLists(type: "lists")
            }
            else {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension CreateActivityViewController: UpdateActivitylistDelegate {
    func updateActivitylist(activitylist: Activitylist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if activitylist.name != "ActivityListName" {
                listRow.baseValue = activitylist
                listRow.title = activitylist.name
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].activitylist = activitylist
                } else {
                    var list = ListContainer()
                    list.activitylist = activitylist
                    listList.append(list)
                }
                updateLists(type: "lists")
            }
            else {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension CreateActivityViewController: UpdatePackinglistDelegate {
    func updatePackinglist(packinglist: Packinglist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if packinglist.name != "PackingListName" {
                listRow.title = packinglist.name
                listRow.baseValue = packinglist
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].packinglist = packinglist
                } else {
                    var list = ListContainer()
                    list.packinglist = packinglist
                    listList.append(list)
                }
                updateLists(type: "lists")
            } else {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension CreateActivityViewController: UpdateGrocerylistDelegate {
    func updateGrocerylist(grocerylist: Grocerylist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            if grocerylist.name != "GroceryListName" {
                let listRow = mvs.allRows[grocerylistIndex]
                listRow.baseValue = grocerylist
                listRow.title = grocerylist.name
                listRow.updateCell()
                if listList.indices.contains(grocerylistIndex) {
                    listList[grocerylistIndex].grocerylist = grocerylist
                } else {
                    var list = ListContainer()
                    list.grocerylist = grocerylist
                    listList.append(list)
                }
                updateLists(type: "lists")
            } else {
                mvs.remove(at: grocerylistIndex)
                activity.grocerylistID = nil
            }
        }
    }
}

extension CreateActivityViewController: ChooseListDelegate {
    func chosenList(list: ListContainer) {
        if let checklist = list.checklist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if checklist.name != "CheckListName" {
                    listRow.baseValue = checklist
                    listRow.title = checklist.name
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].checklist = checklist
                    } else {
                        var list = ListContainer()
                        list.checklist = checklist
                        listList.append(list)
                    }
                    updateLists(type: "lists")
                }
                else {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let activitylist = list.activitylist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if activitylist.name != "ActivityListName" {
                    listRow.baseValue = activitylist
                    listRow.title = activitylist.name
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].activitylist = activitylist
                    } else {
                        var list = ListContainer()
                        list.activitylist = activitylist
                        listList.append(list)
                    }
                    updateLists(type: "lists")
                }
                else {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let grocerylist = list.grocerylist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if grocerylist.name != "GroceryListName" {
                    listRow.title = grocerylist.name
                    listRow.baseValue = grocerylist
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].grocerylist = grocerylist
                    } else {
                        var list = ListContainer()
                        list.grocerylist = grocerylist
                        listList.append(list)
                    }
                    grocerylistIndex = listIndex
                    updateLists(type: "lists")
                } else {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let packinglist = list.packinglist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if packinglist.name != "PackingListName" {
                    listRow.title = packinglist.name
                    listRow.baseValue = packinglist
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].packinglist = packinglist
                    } else {
                        var list = ListContainer()
                        list.packinglist = packinglist
                        listList.append(list)
                    }
                    updateLists(type: "lists")
                } else {
                    mvs.remove(at: listIndex)
                }
            }
        } else {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension CreateActivityViewController: UpdateActivityMediaDelegate {
    func updateActivityMedia(activityPhotos: [String], activityFiles: [String]) {
        activity.activityPhotos = activityPhotos
        activity.activityFiles = activityFiles
        if let mediaRow: ButtonRow = form.rowBy(tag: "Media") {
            if self.activity.activityPhotos == nil || self.activity.activityPhotos!.isEmpty || self.activity.activityFiles == nil || self.activity.activityFiles!.isEmpty {
                mediaRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            } else {
                mediaRow.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }
        }
    }
}

extension CreateActivityViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activityID = activityID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)

            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activities != nil {
                    var activities = conversation.activities!
                    activities.append(activityID)
                    let updatedActivities = ["activities": activities as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                } else {
                    let updatedActivities = ["activities": [activityID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                }
                if activity.grocerylistID != nil {
                    if conversation.grocerylists != nil {
                        var grocerylists = conversation.grocerylists!
                        grocerylists.append(activity.grocerylistID!)
                        let updatedGrocerylists = [grocerylistsEntity: grocerylists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                    } else {
                        let updatedGrocerylists = [grocerylistsEntity: [activity.grocerylistID!] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedGrocerylists)
                    }
                    Database.database().reference().child(grocerylistsEntity).child(activity.grocerylistID!).updateChildValues(updatedConversationID)
                }
                if activity.checklistIDs != nil {
                    if conversation.checklists != nil {
                        let checklists = conversation.checklists! + activity.checklistIDs!
                        let updatedChecklists = [checklistsEntity: checklists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                    } else {
                        let updatedChecklists = [checklistsEntity: activity.checklistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedChecklists)
                    }
                    for ID in activity.checklistIDs! {
                        Database.database().reference().child(checklistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
                if activity.activitylistIDs != nil {
                    if conversation.activitylists != nil {
                        let activitylists = conversation.activitylists! + activity.activitylistIDs!
                        let updatedActivitylists = [activitylistsEntity: activitylists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                    } else {
                        let updatedActivitylists = [activitylistsEntity: activity.activitylistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                    }
                    for ID in activity.activitylistIDs! {
                        Database.database().reference().child(activitylistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
                if activity.packinglistIDs != nil {
                    if conversation.packinglists != nil {
                        let packinglists = conversation.packinglists! + activity.packinglistIDs!
                        let updatedPackinglists = [packinglistsEntity: packinglists as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                    } else {
                        let updatedPackinglists = [packinglistsEntity: activity.packinglistIDs! as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedPackinglists)
                    }
                   for ID in activity.packinglistIDs! {
                        Database.database().reference().child(packinglistsEntity).child(ID).updateChildValues(updatedConversationID)

                    }
                }
            }
            self.connectedToChatAlert()
            self.dismiss(animated: true, completion: nil)
        }
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
