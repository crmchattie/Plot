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
import RRuleSwift

class CreateActivityViewController: FormViewController {
    var activity: Activity!
    var activityOld: Activity!
    var invitation: Invitation?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var activities: [Activity] = networkController.activityService.activities
    lazy var calendars: [String: [CalendarType]] = networkController.activityService.calendars
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var purchaseUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    var conversation: Conversation!
    let avatarOpener = AvatarOpener()
    var locationName : String = "locationName"
    var locationAddress = [String : [Double]]()
    var scheduleList = [Activity]()
    var purchaseList = [Transaction]()
    var purchaseDict = [User: Double]()
    var listList = [ListContainer]()
    var healthList = [HealthContainer]()
    var scheduleIndex: Int = 0
    var purchaseIndex: Int = 0
    var listIndex: Int = 0
    var healthIndex: Int = 0
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
    
    var activityAvatarURL = String() {
        didSet {
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
            viewRow.cell.view!.showActivityIndicator()
            viewRow.cell.view!.sd_setImage(with: URL(string:activityAvatarURL), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                viewRow.cell.view!.hideActivityIndicator()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMainView()
        
        if activity != nil {
            title = "Event"
            active = true
            activityOld = activity
            if activity.activityID != nil {
                activityID = activity.activityID!
            }
            if let localName = activity.locationName, localName != "locationName", let localAddress = activity.locationAddress {
                locationName = localName
                locationAddress = localAddress
//                self.weatherRow()
            }
            setupLists()
            setupRightBarButton(with: "Update")
            resetBadgeForSelf()
        } else {
            title = "New Event"
            if let currentUserID = Auth.auth().currentUser?.uid {
                //create new activityID for auto updating items (schedule, purchases, checklist)
                activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
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
        extendedLayoutIncludesOpaqueBars = true
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
            
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
            
        } else {
            let dotsImage = UIImage(named: "dots")
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(createNewActivity))
            let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
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
                    if row.value == nil {
                        let reference = Database.database().reference().child(activitiesEntity).child(self.activityID).child(messageMetaDataFirebaseFolder).child("activityDescription")
                        reference.removeValue()
                    }
                }
        
            <<< LabelRow("Calendar") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active && self.activity.calendarName != nil {
                    row.value = self.activity.calendarName
                } else {
                    row.value = row.tag
                }
            }.onCellSelection({ _, row in
                self.openCalendar(value: row.title ?? "Calendar")
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
            
            <<< LabelRow("Category") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active && self.activity.category != nil {
                    row.value = self.activity.category
                } else {
                    row.value = "Uncategorized"
                }
            }.onCellSelection({ _, row in
                self.openCategory(value: row.title ?? "Uncategorized")
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        
//            <<< LabelRow("Subcategory") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                row.cell.accessoryType = .disclosureIndicator
//                row.title = row.tag
//                if self.active && self.activity.activityType != "nothing" && self.activity.activityType != nil {
//                    row.value = self.activity.activityType!
//                }
//            }.onCellSelection({ _, row in
////                self.openCategory(value: row.title ?? "Uncategorized")
//            }).cellUpdate { cell, row in
//                cell.accessoryType = .disclosureIndicator
//                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                cell.textLabel?.textAlignment = .left
//            }
            
            <<< ButtonRow("Location") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active, let localName = activity.locationName, localName != "locationName" {
                    row.cell.accessoryType = .detailDisclosureButton
                    row.title = localName
                }
                }.onCellSelection({ _,_ in
                    self.openLocationFinder()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Location" {
                        cell.accessoryType = .disclosureIndicator
                    } else if let value = row.title, !value.isEmpty {
                        cell.accessoryType = .detailDisclosureButton
                    } else {
                        cell.accessoryType = .disclosureIndicator
                        cell.textLabel?.text = "Location"
                    }
                }
            
        
//            <<< ButtonRow("Participants") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textAlignment = .left
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                row.cell.accessoryType = .disclosureIndicator
//                row.title = row.tag
//                if self.acceptedParticipant.count > 0 {
//                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    row.title = self.userNamesString
//                }
//                }.onCellSelection({ _,_ in
//                    self.openParticipantsInviter()
//                }).cellUpdate { cell, row in
//                    cell.accessoryType = .disclosureIndicator
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textAlignment = .left
//                    if row.title == "Participants" {
//                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
//                    } else {
//                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                    }
//                }
            
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
                    if let startDateTime = startDateTime {
                        $0.dateFormatter?.timeZone = .current
                        let original = startDateTime
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        $0.value = rounded
                        self.activity.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                    } else {
                        $0.dateFormatter?.timeZone = .current
                        let original = Date()
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        $0.value = rounded
                        self.activity.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                    }
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
//                    self!.weatherRow()
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
                    if let endDateTime = endDateTime {
                        $0.dateFormatter?.timeZone = .current
                        let original = endDateTime
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        $0.value = rounded
                        self.activity.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                    } else {
                        $0.dateFormatter?.timeZone = .current
                        let original = Date()
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        $0.value = rounded
                        self.activity.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                    }
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
//                    self!.weatherRow()
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
        
        
            <<< LabelRow("Repeat") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.active, let recurrences = self.activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let startDate = activity.startDate {
                    row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate)
                } else {
                    row.value = "Never"
                }
            }.onCellSelection({ _, row in
                self.openRepeat()
            }).cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .left
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.accessoryType = .disclosureIndicator
            }
        
            <<< PushRow<EventAlert>("Reminder") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.title = row.tag
                if self.active && self.activity.reminder != nil {
                    if let value = self.activity.reminder {
                        row.value = EventAlert(rawValue: value)
                    }
                } else {
                    row.value = EventAlert.None
                    if let reminder = row.value?.description {
                        self.activity.reminder = reminder
                    }
                }
                row.options = EventAlert.allCases
            }.onPresent { from, to in
                to.title = "Reminder"
                to.tableViewStyle = .insetGrouped
                to.selectableRowCellUpdate = { cell, row in
                    to.navigationController?.navigationBar.backgroundColor = ThemeManager.currentTheme().barBackgroundColor
                    to.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    to.tableView.separatorStyle = .none
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
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
        
            <<< ButtonRow("Checklists") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
                if self.activity.checklistIDs != nil || self.activity.grocerylistID != nil || self.activity.activitylistIDs != nil {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                } else {
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }
                }.onCellSelection({ _,_ in
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.accessoryType = .disclosureIndicator
                    cell.textLabel?.textAlignment = .left
                    if let _ = self.activity.checklistIDs {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
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
                    if row.value == nil {
                        let reference = Database.database().reference().child(activitiesEntity).child(self.activityID).child(messageMetaDataFirebaseFolder).child("notes")
                        reference.removeValue()
                    }
                }
        
//        <<< SwitchRow("showExtras") { row in
//                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                row.title = "Show Extras"
//                if let showExtras = activity.showExtras {
//                    row.value = showExtras
//                } else {
//                    row.value = true
//                    self.activity.showExtras = true
//                }
//            }.onChange { [weak self] row in
//                self!.activity.showExtras = row.value
//                if !row.value!, let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
//                    self!.segmentRowValue = segmentRow.value!
//                    segmentRow.value = "Hidden"
//                } else if let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
//                    segmentRow.value = self!.segmentRowValue
//                }
//                guard let currentUserID = Auth.auth().currentUser?.uid else { return }
//                let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self!.activityID).child(messageMetaDataFirebaseFolder)
//                let values:[String : Any] = ["showExtras": row.value ?? false]
//                userReference.updateChildValues(values)
//            }.cellUpdate { cell, row in
//                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//            }
//
//        <<< SegmentedRow<String>("sections"){
//                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                $0.hidden = "$showExtras == false"
//                if #available(iOS 13.0, *) {
//                    $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
//                } else {
//                    // Fallback on earlier versions
//                }
//                $0.options = ["Schedule", "Health", "Transactions"]
//                $0.value = "Schedule"
//                }.cellUpdate { cell, row in
//                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                }
//
//        form +++
//            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                               header: "Schedule",
//                               footer: "Add an activity to the schedule") {
//                                $0.tag = "schedulefields"
//                                $0.hidden = "!$sections == 'Schedule'"
//                                $0.addButtonProvider = { section in
//                                    return ButtonRow(){
//                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                        $0.title = "Add Activity Item"
//                                        }.cellUpdate { cell, row in
//                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                            cell.textLabel?.textAlignment = .left
//                                            cell.height = { 60 }
//                                        }
//                                }
//                                $0.multivaluedRowToInsertAt = { index in
//                                    self.scheduleIndex = index
//                                    self.openSchedule()
//                                    return ScheduleRow("label"){
//                                        $0.value = Activity(dictionary: ["name": "Activity" as AnyObject])
//                                    }
//                                }
//
//                            }
//
//    form +++
//        MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                           header: "Health",
//                           footer: "Add a meal, workout and/or mindfulness") {
//                            $0.tag = "healthfields"
//                            $0.hidden = "$sections != 'Health'"
//                            $0.addButtonProvider = { section in
//                                return ButtonRow(){
//                                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                    $0.title = "Add Health Item"
//                                    }.cellUpdate { cell, row in
//                                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                        cell.textLabel?.textAlignment = .left
//                                    }
//                            }
//                            $0.multivaluedRowToInsertAt = { index in
//                                self.healthIndex = index
//                                self.openHealth()
//                                return ButtonRow() { row in
//                                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                row.cell.textLabel?.textAlignment = .left
//                                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                                row.title = "Health"
//                                }.onCellSelection({ _,_ in
//                                    self.healthIndex = index
//                                    self.openHealth()
//                                }).cellUpdate { cell, row in
//                                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                    cell.textLabel?.textAlignment = .left
//                                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
//                                }
//                            }
//
//    }
//
//        form +++
//            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
//                               header: "Transactions",
//                               footer: "Add a transaction") {
//                                $0.tag = "purchasefields"
//                                $0.hidden = "$sections != 'Transactions'"
//                                $0.addButtonProvider = { section in
//                                    return ButtonRow(){
//                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                        $0.title = "Add Transaction Item"
//                                        }.cellUpdate { cell, row in
//                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
//                                            cell.textLabel?.textAlignment = .left
//                                            cell.height = { 60 }
//                                    }
//                                }
//                                $0.multivaluedRowToInsertAt = { index in
//                                    self.purchaseIndex = index
//                                    self.openPurchases()
//                                    return PurchaseRow()
//                                        .onCellSelection() { cell, row in
//                                            self.purchaseIndex = index
//                                            self.openPurchases()
//                                            cell.cellResignFirstResponder()
//                                    }
//
//                                }
//            }

    //                                form +++
    //                                    Section(header: "Balances",
    //                                            footer: "Positive Balance = Owe; Negative Balance = Owed") {
    //                                                $0.tag = "Balances"
    //                                                $0.hidden = "$sections != 'Transactions'"
    //                                }
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
//                    self!.purchaseBreakdown()
                }
                self!.updateLists(type: "purchases")
            }
            else if rowType is HealthRow {
                if self!.healthList.indices.contains(self!.healthIndex) {
                    self!.healthList.remove(at: rowNumber)
                }
                self!.updateLists(type: "health")
            }
//            else if rowType is ButtonRow, rows[0].title != "Add Activity Item",  rows[0].title != "Add Checklist Item", rows[0].title != "Add Transaction Item" {
//                if self!.listList.indices.contains(self!.listIndex) {
//                    self!.listList.remove(at: rowNumber)
//                }
//                if rowNumber == self!.grocerylistIndex {
//                    self!.grocerylistIndex = -1
//                }
//                self!.updateLists(type: "lists")
//            }
        }
    }
}
