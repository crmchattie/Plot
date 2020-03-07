//
//  CreateActivityController.swift
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


class CreateActivityViewController: FormViewController {
    
//    var viewModel: ViewModel!
    
    var activity: Activity!
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    var conversations = [Conversation]()
    var conversation: Conversation!
    let avatarOpener = AvatarOpener()
    var locationName : String = "locationName"
    var locationAddress = [String : [Double]]()
    var scheduleList = [Schedule]()
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
    let activityCreatingGroup = DispatchGroup()
    let informationMessageSender = InformationMessageSender()
    
    fileprivate var reminderDate: Date?
    
    fileprivate var active: Bool = false
    
    typealias CompletionHandler = (_ success: Bool) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        
        if activity != nil {
            active = true
            activityID = activity.activityID
            for ID in activity!.participantsIDs! {
               guard let currentUserID = Auth.auth().currentUser?.uid, currentUserID != ID else { continue }
                let newMemberReference = Database.database().reference().child("users").child(ID)
                
                newMemberReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    
                    let user = User(dictionary: dictionary)
                    
                    self.selectedFalconUsers.append(user)
                    self.purchaseDict[user] = 0.00
                    
                    if let inviteesRow: TextRow = self.form.rowBy(tag: "Participants") {
                        self.userNamesString = "\(self.selectedFalconUsers.count + 1) participants"
                        inviteesRow.value = self.userNamesString
                        inviteesRow.updateCell()
                    }
                    
                })
                
            }
            if let localName = activity.locationName, localName != "locationName" {
                locationName = localName
                locationAddress = activity.locationAddress!
            }
            if activity.schedule != nil {
                for schedule in activity.schedule! {
                    let sche = Schedule(dictionary: schedule as? [String : AnyObject])
                    if sche.name == "nothing" { continue }
                    scheduleList.append(sche)
                    guard let localAddress = sche.locationAddress else { continue }
                    for (key, value) in localAddress {
                        locationAddress[key] = value
                    }
                }
            }
            setupRightBarButton(with: "Update")
            if activity.purchases != nil {
                for purchase in activity.purchases! {
                    let purch = Purchase(dictionary: purchase as? [String : AnyObject])
                    if purch.name == "nothing" { continue }
                    purchaseList.append(purch)
                }
                purchaseBreakdown()
            }
            if activity.checklist != nil && activity.checklist!["name"] == nil {
                checklistDict = activity.checklist!
            }
        } else {
            activityID = Database.database().reference().child("user-activities").child(currentUserID).childByAutoId().key ?? ""
            setupRightBarButton(with: "Create")
            if !selectedFalconUsers.isEmpty {
                userNamesString = "\(selectedFalconUsers.count + 1) participants"
            }
        }
        
        initializeForm()
        
//        print(form.values())

    }
    
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.title = "New Activity"
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = []
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
    }
    
    func setupRightBarButton(with title: String) {
        let checkImage = UIImage(named: "checkNav")
        if title == "Create" {
            let checkBarButton = UIBarButtonItem(image: checkImage, style: .plain, target: self, action: #selector(createNewActivity))
            navigationItem.rightBarButtonItem = checkBarButton
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            let chatsImage = UIImage(named: "chatNav")
            let mapsImage = UIImage(named: "mapNav")
            if activity.participantsIDs!.count > 1 && conversation == nil {
                if #available(iOS 11.0, *) {
                    let checkBarButton = UIButton(type: .system)
                    checkBarButton.setImage(checkImage, for: .normal)
                    checkBarButton.addTarget(self, action: #selector(createNewActivity), for: .touchUpInside)
                    
                    let chatBarButton = UIButton(type: .system)
                    chatBarButton.setImage(chatsImage, for: .normal)
                    chatBarButton.addTarget(self, action: #selector(goToChat), for: .touchUpInside)
                    
                    let mapBarButton = UIButton(type: .system)
                    mapBarButton.setImage(mapsImage, for: .normal)
                    mapBarButton.addTarget(self, action: #selector(goToMap), for: .touchUpInside)
                    
                    navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: checkBarButton), UIBarButtonItem(customView: chatBarButton), UIBarButtonItem(customView: mapBarButton)]
                } else {
                    let checkBarButton = UIBarButtonItem(image: checkImage, style: .plain, target: self, action: #selector(createNewActivity))
                    let chatBarButton = UIBarButtonItem(image: chatsImage, style: .plain, target: self, action: #selector(goToChat))
                    let mapBarButton = UIBarButtonItem(image: mapsImage, style: .plain, target: self, action: #selector(goToMap))
                    navigationItem.rightBarButtonItems = [checkBarButton, chatBarButton, mapBarButton]
                }
            } else {
                if #available(iOS 11.0, *) {
                    let checkBarButton = UIButton(type: .system)
                    checkBarButton.setImage(checkImage, for: .normal)
                    checkBarButton.addTarget(self, action: #selector(createNewActivity), for: .touchUpInside)
                    
                    let mapBarButton = UIButton(type: .system)
                    mapBarButton.setImage(mapsImage, for: .normal)
                    mapBarButton.addTarget(self, action: #selector(goToMap), for: .touchUpInside)
                    
                    navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: checkBarButton), UIBarButtonItem(customView: mapBarButton)]
                } else {
                    let checkBarButton = UIBarButtonItem(image: checkImage, style: .plain, target: self, action: #selector(createNewActivity))
                    let mapBarButton = UIBarButtonItem(image: mapsImage, style: .plain, target: self, action: #selector(goToMap))
                    navigationItem.rightBarButtonItems = [checkBarButton, mapBarButton]
                }
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
                    
                    row.title = "Activity Photo"
                    cell.titleLeftMargin = 20.0
                    cell.titleLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
//                    //  Construct the view for the cell
                    cell.view = UIImageView()
                    cell.view!.contentMode = .scaleAspectFill //.scaleAspectFit
                    cell.view!.clipsToBounds = true
                    cell.contentView.addSubview(cell.view!)
                    
                    if self.active && self.activity.activityOriginalPhotoURL != "" && self.activity.activityOriginalPhotoURL != nil {
                        cell.height = { return CGFloat(200) }
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
                    self.navigationItem.title = $0.value
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    $0.cell.textField.becomeFirstResponder()
                }
                }.onChange() { [unowned self] row in
                    if row.value == nil {
                        self.navigationItem.title = "New Activity"
                        self.navigationItem.rightBarButtonItem?.isEnabled = false
                    } else {
                        self.navigationItem.title = row.value
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Activity Type") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityType != "nothing" {
                    $0.value = self.activity.activityType
                    }
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextAreaRow("Description") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.activityDescription != "nothing" {
                    $0.value = self.activity.activityDescription
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                })
            
            <<< TextRow("Location") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.locationName != "locationName" {
                    $0.value = self.activity.locationName
                    }
                }.onCellHighlightChanged { cell, row in
                    if row.isHighlighted {
                        self.openLocationFinder()
                    }
                    cell.cellResignFirstResponder()
                    self.tableView.endEditing(true)
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< TextRow("Participants") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if !self.selectedFalconUsers.isEmpty {
                    $0.value = self.userNamesString
                }
                }.onCellHighlightChanged { cell, row in
                    if row.isHighlighted {
                        self.openParticipantsInviter()
                    }
                    cell.cellResignFirstResponder()
                    self.tableView.endEditing(true)
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< ActionSheetRow<String>("Transportation") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.selectorTitle = "How are you getting there?"
                $0.options = ["None", "Car", "Flight", "Train", "Bus", "Subway", "Bike/Scooter", "Walk"]
                if self.active && self.activity.transportation != "nothing" {
                    $0.value = self.activity.transportation
                }
                }
                .onPresent { from, to in
                    to.popoverPresentationController?.permittedArrowDirections = .up
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor

            }
            
            <<< SwitchRow("All-day") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.title = $0.tag
                if self.active {
                    $0.value = self.activity.allDay
                } else {
                    $0.value = false
                }
                }.onChange { [weak self] row in
                    let startDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    let endDate: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    
                    if row.value ?? false {
                        startDate.dateFormatter?.dateStyle = .medium
                        startDate.dateFormatter?.timeStyle = .none
                        endDate.dateFormatter?.dateStyle = .medium
                        endDate.dateFormatter?.timeStyle = .none
                    }
                    else {
                        startDate.dateFormatter?.dateStyle = .short
                        startDate.dateFormatter?.timeStyle = .short
                        endDate.dateFormatter?.dateStyle = .short
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
            
            <<< DateTimeInlineRow("Starts") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                if self.active {
                    $0.value = Date(timeIntervalSince1970: self.activity!.startDateTime as! TimeInterval)
                    
                    if self.activity.allDay == true {
                        $0.dateFormatter?.dateStyle = .medium
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.dateStyle = .short
                        $0.dateFormatter?.timeStyle = .short
                    }
                    
                    $0.updateCell()
                    
                } else {
                    $0.value = Date().addingTimeInterval(60*60*24)
                }
                self.startDateTime = $0.value
                }
                .onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Ends")
                    if row.value?.compare(endRow.value!) == .orderedDescending {
                        endRow.value = Date(timeInterval: 60*60*24, since: row.value!)
                        endRow.cell!.backgroundColor = .white
                        endRow.updateCell()
                    }
                    self!.startDateTime = row.value
                }
                .onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
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
                if self.active {
                    $0.value = Date(timeIntervalSince1970: self.activity!.endDateTime as! TimeInterval)
                    
                    if self.activity.allDay == true {
                        $0.dateFormatter?.dateStyle = .medium
                        $0.dateFormatter?.timeStyle = .none
                    }
                    else {
                        $0.dateFormatter?.dateStyle = .short
                        $0.dateFormatter?.timeStyle = .short
                    }
                    
                    $0.updateCell()
                    
                } else {
                    $0.value = Date().addingTimeInterval(60*60*25)
                }
                self.endDateTime = $0.value
                }
                .onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowBy(tag: "Starts")
                    if row.value?.compare(startRow.value!) == .orderedAscending {
                        row.cell!.backgroundColor = .red
                    }
                    else{
                        row.cell!.backgroundColor = .white
                    }
                    row.updateCell()
                    self!.endDateTime = row.value
                }
                .onExpandInlineRow { [weak self] cell, row, inlineRow in
                    inlineRow.cellUpdate { cell, dateRow in
                        let allRow: SwitchRow! = self?.form.rowBy(tag: "All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .date
                        }
                        else {
                            cell.datePicker.datePickerMode = .dateAndTime
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
                if self.active {
                    if let value = self.activity.reminder {
                        $0.value = EventAlert(rawValue: value)
                    }
                } else {
                    $0.value = .Never
                }
                $0.options = EventAlert.allValues
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    
            }
            
        
        
            
//            <<< ActionSheetRow<RepeatInterval>("Repeat") {
//                $0.title = $0.tag
//                $0.options = RepeatInterval.allValues
//                $0.value = .Never
//                }
//                .onPresent { from, to in
//                    to.popoverPresentationController?.permittedArrowDirections = .up
//            }
            
            
            <<< TextAreaRow("Notes") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if self.active && self.activity.notes != "nothing" {
                    $0.value = self.activity.notes
                }
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                })
            
            <<< SegmentedRow<String>("sections"){
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.options = ["Schedule", "Checklist", "Purchases"]
                $0.value = "Schedule"
                }
////                .onCellSelection() { cell, row in
////                    if let thisIndexPath = self.tableView?.indexPath(for: row.cell) {
////                        self.tableView?.scrollToRow(at: thisIndexPath, at: .top, animated: false)
////                    }
////                }
                .onCellSelection({_,_  in
                    if let indexPath = self.form.allRows.last?.indexPath {
                        self.tableView?.scrollToRow(at: indexPath, at: .none, animated: true)
                    }
                })
    
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
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                cell.tintColor = FalconPalette.defaultBlue
                                        }
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                        }.onChange() { cell, row in
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
                                            }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            cell.tintColor = FalconPalette.defaultBlue
                                            }
                                            }.cellUpdate { cell, row in
                                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                            }.onChange() { cell, row in
                                                self.updateLists(type: "checklist")
                                        }
                                            , at: mvs.count - 1)
                                        
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
                                    if selectedFalconUsers.count > 0 {
                                        var mvs = form.sectionBy(tag: "Balances")
                                        for user in selectedFalconUsers {
                                            mvs!.insert(DecimalRow(user.name) {
                                                $0.hidden = "$sections != 'Purchases'"
                                                $0.useFormatterDuringInput = true
                                                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                                $0.tag = user.name
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
                                                    
                                            }, at: mvs!.count)
                                        }
//                                        mvs.footer = "Positive Balance = Receipt; Negative Balance = Payment" as? HeaderFooterViewRepresentable
                                        updateDecimalRow()
                                    }
        
    }
    
    func decimalRowFunc() {
        var mvs = form.sectionBy(tag: "Balances")
        for user in selectedFalconUsers {
            if let userName = user.name, let _ : DecimalRow = form.rowBy(tag: "\(userName)") {
                continue
            } else {
                purchaseDict[user] = 0.00
                mvs!.insert(DecimalRow(user.name) {
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

                }, at: mvs!.count)
            }
        }
        for (key, _) in purchaseDict {
            if !selectedFalconUsers.contains(key) {
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
        for user in selectedFalconUsers {
            purchaseDict[user] = 0.00
        }
        guard let currentUser = Auth.auth().currentUser else { return }
        for purchase in purchaseList {
            let costPerPerson = purchase.cost! / Double(purchase.participantsIDs!.count)
            if purchase.participantsIDs![0] == currentUser.uid {
                for ID in purchase.participantsIDs!{
                    if let user = selectedFalconUsers.first(where: {$0.id == ID}) {
                        var value = purchaseDict[user] ?? 0.00
                        value += costPerPerson
                        purchaseDict[user] = value
                    }
                }
            } else {
                let ID = purchase.participantsIDs![0]
                if let user = selectedFalconUsers.first(where: {$0.id == ID}) {
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
    enum RepeatInterval : String, CustomStringConvertible {
        case Never = "Never"
        case Every_Day = "Every Day"
        case Every_Week = "Every Week"
        case Every_2_Weeks = "Every 2 Weeks"
        case Every_Month = "Every Month"
        case Every_Year = "Every Year"
        
        var description : String { return rawValue }
        
        static let allValues = [Never, Every_Day, Every_Week, Every_2_Weeks, Every_Month, Every_Year]
    }
    
    enum EventAlert : String, CustomStringConvertible {
        case Never = "None"
        case At_time_of_event = "At time of event"
        case Five_Minutes = "5 minutes before"
        case Fifteen_Minutes = "15 minutes before"
        case Half_Hour = "30 minutes before"
        case One_Hour = "1 hour before"
        case One_Day = "1 day before"
        case One_Week = "1 week before"

        var description : String { return rawValue }

        static let allValues = [Never, At_time_of_event, Five_Minutes, Fifteen_Minutes, Half_Hour, One_Hour, One_Day, One_Week]
    }
    
    // MARK: - Reminder Frequency
//    enum EventAlert: String {
//        case none = "None"
//        case halfHour = "30 minutes before"
//        case oneHour = "1 hour before"
//        case oneDay = "1 day before"
//        case oneWeek = "1 week before"
//
//        var description : String { return rawValue }
//
//        static let allValues = [none, halfHour, oneHour, oneHour, oneDay, oneWeek]
//
//        var timeInterval: Double {
//            switch self {
//            case .none:
//                return 0
//            case .halfHour:
//                return -1800
//            case .oneHour:
//                return -3600
//            case .oneDay:
//                return -86400
//            case .oneWeek:
//                return -604800
//            }
//        }
//
//        static func fromInterval(_ interval: TimeInterval) -> EventAlert {
//            switch interval {
//            case 1800:
//                return .halfHour
//            case 3600:
//                return .oneHour
//            case 86400:
//                return .oneDay
//            case 604800:
//                return .oneWeek
//            default:
//                return .none
//            }
//        }
//    }
//
//    var reminder: EventAlert {
//        get {
//            if let date = self.reminderDate {
//                let duration = date.seconds(from: startDateTime!)
//                return EventAlert.fromInterval(duration)
//            }
//            return .none
//        }
//        set {
//            reminderDate = startDateTime!.addingTimeInterval(newValue.timeInterval)
//        }
//    }
    
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
            } else if rowType is SplitRow {
                self!.updateLists(type: "checklist")
            }
        }
    }
    
    
    class CurrencyFormatter : NumberFormatter, FormatterProtocol {
        override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, range rangep: UnsafeMutablePointer<NSRange>?) throws {
            guard obj != nil else { return }
            var str = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            if !string.isEmpty, numberStyle == .currency && !string.contains(currencySymbol) {
                // Check if the currency symbol is at the last index
                if let formattedNumber = self.string(from: 1), String(formattedNumber[formattedNumber.index(before: formattedNumber.endIndex)...]) == currencySymbol {
                    // This means the user has deleted the currency symbol. We cut the last number and then add the symbol automatically
                    str = String(str[..<str.index(before: str.endIndex)])
                    
                }
            }
            obj?.pointee = NSNumber(value: (Double(str) ?? 0.0)/Double(pow(10.0, Double(minimumFractionDigits))))
        }
        
        func getNewPosition(forPosition position: UITextPosition, inTextInput textInput: UITextInput, oldValue: String?, newValue: String?) -> UITextPosition {
            return textInput.position(from: position, offset:((newValue?.count ?? 0) - (oldValue?.count ?? 0))) ?? position
        }
    }
    
    fileprivate func openActivityPicture() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        print("Opened picture")
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
            for index in 0...mvs.count - 2 {
                let scheduleRow = mvs.allRows[index]
                scheduleRow.baseValue = scheduleList[index]
                scheduleRow.updateCell()
            }
        }
    }
    
    fileprivate func updateLists(type: String) {
        if type == "schedule" {
            var firebaseScheduleList = [[String: AnyObject?]]()
            if scheduleList.isEmpty {
                firebaseScheduleList = [["name": "nothing" as AnyObject]]
            } else {
                for schedule in scheduleList {
                    let firebaseSchedule = schedule.toAnyObject()
                    firebaseScheduleList.append(firebaseSchedule)
                }
            }
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            groupActivityReference.updateChildValues(["schedule": firebaseScheduleList as AnyObject])
        } else if type == "purchases" {
            var firebasePurchaseList = [[String: AnyObject?]]()
            if purchaseList.isEmpty {
                firebasePurchaseList = [["name": "nothing" as AnyObject]]
            } else {
                for purchase in purchaseList {
                    let firebasePurchase = purchase.toAnyObject()
                    firebasePurchaseList.append(firebasePurchase)
                }
            }
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            groupActivityReference.updateChildValues(["purchases": firebasePurchaseList as AnyObject])
        } else {
            let mvs = (form.values()["checklistfields"] as! [Any?]).compactMap { $0 }
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
            } else {
                checklistDict["name"] = ["name" : false]
            }
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            groupActivityReference.updateChildValues(["checklist": checklistDict as AnyObject])
        }
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        locationAddress[locationName] = nil
        self.navigationController?.pushViewController(destination, animated: true)
        
        //        present(destination, animated: true, completion: nil)
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
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty{
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc fileprivate func openSchedule() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = ScheduleViewController()
        destination.users = selectedFalconUsers
        destination.filteredUsers = selectedFalconUsers
        destination.startDateTime = startDateTime
        destination.endDateTime = endDateTime
        if scheduleList.indices.contains(scheduleIndex) {
            destination.schedule = scheduleList[scheduleIndex]
            if let scheduleLocationAddress = scheduleList[scheduleIndex].locationAddress {
                for (key, _) in scheduleLocationAddress {
                    locationAddress[key] = nil
                }
            }
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
        }
    
    @objc fileprivate func openPurchases() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = PurchasesViewController()
        destination.users = selectedFalconUsers
        destination.filteredUsers = selectedFalconUsers
        if purchaseList.indices.contains(purchaseIndex) {
            destination.purchase = purchaseList[purchaseIndex]
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc func createNewActivity () {
        guard currentReachabilityStatus != .notReachable, let currentUserID = Auth.auth().currentUser?.uid else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        
        let reminderRow: AlertRow<EventAlert> = form.rowBy(tag: "Reminder")!
        
//        var firebaseScheduleList = [[String: AnyObject?]]()
//        var firebasePurchaseList = [[String: AnyObject?]]()
//
//        let mvs = (form.values()["checklistfields"] as! [Any?]).compactMap { $0 }
//        if !mvs.isEmpty {
//            checklistDict = [String: [String : Bool]]()
//            var index = 1
//            for element in mvs {
//                let value = element as! SplitRowValue<Swift.String, Swift.Bool>
//                if let text = value.left, let state = value.right {
//                    checklistDict["checklist_\(index)"] = [text : state]
//                }
//                index += 1
//            }
//        } else {
//            checklistDict["name"] = ["name" : false]
//        }
        
        let valuesDictionary = form.valuesForFirebase()
        let name = valuesDictionary["Activity Name"]
        let activityType = valuesDictionary["Activity Type"]
        let activityDescription = valuesDictionary["Description"]
        let locationName = self.locationName
        let locationAddress = self.locationAddress
        let transportation = valuesDictionary["Transportation"] ?? "nothing"
        let allDay = valuesDictionary["All-day"]
        let startDateTime = valuesDictionary["Starts"]
        let endDateTime = valuesDictionary["Ends"]
        let reminder = reminderRow.value?.rawValue
        let notes = valuesDictionary["Notes"]
//        if scheduleList.isEmpty {
//            firebaseScheduleList = [["name": "nothing" as AnyObject]]
//        } else {
//            for schedule in scheduleList {
//                let firebaseSchedule = schedule.toAnyObject()
//                firebaseScheduleList.append(firebaseSchedule)
//            }
//        }
//        if purchaseList.isEmpty {
//            firebasePurchaseList = [["name": "nothing" as AnyObject]]
//        } else {
//            for purchase in purchaseList {
//                let firebasePurchase = purchase.toAnyObject()
//                firebasePurchaseList.append(firebasePurchase)
//            }
//        }
        let membersIDs = fetchMembersIDs()
        
        if active {
            if Set(activity.participantsIDs!) != Set(membersIDs.0) {
                updateParticipants(membersIDs: membersIDs)
            }
            
            var childValues: [String: AnyObject] = ["activityID": activityID as AnyObject,
                                                    "name": name as AnyObject,
                                                    "activityType": activityType as AnyObject,
                                                    "activityDescription": activityDescription as AnyObject,
                                                    "locationName": locationName as AnyObject,
                                                    "locationAddress": locationAddress as AnyObject,
                                                    "transportation": transportation as AnyObject,
                                                    "activityOriginalPhotoURL": activityAvatarURL as AnyObject,
                                                    "activityThumbnailPhotoURL": thumbnailImage as AnyObject,
                                                    "allDay": allDay as AnyObject,
                                                    "startDateTime": startDateTime as AnyObject,
                                                    "endDateTime": endDateTime as AnyObject,
                                                    "reminder": reminder as AnyObject,
                                                    "notes": notes as AnyObject,
                                                    "participantsIDs": membersIDs.1 as AnyObject,
                ]
            
            if activity.conversationID == nil && selectedFalconUsers.count > 0 {
                let conversationID = createChat(membersIDs: membersIDs, activityID: activityID)
                childValues["conversationID"] = conversationID as AnyObject
            } else if selectedFalconUsers.count > 0 {
                childValues["conversationID"] = activity.conversationID as AnyObject
            }
            
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            showActivityIndicator()
            groupActivityReference.updateChildValues(childValues)
            
//            activityCreatingGroup.enter()
//            uploadAvatar(activityImage: activityImage, reference: groupActivityReference)

            activityCreatingGroup.notify(queue: DispatchQueue.main, execute: {
                self.hideActivityIndicator()
                print("Activity creating finished...")
                
                if self.conversation == nil {
                    self.navigationController?.backToViewController(viewController: ActivityTableViewController.self)
                } else {
                    self.navigationController?.backToViewController(viewController: ChatLogController.self)
                    //                    self.navigationController?.popViewController(animated: true)

                }
            })
            
        } else {
            let groupActivityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            var childValues: [String: AnyObject] = ["activityID": activityID as AnyObject,
                                                    "name": name as AnyObject,
                                                    "activityType": activityType as AnyObject,
                                                    "activityDescription": activityDescription as AnyObject,
                                                    "locationName": locationName as AnyObject,
                                                    "locationAddress": locationAddress as AnyObject,
                                                    "transportation": transportation as AnyObject,
                                                    "activityOriginalPhotoURL": activityAvatarURL as AnyObject,
                                                    "activityThumbnailPhotoURL": thumbnailImage as AnyObject,
                                                    "allDay": allDay as AnyObject,
                                                    "startDateTime": startDateTime as AnyObject,
                                                    "endDateTime": endDateTime as AnyObject,
                                                    "reminder": reminder as AnyObject,
                                                    "notes": notes as AnyObject,
                                                    "participantsIDs": membersIDs.1 as AnyObject,
            ]
            if selectedFalconUsers.count > 0 {
                let conversationID = createChat(membersIDs: membersIDs, activityID: activityID)
                childValues["conversationID"] = conversationID as AnyObject
                informationMessageSender.sendInformatoinMessage(chatID: conversationID, membersIDs: membersIDs.0, text: "New group has been created")
            }

//            activityCreatingGroup.enter()
            activityCreatingGroup.enter()
            activityCreatingGroup.enter()
            createGroupActivityNode(reference: groupActivityReference, childValues: childValues)
//            uploadAvatar(activityImage: activityImage, reference: groupActivityReference)
            connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)

            activityCreatingGroup.notify(queue: DispatchQueue.main, execute: {
                self.hideActivityIndicator()
                print("Activity creating finished...")
                if self.conversation == nil {
                    self.navigationController?.backToViewController(viewController: ActivityTableViewController.self)
                } else {
//                    let nav = self.navigationController!.viewControllers[2] as! UINavigationController
//                    
//                    if nav.topViewController is SelectActivityTableViewController {
//                        let selectActivityTab = nav.topViewController as! SelectActivityTableViewController
//                        selectActivityTab.activities.append(Activity(dictionary: childValues))
//                        
//                    }
                    self.navigationController?.backToViewController(viewController: ChatLogController.self)
//                    self.navigationController?.popViewController(animated: true)
                }
            })
            
            
            
        }
    }
    
    func fetchMembersIDs() -> ([String], [String:AnyObject]) {
        var membersIDs = [String]()
        var membersIDsDictionary = [String:AnyObject]()
        
        guard let currentUserID = Auth.auth().currentUser?.uid else { return (membersIDs, membersIDsDictionary) }
        
        membersIDsDictionary.updateValue(currentUserID as AnyObject, forKey: currentUserID)
        membersIDs.append(currentUserID)
        
        for selectedUser in selectedFalconUsers {
            guard let id = selectedUser.id else { continue }
            membersIDsDictionary.updateValue(id as AnyObject, forKey: id)
            membersIDs.append(id)
        }
        
        return (membersIDs, membersIDsDictionary)
    }
    
    func showActivityIndicator() {
//        ARSLineProgress.show()
        self.showSpinner(onView: self.view)
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
//        ARSLineProgress.showSuccess()
    }
    
    func uploadAvatar(chatImage: UIImage?, reference: DatabaseReference) {
        guard let image = chatImage else { self.activityCreatingGroup.leave(); return }
        let thumbnailImage = createImageThumbnail(image)
        var images = [(image: UIImage, quality: CGFloat, key: String)]()
        let compressedImageData = compressImage(image: image)
        let compressedImage = UIImage(data: compressedImageData)
        images.append((image: compressedImage!, quality: 0.5, key: "chatOriginalPhotoURL"))
        images.append((image: thumbnailImage, quality: 1, key: "chatThumbnailPhotoURL"))
        let photoUpdatingGroup = DispatchGroup()
        for _ in images { photoUpdatingGroup.enter() }
        
        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        
        for imageElement in images {
            uploadAvatarForUserToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
                reference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
                    photoUpdatingGroup.leave()
                })
            }
        }
    }

    func connectMembersToGroupActivity(memberIDs: [String], activityID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child("user-activities").child(memberID).child(activityID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupActivity": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }

    func createGroupActivityNode(reference: DatabaseReference, childValues: [String: Any]) {
        showActivityIndicator()
        let nodeCreationGroup = DispatchGroup()
        nodeCreationGroup.enter()
        nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        reference.updateChildValues(childValues) { (error, reference) in
            nodeCreationGroup.leave()
            
        }
    }
    
    func connectMembersToGroupChat(memberIDs: [String], chatID: String) {
        let connectingMembersGroup = DispatchGroup()
        for _ in memberIDs {
            connectingMembersGroup.enter()
        }
        connectingMembersGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        for memberID in memberIDs {
            let userReference = Database.database().reference().child("user-messages").child(memberID).child(chatID).child(messageMetaDataFirebaseFolder)
            let values:[String : Any] = ["isGroupChat": true]
            userReference.updateChildValues(values, withCompletionBlock: { (error, reference) in
                connectingMembersGroup.leave()
            })
        }
    }
    
    func createGroupChatNode(reference: DatabaseReference, childValues: [String: Any], noImagesToUpload: Bool) {
        showActivityIndicator()
        let nodeCreationGroup = DispatchGroup()
        nodeCreationGroup.enter()
        nodeCreationGroup.notify(queue: DispatchQueue.main, execute: {
            self.activityCreatingGroup.leave()
        })
        reference.updateChildValues(childValues) { (error, reference) in
            nodeCreationGroup.leave()
        }
    }

    func updateParticipants(membersIDs: ([String], [String:AnyObject])) {
        let participantsSet = Set(activity.participantsIDs!)
        let membersSet = Set(membersIDs.0)
        let difference = participantsSet.symmetricDifference(membersSet)
        for member in difference {
            let chatID = activity!.conversationID!
            
            if participantsSet.contains(member) {
                Database.database().reference().child("user-activities").child(member).child(activityID).child(messageMetaDataFirebaseFolder).removeAllObservers()
                Database.database().reference().child("user-activities").child(member).child(activityID).removeValue()
                
                //remove user from chats as well
                
//                Database.database().reference().child("user-messages").child(member).child(chatID).child(messageMetaDataFirebaseFolder).removeAllObservers()
//                Database.database().reference().child("user-messages").child(member).child(chatID).removeValue()
//
//                Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").child(member).removeValue()
                
            }
                Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder).child("chatParticipantsIDs").updateChildValues(membersIDs.1)
            
            activityCreatingGroup.enter()
            activityCreatingGroup.enter()
            connectMembersToGroupChat(memberIDs: membersIDs.0, chatID: chatID)
            connectMembersToGroupActivity(memberIDs: membersIDs.0, activityID: activityID)
        }
    }
    
    var activityAvatarURL = String() {
        didSet {
            let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
            viewRow.cell.view!.showActivityIndicator()
            viewRow.cell.view!.sd_setImage(with: URL(string:activityAvatarURL), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
                viewRow.cell.view!.hideActivityIndicator()
            })
        }
    }
    
    @objc func goToChat() {
        if activity!.conversationID != nil {
            let groupChatDataReference = Database.database().reference().child("groupChats").child(activity!.conversationID!).child(messageMetaDataFirebaseFolder)
            groupChatDataReference.observeSingleEvent(of: .value, with: { (snapshot) in
                guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                dictionary.updateValue(self.activity!.conversationID as AnyObject, forKey: "id")
                
                if let membersIDs = dictionary["chatParticipantsIDs"] as? [String:AnyObject] {
                    dictionary.updateValue(Array(membersIDs.values) as AnyObject, forKey: "chatParticipantsIDs")
                }
                
                let conversation = Conversation(dictionary: dictionary)
                
                if conversation.chatName == nil {
                    let user = self.selectedFalconUsers[0]
                    conversation.chatName = user.name
                    conversation.chatPhotoURL = user.photoURL
                    conversation.chatThumbnailPhotoURL = user.thumbnailPhotoURL
                }
                
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: conversation)
            })
        }
    }
    
    func createChat(membersIDs: ([String], [String:AnyObject]), activityID: String) -> String {
        var conversationID = String()
        if let currentUserID = Auth.auth().currentUser?.uid {
            if conversation != nil {
                if conversation.activities != nil {
                    var activities = conversation.activities!
                    activities.append(activityID)
                    let updatedActivities = ["activities": activities as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    return conversation.chatID!
                } else {
                    let updatedActivities = ["activities": [activityID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    return conversation.chatID!
                }
            }
            for conversation in conversations {
                if conversation.isGroupChat! {
                    let conversationSet = Set(conversation.chatParticipantsIDs!)
                    let membersSet = Set(membersIDs.0)
                    if membersSet == conversationSet {
                        if conversation.activities != nil {
                            var activities = conversation.activities!
                            activities.append(activityID)
                            let updatedActivities = ["activities": activities as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                            return conversation.chatID!
                        } else {
                            let updatedActivities = ["activities": [activityID] as AnyObject]
                            Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                            return conversation.chatID!
                        }
                    }
                }
            }
            
            if let nameRow: TextRow = form.rowBy(tag: "Activity Name"), let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image") {
                let activities: [String] = [activityID]
                let chatImage = viewRow.view?.image
                let chatID = Database.database().reference().child("user-messages").child(currentUserID).childByAutoId().key ?? ""
                let groupChatsReference = Database.database().reference().child("groupChats").child(chatID).child(messageMetaDataFirebaseFolder)
                let childValues: [String: AnyObject] = ["chatID": chatID as AnyObject, "activities": activities as AnyObject, "chatName": nameRow.value as AnyObject, "chatParticipantsIDs": membersIDs.1 as AnyObject, "admin": currentUserID as AnyObject, "adminNeeded": false as AnyObject, "isGroupChat": true as AnyObject]
                
                activityCreatingGroup.enter()
                activityCreatingGroup.enter()
                activityCreatingGroup.enter()
                createGroupChatNode(reference: groupChatsReference, childValues: childValues, noImagesToUpload: chatImage == nil)
                uploadAvatar(chatImage: chatImage, reference: groupChatsReference)
                connectMembersToGroupChat(memberIDs: membersIDs.0, chatID: chatID)
                
                conversationID = chatID
            }
        }
        return conversationID
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
}

extension CreateActivityViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.title = "New Activity"
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
            navigationItem.title = textField.text
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

extension CreateActivityViewController: UpdateLocation {
    func updateLocation(locationName: String, locationAddress: [String : [Double]]) {
        if let locationRow: TextRow = form.rowBy(tag: "Location") {
            if locationName != "locationName" {
                self.locationName = locationName
                for (key, value) in locationAddress {
                    self.locationAddress[key] = value
                }
                setupRightBarButton(with: "Update")
                locationRow.value = locationName
                locationRow.updateCell()
            } else {
                self.locationName = "locationName"
                locationRow.value = nil
                locationRow.updateCell()
            }
        }
    }
}

extension CreateActivityViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: TextRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                self.userNamesString = "\(self.selectedFalconUsers.count + 1) participants"
                inviteesRow.value = self.userNamesString
                inviteesRow.updateCell()
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                inviteesRow.value = nil
                inviteesRow.updateCell()
            }
            decimalRowFunc()
        }
    }
}

extension CreateActivityViewController: UpdateSchedule {
    func updateSchedule(schedule: Schedule) {
        if let mvs = self.form.sectionBy(tag: "schedulefields") as? MultivaluedSection {
            let scheduleRow = mvs.allRows[scheduleIndex]
            if schedule.name != "Mini Activity Name" {
                scheduleRow.baseValue = schedule
                scheduleRow.updateCell()
                if scheduleList.indices.contains(scheduleIndex) {
                    scheduleList[scheduleIndex] = schedule
                } else {
                    scheduleList.append(schedule)
                }
                sortSchedule()
                guard let localAddress = schedule.locationAddress else { return }
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
                setupRightBarButton(with: "Update")
                updateLists(type: "schedule")
            }
            else {
                mvs.remove(at: scheduleIndex)
//                scheduleList.append(schedule)
//                scheduleRow.baseValue = nil
//                scheduleRow.updateCell()
            }
        }
    }
}

extension CreateActivityViewController: UpdatePurchases {
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
