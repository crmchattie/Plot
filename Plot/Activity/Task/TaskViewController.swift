//
//  TaskViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/2/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
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
import HealthKit

class TaskViewController: FormViewController {
    var activity: Activity!
    var activityOld: Activity!
    var invitation: Invitation?
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
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
    lazy var activities: [Activity] = networkController.activityService.activities
    lazy var lists: [String: [ListType]] = networkController.activityService.lists
    lazy var conversations: [Conversation] = networkController.conversationService.conversations
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var purchaseUsers = [User]()
    var userInvitationStatus: [String: Status] = [:]
    var conversation: Conversation!
    let avatarOpener = AvatarOpener()
    var subtaskList = [Activity]()
    var container: Container!
    var purchaseList = [Transaction]()
    var purchaseDict = [User: Double]()
    var listList = [ListContainer]()
    var healthList = [HealthContainer]()
    var purchaseIndex: Int = 0
    var listIndex: Int = 0
    var healthIndex: Int = 0
    var grocerylistIndex: Int = -1
    var userNames : [String] = []
    var userNamesString: String = ""
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
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Task Image")!
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
            title = "Task"
            active = true
            activityOld = activity.copy() as? Activity
            if activity.activityID != nil {
                activityID = activity.activityID!
                print(activityID)
            }
            if activity.admin == nil, let currentUserID = Auth.auth().currentUser?.uid {
                activity.admin = currentUserID
            }
            setupLists()
            resetBadgeForSelf()
        } else {
            title = "New Task"
            if let currentUserID = Auth.auth().currentUser?.uid {
                //create new activityID for auto updating items (schedule, purchases, checklist)
                let listDefault = lists[ListOptions.plot.name]?.first { $0.name == "Default"}
                activityID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
                activity = Activity(activityID: activityID, admin: currentUserID, listID: listDefault?.id ?? "", listName: listDefault?.name ?? "", listColor: listDefault?.color ?? "", listSource: listDefault?.source ?? "", isTask: true, isCompleted: false)
            }
        }
        
        setupRightBarButton()
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
            if row.value == nil && self.active {
                let reference = Database.database().reference().child(activitiesEntity).child(self.activityID).child(messageMetaDataFirebaseFolder).child("activityDescription")
                reference.removeValue()
            }
        }
        
        <<< CheckRow("Completed") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.tintColor = FalconPalette.defaultBlue
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.cell.accessoryType = .checkmark
            $0.title = $0.tag
            $0.value = activity.isCompleted ?? false
            if $0.value ?? false {
                $0.cell.tintAdjustmentMode = .automatic
            } else {
                $0.cell.tintAdjustmentMode = .dimmed
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.tintColor = FalconPalette.defaultBlue
            cell.accessoryType = .checkmark
            if row.value == false {
                cell.tintAdjustmentMode = .dimmed
            } else {
                cell.tintAdjustmentMode = .automatic
            }
        }.onChange { row in
            self.activity.isCompleted = row.value
            if row.value ?? false, let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                row.cell.tintAdjustmentMode = .automatic
                let original = Date()
                let updateDate = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                completedRow.value = updateDate
                completedRow.updateCell()
                completedRow.hidden = false
                completedRow.evaluateHidden()
                self.activity.completedDate = updateDate
            } else if let completedRow: DateTimeInlineRow = self.form.rowBy(tag: "Completed On") {
                row.cell.tintAdjustmentMode = .dimmed
                completedRow.value = nil
                completedRow.updateCell()
                completedRow.hidden = true
                completedRow.evaluateHidden()
                self.activity.completedDate = nil
            }
        }
        
        <<< DateTimeInlineRow("Completed On") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.minuteInterval = 5
            $0.dateFormatter?.dateStyle = .medium
            $0.dateFormatter?.timeStyle = .short
            if self.active, let date = activity.completedDate {
                $0.value = date
                $0.updateCell()
            } else {
                $0.hidden = true
            }
        }.onChange { [weak self] row in
            self?.activity.completedDate = row.value
        }.onExpandInlineRow { cell, row, inlineRow in
            inlineRow.cellUpdate { (cell, row) in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
                if #available(iOS 13.4, *) {
                    cell.datePicker.preferredDatePickerStyle = .wheels
                }
                else {
                    cell.datePicker.datePickerMode = .dateAndTime
                }
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }.onCollapseInlineRow { cell, _, _ in
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
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
        
        <<< SwitchRow("Start Date") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if self.active, let activity = activity, let startDateTime = activity.startDateTimeComponents {
                $0.value = true
                let calendar = Calendar.current
                $0.cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getMonthAndDateAndYear()
            } else {
                $0.value = false
            }
        }.onChange { [weak self] row in
            if let value = row.value, let startDate: DatePickerRow = self?.form.rowBy(tag: "StartDate") {
                if value, let startTime = self?.form.rowBy(tag: "StartTime") {
                    if let activity = self?.activity, let startDateTime = activity.startDateTimeComponents {
                        let calendar = Calendar.current
                        row.cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getMonthAndDateAndYear()
                        startDate.value = calendar.date(from: startDateTime)
                    } else {
                        let calendar = Calendar.current
                        let startDateTime = Date()
                        startDate.value = startDateTime
                        row.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()
                        self?.activity.startDateTimeComponents = calendar.dateComponents([.year, .month, .day], from: startDateTime)

                    }
                    startTime.hidden = true
                    startTime.evaluateHidden()
                } else if let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Start Time") {
                    row.cell.detailTextLabel?.text = nil
                    startDateSwitchRow.value = false
                    startDateSwitchRow.updateCell()
                    startDateSwitchRow.cell.detailTextLabel?.text = nil
                    self?.activity.startDateTimeComponents = nil
                }
                let condition: Condition = value ? false : true
                row.disabled = condition
                startDate.hidden = condition
                startDate.evaluateHidden()
                if self!.active {
                    self?.updateRepeatReminder()
                }
            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let startDate = self?.form.rowBy(tag: "StartDate"), let startTime = self?.form.rowBy(tag: "StartTime") {
                    startDate.hidden = startDate.isHidden ? false : true
                    startDate.evaluateHidden()
                    if !startDate.isHidden {
                        startTime.hidden = true
                        startTime.evaluateHidden()
                    }
                }
            }
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            if let activity = self.activity, let startDateTime = activity.startDateTimeComponents {
                let calendar = Calendar.current
                cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getMonthAndDateAndYear()
            }
        }
        
        <<< DatePickerRow("StartDate") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.hidden = true
            $0.minuteInterval = 5
            if #available(iOS 13.4, *) {
                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            }
            else {
                $0.cell.datePicker.datePickerMode = .date
            }
            if self.active, let activity = activity, let startDateTime = activity.startDateTimeComponents {
                let calendar = Calendar.current
                $0.value = calendar.date(from: startDateTime)
                $0.updateCell()
            }
        }.onChange { [weak self] row in
            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Start Date") {
                let calendar = Calendar.current
                self?.activity.startDateTimeComponents = calendar.dateComponents([.year, .month, .day], from: value)
                switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                
            }
            if self!.active {
                self?.updateRepeatReminder()
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        
        <<< SwitchRow("Start Time") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if self.active, let activity = activity, let startDateTime = activity.startDateTimeComponents {
                $0.value = true
                let calendar = Calendar.current
                $0.cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getTimeString()
            } else {
                $0.value = false
            }
        }.onChange { [weak self] row in
            if let value = row.value, let startTime: TimePickerRow = self?.form.rowBy(tag: "StartTime") {
                if value, let startDateDateRow = self?.form.rowBy(tag: "StartDate"), let startDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Start Date") {
                    startDateSwitchRow.value = value
                    startDateSwitchRow.updateCell()
                    if let activity = self?.activity, let startDateTime = activity.startDateTimeComponents, let _ = startDateTime.hour, let _ = startDateTime.minute {
                        let calendar = Calendar.current
                        row.cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getTimeString()
                        startDateSwitchRow.cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getMonthAndDateAndYear()
                        startTime.value = calendar.date(from: startDateTime)
                    } else {
                        let calendar = Calendar.current
                        let original = Date()
                        let startDateTime = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        startTime.value = startDateTime
                        row.cell.detailTextLabel?.text = startDateTime.getTimeString()
                        startDateSwitchRow.cell.detailTextLabel?.text = startDateTime.getMonthAndDateAndYear()
                        self?.activity.startDateTimeComponents = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: startDateTime)

                    }
                    startDateDateRow.hidden = true
                    startDateDateRow.evaluateHidden()
                } else {
                    row.cell.detailTextLabel?.text = nil
                    self?.activity.startDateTimeComponents?.hour = nil
                    self?.activity.startDateTimeComponents?.minute = nil
                }
                let condition: Condition = value ? false : true
                row.disabled = condition
                startTime.hidden = condition
                startTime.evaluateHidden()
                if self!.active {
                    self?.updateRepeatReminder()
                }
            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let startTime = self?.form.rowBy(tag: "StartTime"), let startDate = self?.form.rowBy(tag: "StartDate") {
                    startTime.hidden = startTime.isHidden ? false : true
                    startTime.evaluateHidden()
                    if !startTime.isHidden {
                        startDate.hidden = true
                        startDate.evaluateHidden()
                    }
                }
            }
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            if let activity = self.activity, let startDateTime = activity.startDateTimeComponents, let _ = startDateTime.hour, let _ = startDateTime.minute {
                let calendar = Calendar.current
                cell.detailTextLabel?.text = calendar.date(from: startDateTime)?.getTimeString()
            }
        }
        
        <<< TimePickerRow("StartTime") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.hidden = true
            $0.minuteInterval = 5
            if #available(iOS 13.4, *) {
                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            }
            else {
                $0.cell.datePicker.datePickerMode = .time
            }
            if self.active, let activity = activity, let startDateTime = activity.startDateTimeComponents {
                let calendar = Calendar.current
                $0.value = calendar.date(from: startDateTime)
                $0.updateCell()
            }
        }.onChange { [weak self] row in
            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Start Time") {
                let calendar = Calendar.current
                self?.activity.startDateTimeComponents = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: value)
                switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                
            }
            if self!.active {
                self?.updateRepeatReminder()
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }

        <<< SwitchRow("Deadline Date") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if self.active, let activity = activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                $0.value = true
                let calendar = Calendar.current
                $0.cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getMonthAndDateAndYear()
            } else {
                $0.value = false
            }
        }.onChange { [weak self] row in
            if let value = row.value, let deadlineDate: DatePickerRow = self?.form.rowBy(tag: "DeadlineDate") {
                if value, let deadlineTime = self?.form.rowBy(tag: "DeadlineTime") {
                    if let activity = self?.activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                        let calendar = Calendar.current
                        row.cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getMonthAndDateAndYear()
                        deadlineDate.value = calendar.date(from: deadlineDateTime)
                    } else {
                        let calendar = Calendar.current
                        let deadlineDateTime = Date()
                        deadlineDate.value = deadlineDateTime
                        row.cell.detailTextLabel?.text = deadlineDateTime.getMonthAndDateAndYear()
                        self?.activity.deadlineDateTimeComponents = calendar.dateComponents([.year, .month, .day], from: deadlineDateTime)

                    }
                    deadlineTime.hidden = true
                    deadlineTime.evaluateHidden()
                } else if let deadlineDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Deadline Time") {
                    row.cell.detailTextLabel?.text = nil
                    deadlineDateSwitchRow.value = false
                    deadlineDateSwitchRow.updateCell()
                    deadlineDateSwitchRow.cell.detailTextLabel?.text = nil
                    self?.activity.deadlineDateTimeComponents = nil
                }
                let condition: Condition = value ? false : true
                row.disabled = condition
                deadlineDate.hidden = condition
                deadlineDate.evaluateHidden()
            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let deadlineDate = self?.form.rowBy(tag: "DeadlineDate"), let deadlineTime = self?.form.rowBy(tag: "DeadlineTime") {
                    deadlineDate.hidden = deadlineDate.isHidden ? false : true
                    deadlineDate.evaluateHidden()
                    if !deadlineDate.isHidden {
                        deadlineTime.hidden = true
                        deadlineTime.evaluateHidden()
                    }
                }
            }
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            if let activity = self.activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                let calendar = Calendar.current
                cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getMonthAndDateAndYear()
            }
        }
        
        <<< DatePickerRow("DeadlineDate") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.hidden = true
            $0.minuteInterval = 5
            if #available(iOS 13.4, *) {
                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            }
            else {
                $0.cell.datePicker.datePickerMode = .date
            }
            if self.active, let activity = activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                let calendar = Calendar.current
                $0.value = calendar.date(from: deadlineDateTime)
                $0.updateCell()
            }
        }.onChange { [weak self] row in
            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Deadline Date") {
                let calendar = Calendar.current
                self?.activity.deadlineDateTimeComponents = calendar.dateComponents([.year, .month, .day], from: value)
                switchDateRow.cell.detailTextLabel?.text = value.getMonthAndDateAndYear()
                
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        
        <<< SwitchRow("Deadline Time") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            if self.active, let activity = activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                $0.value = true
                let calendar = Calendar.current
                $0.cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getTimeString()
            } else {
                $0.value = false
            }
        }.onChange { [weak self] row in
            if let value = row.value, let deadlineTime: TimePickerRow = self?.form.rowBy(tag: "DeadlineTime") {
                if value, let deadlineDateDateRow = self?.form.rowBy(tag: "DeadlineDate"), let deadlineDateSwitchRow: SwitchRow = self?.form.rowBy(tag: "Deadline Date") {
                    deadlineDateSwitchRow.value = value
                    deadlineDateSwitchRow.updateCell()
                    if let activity = self?.activity, let deadlineDateTime = activity.deadlineDateTimeComponents, let _ = deadlineDateTime.hour, let _ = deadlineDateTime.minute {
                        let calendar = Calendar.current
                        row.cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getTimeString()
                        deadlineDateSwitchRow.cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getMonthAndDateAndYear()
                        deadlineTime.value = calendar.date(from: deadlineDateTime)
                    } else {
                        let calendar = Calendar.current
                        let original = Date()
                        let deadlineDateTime = Date(timeIntervalSinceReferenceDate:
                                            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        deadlineTime.value = deadlineDateTime
                        row.cell.detailTextLabel?.text = deadlineDateTime.getTimeString()
                        deadlineDateSwitchRow.cell.detailTextLabel?.text = deadlineDateTime.getMonthAndDateAndYear()
                        self?.activity.deadlineDateTimeComponents = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: deadlineDateTime)

                    }
                    deadlineDateDateRow.hidden = true
                    deadlineDateDateRow.evaluateHidden()
                } else {
                    row.cell.detailTextLabel?.text = nil
                    self?.activity.deadlineDateTimeComponents?.hour = nil
                    self?.activity.deadlineDateTimeComponents?.minute = nil
                }
                let condition: Condition = value ? false : true
                row.disabled = condition
                deadlineTime.hidden = condition
                deadlineTime.evaluateHidden()
            }
        }.onCellSelection({ [weak self] _, row in
            if row.value ?? false {
                if let deadlineTime = self?.form.rowBy(tag: "DeadlineTime"), let deadlineDate = self?.form.rowBy(tag: "DeadlineDate") {
                    deadlineTime.hidden = deadlineTime.isHidden ? false : true
                    deadlineTime.evaluateHidden()
                    if !deadlineTime.isHidden {
                        deadlineDate.hidden = true
                        deadlineDate.evaluateHidden()
                    }
                }
            }
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            if let activity = self.activity, let deadlineDateTime = activity.deadlineDateTimeComponents, let _ = deadlineDateTime.hour, let _ = deadlineDateTime.minute {
                let calendar = Calendar.current
                cell.detailTextLabel?.text = calendar.date(from: deadlineDateTime)?.getTimeString()
            }
        }
        
        <<< TimePickerRow("DeadlineTime") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.cell.tintColor = ThemeManager.currentTheme().cellBackgroundColor
            $0.hidden = true
            $0.minuteInterval = 5
            if #available(iOS 13.4, *) {
                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            }
            else {
                $0.cell.datePicker.datePickerMode = .time
            }
            if self.active, let activity = activity, let deadlineDateTime = activity.deadlineDateTimeComponents {
                let calendar = Calendar.current
                $0.value = calendar.date(from: deadlineDateTime)
                $0.updateCell()
            }
        }.onChange { [weak self] row in
            if let value = row.value, let switchDateRow: SwitchRow = self?.form.rowBy(tag: "Deadline Time") {
                let calendar = Calendar.current
                self?.activity.deadlineDateTimeComponents = calendar.dateComponents([.hour, .minute, .day, .month, .year], from: value)
                switchDateRow.cell.detailTextLabel?.text = value.getTimeString()
                
            }
        }.cellUpdate { cell, row in
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
        
        <<< LabelRow("List") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            row.cell.accessoryType = .disclosureIndicator
            row.cell.selectionStyle = .default
            row.title = row.tag
            if self.active && self.activity.listName != nil {
                row.value = self.activity.listName
            } else {
                row.value = "Default"
            }
        }.onCellSelection({ _, row in
            self.openTaskList()
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
        
        <<< ButtonRow("Sub-Tasks") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textAlignment = .left
            row.cell.accessoryType = .disclosureIndicator
            row.title = row.tag
            row.hidden = "$showExtras == false"
            if self.activity.subtaskIDs != nil {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            } else {
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        }.onCellSelection({ _,_ in
            self.openSubtasks()
        }).cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textAlignment = .left
            if let _ = self.activity.subtaskIDs {
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
        
        if delegate == nil {
            form.last!
            <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.hidden = "$showExtras == false"
                if #available(iOS 13.0, *) {
                    $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                }
                $0.options = ["Health", "Transactions"]
                if !(activity.showExtras ?? true) {
                    $0.value = "Hidden"
                } else {
                    $0.value = "Health"
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            }.onChange({ _ in
                self.sectionChanged = true
            })
            
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
        let rowType = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if rowType is PurchaseRow {
                if self!.purchaseList.indices.contains(self!.purchaseIndex) {
                    self!.purchaseList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                    //                    self!.purchaseBreakdown()
                }
            }
            else if rowType is HealthRow {
                if self!.healthList.indices.contains(self!.healthIndex) {
                    self!.healthList.remove(at: rowNumber)
                    self!.updateLists(type: "container")
                }
            }
        }
    }
}
