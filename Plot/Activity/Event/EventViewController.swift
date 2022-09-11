//
//  EventViewController.swift
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
import CodableFirebase
import RRuleSwift
import HealthKit

class EventViewController: FormViewController {
    var activity: Activity!
    var activityOld: Activity!
    var invitation: Invitation?
    
    weak var delegate : UpdateActivityDelegate?
    
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
    lazy var activities: [Activity] = networkController.activityService.events
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var calendars: [String: [CalendarType]] = networkController.activityService.calendars
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var purchaseUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    let avatarOpener = AvatarOpener()
    var locationName : String = "locationName"
    var locationAddress = [String : [Double]]()
    var scheduleList = [Activity]()
    var container: Container!
    var purchaseList = [Transaction]()
    var purchaseDict = [User: Double]()
    var listList = [ListContainer]()
    var healthList = [HealthContainer]()
    var calendar: CalendarType!
    var purchaseIndex: Int = 0
    var listIndex: Int = 0
    var healthIndex: Int = 0
    var taskList = [Activity]()
    var taskIndex: Int = 0
    var grocerylistIndex: Int = -1
    var startDateTime: Date?
    var endDateTime: Date?
    var thumbnailImage: String = ""
    var segmentRowValue: String = "Health"
    var activityID = String()
    let informationMessageSender = InformationMessageSender()
    // Participants with accepted invites
    var acceptedParticipant: [User] = []
    var weather: [DailyWeatherElement]!
        
    var active = false
    var sectionChanged: Bool = false
    
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    typealias CompletionHandler = (_ success: Bool) -> Void
    
    var activityAvatarURL = String() {
        didSet {
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Event Image")!
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
            activityOld = activity.copy() as? Activity
            if activity.activityID != nil {
                activityID = activity.activityID!
            }
            if activity.admin == nil, let currentUserID = Auth.auth().currentUser?.uid {
                activity.admin = currentUserID
            }
            if let localName = activity.locationName, localName != "locationName", let localAddress = activity.locationAddress {
                locationName = localName
                locationAddress = localAddress
                //                self.weatherRow()
            }
            setupLists()
            resetBadgeForSelf()
        } else {
            title = "New Event"
            if let currentUserID = Auth.auth().currentUser?.uid {
                //create new activityID for auto updating items (schedule, purchases, checklist)
                activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                let original = Date()
                let rounded = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                
                if let calendar = calendar {
                    activity = Activity(activityID: activityID, admin: currentUserID, calendarID: calendar.id ?? "", calendarName: calendar.name ?? "", calendarColor: calendar.color ?? "", calendarSource: calendar.source ?? "", allDay: false, startDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), startTimeZone: TimeZone.current.identifier, endDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), endTimeZone: TimeZone.current.identifier, isEvent: true)
                } else {
                    let calendar = calendars[CalendarSourceOptions.plot.name]?.first { $0.name == "Default"}
                    activity = Activity(activityID: activityID, admin: currentUserID, calendarID: calendar?.id ?? "", calendarName: calendar?.name ?? "", calendarColor: calendar?.color ?? "", calendarSource: calendar?.source ?? "", allDay: false, startDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), startTimeZone: TimeZone.current.identifier, endDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), endTimeZone: TimeZone.current.identifier, isEvent: true)

                }
            }
        }
        
        setupRightBarButton()
        initializeForm()
        
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
    
    func setupRightBarButton() {
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = plusBarButton
            navigationItem.rightBarButtonItem?.isEnabled = false
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        } else if delegate != nil {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = plusBarButton
            navigationItem.rightBarButtonItem?.isEnabled = true
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
        
        <<< TextRow("Name") {
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
        }
        
        <<< ButtonRow("Location") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textAlignment = .left
            if self.active, let localName = activity.locationName, localName != "locationName" {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.accessoryType = .detailDisclosureButton
                row.title = localName
            } else {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
            }
        }.onCellSelection({ _,_ in
            self.openLocationFinder()
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textAlignment = .left
            if row.title == "Location" {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.accessoryType = .disclosureIndicator
            } else if let value = row.title, !value.isEmpty {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.accessoryType = .detailDisclosureButton
            } else {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Location"
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
                if let timeZone = activity.startTimeZone {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: timeZone)
                }
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
                    let original = startDateTime
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.activity.startDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                } else {
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
                self!.updateRepeatReminder()
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
            row.cell.selectionStyle = .default
            row.title = "Time Zone"
            row.hidden = true
            if active, let timeZone = activity.startTimeZone {
                row.value = timeZone
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
                if let timeZone = activity.endTimeZone {
                    $0.dateFormatter?.timeZone = TimeZone(identifier: timeZone)
                }
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
                    let original = endDateTime
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    $0.value = rounded
                    self.activity.endDateTime = NSNumber(value: Int(($0.value!).timeIntervalSince1970))
                } else {
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
            row.cell.selectionStyle = .default
            row.title = "Time Zone"
            row.hidden = true
            
            if active, let timeZone = activity.endTimeZone {
                row.value = timeZone
            }
//            else {
//                row.value = TimeZone.current.identifier
//                activity.endTimeZone = TimeZone.current.identifier
//            }
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
            row.cell.selectionStyle = .default
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
            if self.active, let value = self.activity.reminder {
                row.value = EventAlert(rawValue: value)
            } else {
                row.value = EventAlert.None
                if let reminder = row.value?.description {
                    self.activity.reminder = reminder
                }
            }
            row.options = EventAlert.allCases
        }.onPresent { from, to in
            to.title = "Reminder"
            to.extendedLayoutIncludesOpaqueBars = true
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
        
        <<< LabelRow("Participants") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.cell.accessoryType = .disclosureIndicator
            row.cell.textLabel?.textAlignment = .left
            row.cell.selectionStyle = .default
            row.title = row.tag
            if activity.admin == nil || activity.admin == Auth.auth().currentUser?.uid {
                row.value = String(self.acceptedParticipant.count + 1)
            } else {
                row.value = String(self.acceptedParticipant.count)
            }
        }.onCellSelection({ _, row in
            self.openParticipantsInviter()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            cell.textLabel?.textAlignment = .left
        }
        
        <<< LabelRow("Calendar") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if self.active && self.activity.calendarName != nil {
                row.value = self.activity.calendarName
            } else {
                row.value = "Default"
            }
        }.onCellSelection({ _, row in
            self.openCalendar()
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
            row.cell.selectionStyle = .default
            row.title = row.tag
            if self.active && self.activity.category != nil {
                row.value = self.activity.category
            } else {
                row.value = "Uncategorized"
            }
        }.onCellSelection({ _, row in
            self.openLevel(value: row.value ?? "Uncategorized", level: "Category")
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            cell.textLabel?.textAlignment = .left
        }
        
        //        if let _ = activity.activityType {
        //            form.last!
        //            <<< LabelRow("Subcategory") { row in
        //                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        //                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        //                row.cell.accessoryType = .disclosureIndicator
        //                row.cell.selectionStyle = .default
        //                row.title = row.tag
        //                if self.active && self.activity.activityType != "nothing" && self.activity.activityType != nil {
        //                    row.value = self.activity.activityType!
        //                } else {
        //                    row.value = "Uncategorized"
        //                }
        //            }.onCellSelection({ _, row in
        //                self.openLevel(value: row.value ?? "Uncategorized", level: "Subcategory")
        //            }).cellUpdate { cell, row in
        //                cell.accessoryType = .disclosureIndicator
        //                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        //                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        //                cell.textLabel?.textAlignment = .left
        //            }
        //        }
        
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
            if !row.value!, let segmentRow : SegmentedRow<String> = self!.form.rowBy(tag: "sections") {
                self?.segmentRowValue = segmentRow.value ?? "Health"
                segmentRow.value = "Hidden"
            } else if let segmentRow : SegmentedRow<String> = self?.form.rowBy(tag: "sections") {
                segmentRow.value = self?.segmentRowValue
            }
            guard let currentUserID = Auth.auth().currentUser?.uid else { return }
            let userReference = Database.database().reference().child(userActivitiesEntity).child(currentUserID).child(self!.activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["showExtras": row.value ?? false]
            userReference.updateChildValues(values)
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        
        <<< ButtonRow("Sub-Events") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.cell.textLabel?.textAlignment = .left
            row.cell.accessoryType = .disclosureIndicator
            row.title = row.tag
            row.hidden = "$showExtras == false"
            if let scheduleIDs = self.activity.scheduleIDs, !scheduleIDs.isEmpty {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            } else {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }.onCellSelection({ _,_ in
            self.openSchedule()
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textAlignment = .left
            if let scheduleIDs = self.activity.scheduleIDs, !scheduleIDs.isEmpty {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            } else {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }
        
        <<< ButtonRow("Checklists") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textAlignment = .left
            row.cell.accessoryType = .disclosureIndicator
            row.title = row.tag
            row.hidden = "$showExtras == false"
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
            row.hidden = "$showExtras == false"
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
        
        <<< LabelRow("Tags") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.accessoryType = .disclosureIndicator
            row.cell.textLabel?.textAlignment = .left
            row.cell.selectionStyle = .default
            row.hidden = "$showExtras == false"
            row.title = row.tag
        }.onCellSelection({ _, row in
            self.openTags()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.textLabel?.textAlignment = .left
            if let tags = self.activity.tags, !tags.isEmpty {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            } else {
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }
        
        //            <<< TextAreaRow("Notes") {
        //                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
        //                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        //                $0.placeholder = $0.tag
        //                $0.hidden = "$showExtras == false"
        //                if self.active && self.activity.notes != "nothing" && self.activity.notes != nil {
        //                    $0.value = self.activity.notes
        //                }
        //                }.cellUpdate({ (cell, row) in
        //                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                    cell.textView?.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        //                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
        //                }).onChange() { [unowned self] row in
        //                    self.activity.notes = row.value
        //                }
        
        if delegate == nil {
            form.last!
            <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.hidden = "$showExtras == false"
                if #available(iOS 13.0, *) {
                    $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                }
                $0.options = ["Tasks", "Health", "Transactions"]
                if !(activity.showExtras ?? true) {
                    $0.value = "Hidden"
                } else {
                    $0.value = "Tasks"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange({ _ in
                self.sectionChanged = true
            })
            
            form +++
                MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: "Tasks",
                                   footer: "Connect an task") {
                                    $0.tag = "Tasks"
                                    $0.hidden = "!$sections == 'Tasks'"
                                    $0.addButtonProvider = { section in
                                        return ButtonRow("taskButton"){
                                            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            $0.title = "Connect Task"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                                cell.textLabel?.textAlignment = .left
                                                cell.height = { 60 }
                                            }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        return SubtaskRow("label"){ _ in
                                            self.taskIndex = index
                                            self.openTask()
                                        }
                                    }

                                }
            
            form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Health",
                               footer: "Connect a workout and/or mindfulness session") {
                $0.tag = "Health"
                $0.hidden = "$sections != 'Health'"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.title = "Connect Health"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textAlignment = .left
                        cell.height = { 60 }
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    self.healthIndex = index
                    self.openHealth()
                    return HealthRow()
                        .onCellSelection() { cell, row in
                            self.healthIndex = index
                            self.openHealth()
                            cell.cellResignFirstResponder()
                        }
                    
                }
                
            }
            
            form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Transactions",
                               footer: "Connect a transaction") {
                $0.tag = "Transactions"
                $0.hidden = "$sections != 'Transactions'"
                $0.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.title = "Connect Transaction"
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
        }
        
        //                                    form +++
        //                                        Section(header: "Balances",
        //                                                footer: "Positive Balance = Owe; Negative Balance = Owed") {
        //                                                    $0.tag = "Balances"
        //                                                    $0.hidden = "$sections != 'Transactions'"
        //                                    }
    }
    
    override func sectionsHaveBeenAdded(_ sections: [Section], at indexes: IndexSet) {
        super.sectionsHaveBeenAdded(sections, at: indexes)
        if sectionChanged, let section = indexes.first {
            let row = tableView.numberOfRows(inSection: section) - 1
            let indexPath = IndexPath(row: row, section: section)
            DispatchQueue.main.async {
                self.tableView?.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
            sectionChanged = false
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let row = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if row is PurchaseRow {
                if self!.purchaseList.indices.contains(rowNumber) {
                    self!.purchaseList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    //                    self!.purchaseBreakdown()
                }
            }
            else if row is HealthRow {
                if self!.healthList.indices.contains(rowNumber) {
                    self!.healthList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                }
            }
            else if row is SubtaskRow {
                if self!.taskList.indices.contains(rowNumber) {
                    self!.taskList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                }
            }
        }
    }
}
