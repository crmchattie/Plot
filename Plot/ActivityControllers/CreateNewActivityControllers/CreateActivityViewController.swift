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
    var purchaseList = [Purchase]()
    var purchaseDict = [User: Double]()
    var listList = [Any]()
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
            if activity.purchases != nil {
                for purchase in activity.purchases! {
                    if purchase.name == "nothing" { continue }
                    purchaseList.append(purchase)
                }
            }
            if let grocerylist = activity.grocerylist {
                listList.append(grocerylist)
                grocerylistIndex = listList.count - 1
            }
            if activity.packinglist != nil {
                for packinglist in activity.packinglist! {
                    if packinglist.name == "nothing" { continue }
                    listList.append(packinglist)
                }
            }
            if activity.checklist != nil {
                for checklist in activity.checklist! {
                    if checklist.name == "nothing" { continue }
                    listList.append(checklist)
                }
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
        
        purchaseUsers = self.acceptedParticipant
        
        if let currentUserID = Auth.auth().currentUser?.uid, activity.admin == currentUserID {
            let participantReference = Database.database().reference().child("users").child(currentUserID)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    self.purchaseUsers.append(user)
                    for user in self.purchaseUsers {
                        self.purchaseDict[user] = 0.00
                    }
                    
                    self.decimalRowFunc()
                    self.purchaseBreakdown()
                    self.updateDecimalRow()
                }
            })
        } else {
            for user in self.purchaseUsers {
                self.purchaseDict[user] = 0.00
            }
            
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
        } else {
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
                    $0.value = self.activity.activityType?.capitalized
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
                    print("startdate update")
                    self!.weatherRow()
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
                    print("startdate update")
                    self!.weatherRow()
                }.onExpandInlineRow { [weak self] cell, row, inlineRow in
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
        
        <<< SwitchRow("showExtras") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = "Show Schedule, Lists & Purchases"
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
            }
            
        <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.hidden = "$showExtras == false"
                if #available(iOS 13.0, *) {
                    $0.cell.segmentedControl.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
                } else {
                    // Fallback on earlier versions
                }
                $0.options = ["Schedule", "Lists", "Purchases"]
                $0.value = "Schedule"
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }

        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Schedule",
                               footer: "Add a new point in the schedule") {
                                $0.tag = "schedulefields"
                                $0.hidden = "!$sections == 'Schedule'"
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
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                           header: "Lists",
                           footer: "Add a checklist and/or recipe list") {
                            $0.tag = "listsfields"
                            $0.hidden = "$sections != 'Lists'"
                            $0.addButtonProvider = { section in
                                return ButtonRow(){
                                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    $0.title = "Add New List"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                    }
                            }
                            $0.multivaluedRowToInsertAt = { index in
                                self.listIndex = index
                                self.openList()
                                return ButtonRow() { row in
                                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                row.cell.textLabel?.textAlignment = .left
                                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                row.title = "List"
                                }.onCellSelection({ _,_ in
                                    self.listIndex = index
                                    self.openList()
                                }).cellUpdate { cell, row in
                                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                    cell.textLabel?.textAlignment = .left
                                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                }
                            }
                            
    }
                            for list in listList {
                                if let groceryList = list as? Grocerylist {
                                    var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                                    mvs.insert(ButtonRow() { row in
                                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
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
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            cell.textLabel?.textAlignment = .left
                                        }, at: mvs.count - 1)
                                } else if let checklist = list as? Checklist {
                                    var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                                    mvs.insert(ButtonRow() { row in
                                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        row.cell.textLabel?.textAlignment = .left
                                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        row.title = checklist.name
                                        }.onCellSelection({ cell, row in
                                            self.listIndex = row.indexPath!.row
                                            self.openList()
                                        }).cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            cell.textLabel?.textAlignment = .left
                                        }, at: mvs.count - 1)
                                } else if let packinglist = list as? Packinglist {
                                    var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                                    mvs.insert(ButtonRow() { row in
                                        row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        row.cell.textLabel?.textAlignment = .left
                                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        row.title = packinglist.name
                                        }.onCellSelection({ cell, row in
                                            self.listIndex = row.indexPath!.row
                                            self.openList()
                                        }).cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                            cell.textLabel?.textAlignment = .left
                                        }, at: mvs.count - 1)
                                }
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
                                            footer: "Positive Balance = Owe; Negative Balance = Owed") {
                                                $0.tag = "Balances"
                                                $0.hidden = "$sections != 'Purchases'"
                                }
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
            if !purchaseUsers.contains(key) {
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
        for user in purchaseUsers {
            purchaseDict[user] = 0.00
        }
        guard let currentUser = Auth.auth().currentUser else { return }
        for purchase in purchaseList {
            if let purchaser = purchase.purchaser {
                var costPerPerson: Double = 0.00
                if let purchaseRowCount = purchase.purchaseRowCount {
                    costPerPerson = purchase.cost! / Double(purchaseRowCount)
                } else if let participants = purchase.participantsIDs {
                    costPerPerson = purchase.cost! / Double(participants.count)
                }
                // minus cost from purchaser's balance
                for ID in purchaser {
                    if let user = purchaseUsers.first(where: {$0.id == ID}) {
                        var value = purchaseDict[user] ?? 0.00
                        value -= costPerPerson
                        purchaseDict[user] = value
                    }
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
                        if let ID = user.id, !purchaser.contains(ID) {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                }
            } else {
                let costPerPerson = purchase.cost! / Double(purchase.participantsIDs!.count)
                if purchase.participantsIDs![0] == currentUser.uid {
                    for ID in purchase.participantsIDs!{
                        if let user = purchaseUsers.first(where: {$0.id == ID}) {
                            var value = purchaseDict[user] ?? 0.00
                            value += costPerPerson
                            purchaseDict[user] = value
                        }
                    }
                } else {
                    let ID = purchase.participantsIDs![0]
                    if let user = purchaseUsers.first(where: {$0.id == ID}) {
                        var value = purchaseDict[user] ?? 0.00
                        value -= costPerPerson
                        purchaseDict[user] = value
                    }
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
                    self!.purchaseBreakdown()
                    self!.updateDecimalRow()
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
    
    fileprivate func weatherRow() {
        if let localName = activity.locationName, localName != "locationName", Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval) > Date(), Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval) < Date().addingTimeInterval(1296000) {
            var startDate = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
            if startDate < Date() {
                startDate = Date().addingTimeInterval(3600)
            }
            let endDate = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
            let startDateString = startDate.toString(dateFormat: "YYYY-MM-dd") + "T24:00:00Z"
            let endDateString = endDate.toString(dateFormat: "YYYY-MM-dd") + "T00:00:00Z"
            print("updating weather row")
            if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let localAddress = activity.locationAddress, let latitude = localAddress[locationName]?[0], let longitude = localAddress[locationName]?[1] {
                print("weather row exists")
                print("startDateString \(startDateString)")
                print("endDateString \(endDateString)")
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
                print("weather row exists")
                print("startDateString \(startDateString)")
                print("endDateString \(endDateString)")
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
            if listList.isEmpty {
                activity.checklist = [Checklist]()
                activity.grocerylist = nil
                groupActivityReference.child("checklist").removeValue()
                groupActivityReference.child("grocerylist").removeValue()
            } else {
                var firebaseChecklistList = [[String: AnyObject?]]()
                var checklistList = [Checklist]()
                var firebasePackinglistList = [[String: AnyObject?]]()
                var packinglistList = [Packinglist]()
                var firebaseGrocerylistList = [String: AnyObject?]()
                var grocerylistList: Grocerylist!
                for list in listList {
                    if let checklist = list as? Checklist {
                        checklistList.append(checklist)
                        let firebaseChecklist = checklist.toAnyObject()
                        firebaseChecklistList.append(firebaseChecklist)
                    } else if let packinglist = list as? Packinglist {
                        packinglistList.append(packinglist)
                        let firebasePackinglist = packinglist.toAnyObject()
                        firebasePackinglistList.append(firebasePackinglist)
                    } else if let grocerylist = list as? Grocerylist {
                        grocerylistList = grocerylist
                        firebaseGrocerylistList = grocerylist.toAnyObject()
                    }
                }
                activity.checklist = checklistList
                groupActivityReference.updateChildValues(["checklist": firebaseChecklistList as AnyObject])
                activity.packinglist = packinglistList
                groupActivityReference.updateChildValues(["packinglist": firebasePackinglistList as AnyObject])
                activity.grocerylist = grocerylistList
                groupActivityReference.updateChildValues(["grocerylist": firebaseGrocerylistList as AnyObject])
            }
        }
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
        print("openLocation")
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
                        destination.conversations = self.conversations
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
                            destination.conversations = self.conversations
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
                            destination.conversations = self.conversations
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
        destination.users = purchaseUsers
        destination.filteredUsers = purchaseUsers
        if purchaseList.indices.contains(purchaseIndex) {
            destination.purchase = purchaseList[purchaseIndex]
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openList() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        if listIndex == grocerylistIndex, let grocerylist = listList[listIndex] as? Grocerylist {
            let destination = GrocerylistViewController()
            destination.grocerylist = grocerylist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let checklist = listList[listIndex] as? Checklist {
            let destination = ChecklistViewController()
            destination.checklist = checklist
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let packinglist = listList[listIndex] as? Packinglist {
            let destination = PackinglistViewController()
            destination.packinglist = packinglist
            destination.delegate = self
            if let weather = self.weather {
                destination.weather = weather
            }
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let alertController = UIAlertController(title: "Type of List", message: nil, preferredStyle: .alert)
            let groceryList = UIAlertAction(title: "Grocery List", style: .default) { (action:UIAlertAction) in
                self.grocerylistIndex = self.listIndex
                let destination = GrocerylistViewController()
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }
            let packingList = UIAlertAction(title: "Packing List", style: .default) { (action:UIAlertAction) in
                let destination = PackinglistViewController()
                destination.delegate = self
                if let weather = self.weather {
                    destination.weather = weather
                }

            }
            let checkList = UIAlertAction(title: "Checklist", style: .default) { (action:UIAlertAction) in
                let destination = ChecklistViewController()
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }
            let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
                print("You've pressed cancel")
                if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                    print("listsfields")
                    mvs.remove(at: self.listIndex)
                }
            }
            
            if activity.grocerylist == nil {
                alertController.addAction(groceryList)
//                alertController.addAction(packingList)
                alertController.addAction(checkList)
                alertController.addAction(cancelAlert)
                self.present(alertController, animated: true, completion: nil)
            } else {
                let destination = ChecklistViewController()
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    @objc func createNewActivity() {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if !active || sentActivity {
            alert.addAction(UIAlertAction(title: "Create New Activity", style: .default, handler: { (_) in
                self.createActivity()
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Update Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                self.createActivity()
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                self.duplicateActivity()
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
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
            } else {
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 2)
                    homeTab.changeToIndex(index: 2)
                }
                self.tabBarController?.selectedIndex = 1
                self.navigationController?.backToViewController(viewController: ActivityTypeViewController.self)
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
        
        alert.addAction(UIAlertAction(title: "Share Activity", style: .default, handler: { (_) in
            print("User click Edit button")
            self.share()
        }))

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
    
    func duplicateActivity() {
        
        if let activity = activity, let currentUserID = Auth.auth().currentUser?.uid {
            var newActivityID: String!
            
            newActivityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
            
            let newActivity = activity.copy() as! Activity
            newActivity.activityID = newActivityID
            newActivity.admin = currentUserID
            newActivity.participantsIDs = nil
            newActivity.activityPhotos = nil
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

            if self.conversation == nil {
                self.navigationController?.backToViewController(viewController: ActivityViewController.self)
            } else {
               self.navigationController?.backToViewController(viewController: ChatLogController.self)
            }
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
        print("updating grocery list")
        if self.activity.grocerylist != nil, self.activity.grocerylist?.ingredients != nil, let recipeIngredients = recipe.extendedIngredients {
            var glIngredients = self.activity.grocerylist!.ingredients!
            if let grocerylistServings = activity.grocerylist!.servings!["\(recipe.id)"], grocerylistServings != recipe.servings {
                activity.grocerylist!.servings!["\(recipe.id)"] = recipe.servings
                for recipeIngredient in recipeIngredients {
                    if let index = self.activity.grocerylist?.ingredients!.firstIndex(where: {$0 == recipeIngredient}) {
                        glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil && recipeIngredient.amount != nil  {
                                glIngredients[index].amount! +=  recipeIngredient.amount! - recipeIngredient.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                            }
                            if glIngredients[index].measures?.metric?.amount != nil && recipeIngredient.measures?.metric?.amount! != nil {
                                glIngredients[index].measures!.metric!.amount! +=  recipeIngredient.measures!.metric!.amount! - recipeIngredient.measures!.metric!.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                            }
                            if glIngredients[index].measures?.us?.amount != nil && recipeIngredient.measures?.us?.amount! != nil {
                                glIngredients[index].measures!.us!.amount! +=  recipeIngredient.measures!.us!.amount! - recipeIngredient.measures!.us!.amount! * Double(grocerylistServings) / Double(recipe.servings!)
                            }
                    }
                }
            } else if activity.grocerylist!.recipes!["\(recipe.id)"] != nil && add {
                return
            } else {
                if add {
                    if self.activity.grocerylist!.recipes != nil {
                        self.activity.grocerylist!.recipes!["\(recipe.id)"] = recipe.title
                        self.activity.grocerylist!.servings!["\(recipe.id)"] = recipe.servings
                    } else {
                        self.activity.grocerylist!.recipes = ["\(recipe.id)": recipe.title]
                        self.activity.grocerylist!.servings = ["\(recipe.id)": recipe.servings!]
                    }
                } else {
                    self.activity.grocerylist!.recipes!["\(recipe.id)"] = nil
                    self.activity.grocerylist!.servings!["\(recipe.id)"] = nil
                }
                for recipeIngredient in recipeIngredients {
                    if let index = self.activity.grocerylist?.ingredients!.firstIndex(where: {$0 == recipeIngredient}) {
                        if add {
                            glIngredients[index].recipe![recipe.title] = recipeIngredient.amount ?? 0.0
                            if glIngredients[index].amount != nil {
                                glIngredients[index].amount! += recipeIngredient.amount ?? 0.0
                            }
                            if glIngredients[index].measures?.metric?.amount != nil {
                                glIngredients[index].measures?.metric?.amount! += recipeIngredient.measures?.metric?.amount ?? 0.0
                            }
                            if glIngredients[index].measures?.us?.amount != nil {
                                glIngredients[index].measures?.us?.amount! += recipeIngredient.measures?.us?.amount ?? 0.0
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
                            if glIngredients[index].measures?.metric?.amount != nil {
                                glIngredients[index].measures?.metric?.amount! -= recipeIngredient.measures?.metric?.amount ?? 0.0
                                if glIngredients[index].measures?.metric?.amount! == 0 {
                                    glIngredients.remove(at: index)
                                    continue
                                } else {
                                    glIngredients[index].recipe![recipe.title] = nil
                                }
                            }
                            if glIngredients[index].measures?.us?.amount != nil {
                                glIngredients[index].measures?.us?.amount! -= recipeIngredient.measures?.us?.amount ?? 0.0
                                if glIngredients[index].measures?.us?.amount! == 0 {
                                    glIngredients.remove(at: index)
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
                self.activity.grocerylist = nil
            } else {
                self.activity.grocerylist?.ingredients = glIngredients
            }
            if listList.indices.contains(grocerylistIndex) {
                listList[grocerylistIndex] = self.activity.grocerylist as Any
            }
            print("updated grocery list")
        } else if let recipeIngredients = recipe.extendedIngredients, add {
            let groceryList = Grocerylist(dictionary: ["name" : "Grocery List"] as [String: AnyObject])
            var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
            mvs.insert(ButtonRow() { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.title = groceryList.name
                self.grocerylistIndex = mvs.count - 1
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            
            groceryList.ingredients = recipeIngredients
            for index in 0...groceryList.ingredients!.count - 1 {
                groceryList.ingredients![index].recipe = [recipe.title: groceryList.ingredients![index].amount ?? 0.0]
            }
            groceryList.recipes = ["\(recipe.id)": recipe.title]
            groceryList.servings = ["\(recipe.id)": recipe.servings!]
            
            self.activity.grocerylist? = groceryList
            listList.append(groceryList)
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
                var newLocationName = key
                if newLocationName.contains("/") {
                    newLocationName = newLocationName.replacingOccurrences(of: "/", with: "")
                }
                if newLocationName.contains(".") {
                    newLocationName = newLocationName.replacingOccurrences(of: ".", with: "")
                }
                if newLocationName.contains("#") {
                    newLocationName = newLocationName.replacingOccurrences(of: "#", with: "")
                }
                if newLocationName.contains("$") {
                    newLocationName = newLocationName.replacingOccurrences(of: "$", with: "")
                }
                if newLocationName.contains("[") {
                    newLocationName = newLocationName.replacingOccurrences(of: "[", with: "")
                }
                if newLocationName.contains("]") {
                    newLocationName = newLocationName.replacingOccurrences(of: "]", with: "")
                }
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

extension CreateActivityViewController: UpdateScheduleDelegate {
    func updateSchedule(schedule: Activity) {
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            let scheduleRow = mvs.allRows[scheduleIndex]
            if let _ = schedule.name {
                scheduleRow.baseValue = schedule
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
            } else {
                mvs.remove(at: scheduleIndex)
            }
        }
    }
    func updateIngredients(recipe: Recipe?, recipeID: String?) {
        print("updating Ingredients")
        if let recipe = recipe {
            updateGrocerylist(recipe: recipe, add: true)
        } else if let recipeID = recipeID {
            lookupRecipe(recipeID: Int(recipeID)!, add: true)
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

extension CreateActivityViewController: UpdateChecklistDelegate {
    func updateChecklist(checklist: Checklist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if checklist.name != "CheckListName" {
                listRow.baseValue = checklist
                listRow.title = checklist.name
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex] = checklist
                } else {
                    listList.append(checklist)
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
                    listList[listIndex] = packinglist
                } else {
                    listList.append(packinglist)
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
                    listList[grocerylistIndex] = grocerylist
                } else {
                    listList.append(grocerylist)
                }
                updateLists(type: "lists")
            } else {
                mvs.remove(at: grocerylistIndex)
                activity.grocerylist = nil
            }
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
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?) {
        if let activityID = activityID {
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
               }
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
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
