//
//  SchedulerViewController.swift
//  Plot
//
//  Created by Cory McHattie on 12/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

class SchedulerViewController: FormViewController {
    var scheduler: Scheduler!
    var type: CustomType = .sleep
    var customSegmentControl = CustomMultiSegmentedControl()
    var active: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(type.rawValue.capitalized) Schedule"
        setupVariables()
        configureTableView()
        initializeForm()
        updateLength()
    }
    
    fileprivate func setupVariables() {
        if scheduler == nil, let currentUser = Auth.auth().currentUser?.uid {
            active = false
            customSegmentControl = CustomMultiSegmentedControl(buttonImages: nil, buttonTitles: ["M", "T", "W", "T", "F", "S", "S"], selectedIndex: nil)
            let original = Date()
            let rounded = Date(timeIntervalSinceReferenceDate:
            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
            let timezone = TimeZone.current
            let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
            let date = rounded.addingTimeInterval(seconds)
            if type == .sleep {
                let ID = Database.database().reference().child(userSleepEntity).child(currentUser).childByAutoId().key ?? ""
                var dateComp = DateComponents()
                dateComp.hour = 23
                dateComp.minute = 0
                dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let startTime = Calendar.current.date(from: dateComp)
                dateComp.hour = 7
                dateComp.minute = 0
                dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let endTime = Calendar.current.date(from: dateComp)
                scheduler = Scheduler(id: ID, name: nil, activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime, schedulerDate: date, lastModifiedDate: date, createdDate: date)
            } else if type == .work {
                let ID = Database.database().reference().child(userWorkEntity).child(currentUser).childByAutoId().key ?? ""
                var dateComp = DateComponents()
                dateComp.hour = 9
                dateComp.minute = 0
                dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let startTime = Calendar.current.date(from: dateComp)
                dateComp.hour = 17
                dateComp.minute = 0
                dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                let endTime = Calendar.current.date(from: dateComp)
                scheduler = Scheduler(id: ID, name: nil, activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime, schedulerDate: date, lastModifiedDate: date, createdDate: date)
            }
        } else {
            let selectedIndex: [Int] = scheduler!.activeDays?.map({$0.integer}) ?? []
            customSegmentControl = CustomMultiSegmentedControl(buttonImages: nil, buttonTitles: ["M", "T", "W", "T", "F", "S", "S"], selectedIndex: selectedIndex)
        }
    }
    
    fileprivate func configureTableView() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        definesPresentationContext = true
        
        customSegmentControl.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmentControl.delegate = self
                
        view.addSubview(customSegmentControl)
        view.addSubview(tableView)
        
        customSegmentControl.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 20, left: 0, bottom: 0, right: 0))
        tableView.anchor(top: customSegmentControl.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let currentUser = Auth.auth().currentUser?.uid {
            self.showActivityIndicator()
            if type == .sleep {
                let createSleep = SleepActions(sleep: scheduler, active: active, currentUser: currentUser)
                createSleep.createNewSleep()
            } else if type == .work {
                let createWork = WorkActions(work: scheduler, active: active, currentUser: currentUser)
                createWork.createNewWork()
            }
            self.hideActivityIndicator()
            
            if active {
                self.navigationController?.popViewController(animated: true)
            } else {
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 2)
                    homeTab.changeToIndex(index: 2)
                }
                self.tabBarController?.selectedIndex = 1
                if #available(iOS 13.0, *) {
                    self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Length") {
                $0.cell.isUserInteractionEnabled = false
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< DateTimeInlineRow("\(type.categoryText)") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .none
                $0.dateFormatter?.timeStyle = .short
                $0.value = self.scheduler.startTime
            }.onChange { [weak self] row in
                self!.updateLength()
                self!.scheduler.startTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .time
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
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
        
            <<< DateTimeInlineRow("\(type.subcategoryText)") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                $0.title
                    = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .none
                $0.dateFormatter?.timeStyle = .short
                $0.value = self.scheduler.endTime
            }.onChange { [weak self] row in
                self!.updateLength()
                self!.scheduler.endTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .time
                    cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
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
        
    }
    
    fileprivate func updateLength() {
        if let lengthRow : TextRow = form.rowBy(tag: "Length"), let startRow : DateTimeInlineRow = form.rowBy(tag: "\(type.categoryText)"), let startValue = startRow.value, let endRow : DateTimeInlineRow = form.rowBy(tag: "\(type.subcategoryText)"), let endValue = endRow.value {
            var length = Calendar.current.dateComponents([.second], from: startValue, to: endValue).second ?? 0
            if length < 0 {
                length += 60*60*24
            }
            let hour = length / 3600
            let minutes = (length % 3600) / 60
            if minutes > 0 && hour > 0 {
                if hour == 1 {
                    lengthRow.value = "\(hour) hour \(minutes) minutes"
                } else {
                    lengthRow.value = "\(hour) hours \(minutes) minutes"
                }
            } else if hour > 0 {
                if hour == 1 {
                    lengthRow.value = "\(hour) hour"
                } else {
                    lengthRow.value = "\(hour) hours"
                }
            } else {
                lengthRow.value = "\(minutes) minutes"
            }
            lengthRow.updateCell()
            scheduler.length = length
        }
    }
    
}

extension SchedulerViewController: CustomMultiSegmentedControlDelegate {
    func changeToIndex(indexes:[Int]) {
        scheduler.activeDays = getDaysOfWeek(integers: indexes)
    }
}

