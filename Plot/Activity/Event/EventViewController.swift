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
    
    var transaction: Transaction!
    var workout: Workout!
    var mindfulness: Mindfulness!
    var task: Activity!
    var template: Template!
        
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
                print(activityID)
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
                if let transaction = transaction, let activity = EventBuilder.createActivity(from: transaction), let activityID = activity.activityID {
                    self.activity = activity
                    self.activityID = activityID
                } else if let workout = workout, let activity = EventBuilder.createActivity(from: workout), let activityID = activity.activityID {
                    self.activity = activity
                    self.activityID = activityID
                } else if let mindfulness = mindfulness, let activity = EventBuilder.createActivity(from: mindfulness), let activityID = activity.activityID {
                    self.activity = activity
                    self.activityID = activityID
                } else if let task = task, let activity = EventBuilder.createActivity(task: task), let activityID = activity.activityID {
                    self.activity = activity
                    self.activityID = activityID
                } else if let template = template, let activityList = EventBuilder.createActivity(template: template), let activity = activityList.0, let activityID = activity.activityID {
                    self.activityID = activityID
                    self.activity = activity
                    scheduleList = activityList.1 ?? []
                    if !scheduleList.isEmpty {
                        sortSchedule()
                        updateLists(type: "schedule")
                    }
                } else {
                    activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                    print(activityID)
                    let original = Date()
                    let rounded = Date(timeIntervalSinceReferenceDate:
                                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                    
                    if let calendar = calendar {
                        activity = Activity(activityID: activityID, admin: currentUserID, calendarID: calendar.id ?? "", calendarName: calendar.name ?? "", calendarColor: calendar.color ?? CIColor(color: ChartColors.palette()[1]).stringRepresentation, calendarSource: calendar.source ?? "", allDay: false, startDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), startTimeZone: TimeZone.current.identifier, endDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), endTimeZone: TimeZone.current.identifier, isEvent: true, createdDate: NSNumber(value: Int((rounded).timeIntervalSince1970)))
                    } else {
                        let calendar = calendars[CalendarSourceOptions.plot.name]?.first { $0.defaultCalendar ?? false }
                        activity = Activity(activityID: activityID, admin: currentUserID, calendarID: calendar?.id ?? "", calendarName: calendar?.name ?? "", calendarColor: calendar?.color ?? CIColor(color: ChartColors.palette()[1]).stringRepresentation, calendarSource: calendar?.source ?? "", allDay: false, startDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), startTimeZone: TimeZone.current.identifier, endDateTime: NSNumber(value: Int((rounded).timeIntervalSince1970)), endTimeZone: TimeZone.current.identifier, isEvent: true, createdDate: NSNumber(value: Int((rounded).timeIntervalSince1970)))

                    }
                }

                if let container = container {
                    activity.containerID = container.id
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
        
        if active, let currentUser = Auth.auth().currentUser?.uid, let participantsIDs = activity?.participantsIDs, !participantsIDs.contains(currentUser) {
            navigationItem.rightBarButtonItems = []
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate func setupMainView() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        navigationOptions = .Disabled
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
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .label
            $0.placeholderColor = .secondaryLabel
            $0.placeholder = $0.tag
            if let activity = activity, let name = activity.name {
                $0.value = name
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
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .label
        }
        
        
        <<< TextAreaRow("Description") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.textColor = .label
            $0.cell.placeholderLabel?.textColor = .secondaryLabel
            $0.placeholder = $0.tag
            if let activity = activity, let description = activity.activityDescription, description != "nothing" {
                $0.value = description
            }
        }.cellUpdate({ (cell, row) in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textView?.backgroundColor = .secondarySystemGroupedBackground
            cell.textView?.textColor = .label
        }).onChange() { [unowned self] row in
            self.activity.activityDescription = row.value
        }
        
        <<< LabelRow("Location") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            if let activity = activity, let localName = activity.locationName, localName != "locationName" {
                row.cell.textLabel?.textColor = .label
                row.cell.accessoryType = .detailDisclosureButton
                row.title = localName
            } else {
                row.cell.textLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.title = row.tag
            }
        }.onCellSelection({ _,_ in
            self.openLocationFinder()
        }).cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textAlignment = .left
            if row.title == "Location" {
                cell.textLabel?.textColor = .secondaryLabel
                cell.accessoryType = .disclosureIndicator
            } else if let value = row.title, !value.isEmpty {
                cell.textLabel?.textColor = .label
                cell.accessoryType = .detailDisclosureButton
            } else {
                cell.textLabel?.textColor = .secondaryLabel
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Location"
            }
        }
        
        <<< SwitchRow("All-day") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.title = $0.tag
            if let activity = activity, let allDay = activity.allDay {
                $0.value = allDay
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
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        
        //add Soon option to replace time; will require update to end time as well
        <<< DateTimeInlineRow("Starts") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.minuteInterval = 5
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            if let activity = activity {
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
        }.onChange { [weak self] row in
            let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
            if row.value?.compare(endRow.value!) == .orderedDescending {
                endRow.value = Date(timeInterval: 0, since: row.value!)
                endRow.updateCell()
            }
            self!.activity.startDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
            if self!.active {
                self!.updateRepeatReminder()
            }
            //                    self!.weatherRow()
        }.onExpandInlineRow { [weak self] cell, row, inlineRow in
            inlineRow.cellUpdate { (cell, row) in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.tintColor = .secondarySystemGroupedBackground
                if #available(iOS 14.0, *) {
                    cell.datePicker.preferredDatePickerStyle = .inline
                    cell.datePicker.tintColor = .systemBlue
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
            cell.detailTextLabel?.textColor = .secondaryLabel
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "startTimeZone") {
                timeZoneRow.hidden = true
                timeZoneRow.evaluateHidden()
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        <<< LabelRow("startTimeZone") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = "Time Zone"
            row.hidden = true
            if let activity = activity, let timeZone = activity.startTimeZone {
                row.value = timeZone
            }
        }.onCellSelection({ _,_ in
            self.openTimeZoneFinder(startOrEndTimeZone: "startTimeZone")
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        <<< DateTimeInlineRow("Ends") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.detailTextLabel?.textColor = .secondaryLabel
            $0.title = $0.tag
            $0.minuteInterval = 5
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            if let activity = activity {
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
        }.onChange { [weak self] row in
            let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
            if row.value?.compare(startRow.value!) == .orderedAscending {
                startRow.value = Date(timeInterval: 0, since: row.value!)
                startRow.updateCell()
            }
            self!.activity.endDateTime = NSNumber(value: Int((row.value!).timeIntervalSince1970))
            //                    self!.weatherRow()
        }.onExpandInlineRow { [weak self] cell, row, inlineRow in
            inlineRow.cellUpdate { (cell, row) in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.tintColor = .secondarySystemGroupedBackground
                if let endTimeZone = self?.activity.endTimeZone {
                    cell.datePicker.timeZone = TimeZone(identifier: endTimeZone)
                }
                if #available(iOS 14.0, *) {
                    cell.datePicker.preferredDatePickerStyle = .inline
                    cell.datePicker.tintColor = .systemBlue
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
            cell.detailTextLabel?.textColor = .secondaryLabel
            if let timeZoneRow: LabelRow = self.form.rowBy(tag: "endTimeZone") {
                timeZoneRow.hidden = true
                timeZoneRow.evaluateHidden()
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            
        }
        
        <<< LabelRow("endTimeZone") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = "Time Zone"
            row.hidden = true
            if let activity = activity, let timeZone = activity.endTimeZone {
                row.value = timeZone
            }
        }.onCellSelection({ _,_ in
            self.openTimeZoneFinder(startOrEndTimeZone: "endTimeZone")
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        
        <<< LabelRow("Repeat") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let activity = activity, let recurrences = activity.recurrences, let recurrenceRule = RecurrenceRule(rruleString: recurrences[0]), let startDate = activity.startDate {
                row.value = recurrenceRule.typeOfRecurrence(language: .english, occurrence: startDate)
            } else {
                row.value = "Never"
            }
        }.onCellSelection({ _, row in
            self.openRepeat()
        }).cellUpdate { cell, row in
            cell.textLabel?.textAlignment = .left
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.accessoryType = .disclosureIndicator
        }
        
        <<< PushRow<EventAlert>("Reminder") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            if let activity = activity, let value = activity.reminder {
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
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                to.tableView.separatorStyle = .none
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
        }.onChange() { [unowned self] row in
            if let reminder = row.value?.description {
                self.activity.reminder = reminder
                if self.active {
                    self.scheduleReminder()
                }
            }
        }
        
        if delegate == nil {
            form.last!
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textColor = .label
                row.cell.detailTextLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                row.value = String(selectedFalconUsers.count + 1)
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.textLabel?.textAlignment = .left
            }
        }
        
        form.last!
        
        <<< LabelRow("Calendar") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let activity = activity, let calendarName = activity.calendarName {
                row.value = calendarName
            } else {
                calendar = calendars[CalendarSourceOptions.plot.name]?.first { $0.defaultCalendar ?? false }
                row.value = calendar?.name ?? "Default"
            }
        }.onCellSelection({ _, row in
            self.openCalendar()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
        }
        
        
        <<< LabelRow("Category") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if let activity = activity, let category = activity.category {
                row.value = category
            } else {
                row.value = "Uncategorized"
            }
        }.onCellSelection({ _, row in
            self.openLevel(value: row.value ?? "Uncategorized", level: "Category")
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
        }
        
        //        if let _ = activity.activityType {
        //            form.last!
        //            <<< LabelRow("Subcategory") { row in
        //                row.cell.backgroundColor = .secondarySystemGroupedBackground
        //                row.cell.textLabel?.textColor = .label
        //                row.cell.detailTextLabel?.textColor = .secondaryLabel
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
        //                cell.backgroundColor = .secondarySystemGroupedBackground
        //                cell.textLabel?.textColor = .label
        //                cell.detailTextLabel?.textColor = .secondaryLabel
        //                cell.textLabel?.textAlignment = .left
        //            }
        //        }
        
        <<< SwitchRow("showExtras") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.title = "Show Extras"
            if let activity = activity, let showExtras = activity.showExtras {
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
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        <<< LabelRow("Sub-Events") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.cell.textLabel?.textColor = .label
            row.title = row.tag
            if let activity = activity, let scheduleIDs = activity.scheduleIDs, scheduleIDs.isEmpty {
                row.value = "0"
            } else {
                row.value = String(self.activity.scheduleIDs?.count ?? 0)
            }
            row.hidden = "$showExtras == false"
        }.onCellSelection({ _,_ in
            self.openSchedule()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .label
            if let activity = self.activity, let scheduleIDs = activity.scheduleIDs, scheduleIDs.isEmpty {
                row.value = "0"
            } else {
                row.value = String(self.activity.scheduleIDs?.count ?? 0)
            }
        }
        
        <<< LabelRow("Checklists") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.cell.textLabel?.textColor = .label
            row.title = row.tag
            if let activity = activity, let checklistIDs = activity.checklistIDs {
                row.value = String(checklistIDs.count)
            } else {
                row.value = "0"
            }
            row.hidden = "$showExtras == false"
        }.onCellSelection({ _,_ in
            self.openList()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .label
            if let checklistIDs = self.activity.checklistIDs {
                row.value = String(checklistIDs.count)
            } else {
                row.value = "0"
            }
        }
        
        <<< LabelRow("Media") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            row.hidden = "$showExtras == false"
            if let activity = activity, let photos = activity.activityPhotos, let files = activity.activityFiles, photos.isEmpty, files.isEmpty {
                row.value = "0"
            } else {
                row.value = String((self.activity.activityPhotos?.count ?? 0) + (self.activity.activityFiles?.count ?? 0))
            }
        }.onCellSelection({ _,_ in
            self.openMedia()
        }).cellUpdate { cell, row in
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .label
            if let photos = self.activity.activityPhotos, let files = self.activity.activityFiles, photos.isEmpty, files.isEmpty {
                row.value = "0"
            } else {
                row.value = String((self.activity.activityPhotos?.count ?? 0) + (self.activity.activityFiles?.count ?? 0))
            }
        }
        
//        <<< LabelRow("Tags") { row in
//            row.cell.backgroundColor = .secondarySystemGroupedBackground
//            row.cell.textLabel?.textColor = .label
//            row.cell.detailTextLabel?.textColor = .secondaryLabel
//            row.cell.accessoryType = .disclosureIndicator
//            row.cell.selectionStyle = .default
//            row.hidden = "$showExtras == false"
//            row.title = row.tag
//            if let tags = self.activity.tags, !tags.isEmpty {
//                row.value = String(tags.count)
//            } else {
//                row.value = "0"
//            }
//        }.onCellSelection({ _, row in
//            self.openTags()
//        }).cellUpdate { cell, row in
//            cell.accessoryType = .disclosureIndicator
//            cell.backgroundColor = .secondarySystemGroupedBackground
//            cell.detailTextLabel?.textColor = .secondaryLabel
//            cell.textLabel?.textAlignment = .left
//            cell.textLabel?.textColor = .label
//            if let tags = self.activity.tags, !tags.isEmpty {
//                row.value = String(tags.count)
//            } else {
//                row.value = "0"
//            }
//        }
        
        //            <<< TextAreaRow("Notes") {
        //                $0.cell.backgroundColor = .secondarySystemGroupedBackground
        //                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
        //                $0.cell.textView?.textColor = .label
        //                $0.cell.placeholderLabel?.textColor = .secondaryLabel
        //                $0.placeholder = $0.tag
        //                $0.hidden = "$showExtras == false"
        //                if self.active && self.activity.notes != "nothing" && self.activity.notes != nil {
        //                    $0.value = self.activity.notes
        //                }
        //                }.cellUpdate({ (cell, row) in
        //                    cell.backgroundColor = .secondarySystemGroupedBackground
        //                    cell.textView?.backgroundColor = .secondarySystemGroupedBackground
        //                    cell.textView?.textColor = .label
        //                }).onChange() { [unowned self] row in
        //                    self.activity.notes = row.value
        //                }
        
        if delegate == nil && (!active || (activity?.participantsIDs?.contains(Auth.auth().currentUser?.uid ?? "") ?? false)) {
            form.last!
            <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.hidden = "$showExtras == false"
                $0.options = ["Tasks", "Health", "Transactions"]
                if !(activity.showExtras ?? true) {
                    $0.value = "Hidden"
                } else {
                    $0.value = "Tasks"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
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
                                            $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                            $0.title = "Connect Task"
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = .secondarySystemGroupedBackground
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
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Connect Health"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
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
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.title = "Connect Transaction"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
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
                    let item = self!.purchaseList[rowNumber]
                    ContainerFunctions.deleteStuffInside(type: .transaction, ID: item.guid)
                }
            }
            else if row is HealthRow {
                if self!.healthList.indices.contains(rowNumber)  {
                    self!.healthList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    let item = self!.healthList[rowNumber]
                    ContainerFunctions.deleteStuffInside(type: item.type, ID: item.ID)
                }
            }
            else if row is SubtaskRow {
                if self!.taskList.indices.contains(rowNumber) {
                    self!.taskList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    let item = self!.taskList[rowNumber]
                    ContainerFunctions.deleteStuffInside(type: .task, ID: item.activityID ?? "")
                }
            }
        }
    }
}
