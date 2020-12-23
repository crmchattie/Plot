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
import CodableFirebase

class SchedulerViewController: FormViewController {
    var scheduler: Scheduler!
    var type: CustomType = .sleep
    var active: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(type.rawValue.capitalized) Schedule"

        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        activityIndicatorView.startAnimating()
        
        setupVariables()
        configureTableView()
    }
    
    fileprivate func setupVariables() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ref = Database.database().reference()
            if type == .sleep {
                group.enter()
                ref.child(userSleepEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let sleepIDs = snapshot.value as? [String: AnyObject] {
                        for (sleepID, _) in sleepIDs {
                            ref.child(sleepEntity).child(sleepID).observeSingleEvent(of: .value, with: { sleepSnapshot in
                                if sleepSnapshot.exists(), let sleepSnapshotValue = sleepSnapshot.value {
                                    if let sleep = try? FirebaseDecoder().decode(Scheduler.self, from: sleepSnapshotValue) {
                                        self.scheduler = sleep
                                    }
                                }
                                group.leave()
                            })
                        }
                    } else {
                        self.active = false
                        let original = Date()
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        let timezone = TimeZone.current
                        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                        let date = rounded.addingTimeInterval(seconds)
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
                        self.scheduler = Scheduler(id: ID, name: nil, dailyTimes: [DailyTimes(activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime)], schedulerDate: date, lastModifiedDate: date, createdDate: date)
                        group.leave()
                    }
                })
            } else if type == .work {
                group.enter()
                ref.child(userWorkEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let workIDs = snapshot.value as? [String: AnyObject] {
                        for (workID, _) in workIDs {
                            ref.child(workEntity).child(workID).observeSingleEvent(of: .value, with: { workSnapshot in
                                if workSnapshot.exists(), let workSnapshotValue = workSnapshot.value {
                                    if let work = try? FirebaseDecoder().decode(Scheduler.self, from: workSnapshotValue) {
                                        self.scheduler = work
                                    }
                                }
                                group.leave()
                            })
                        }
                    } else {
                        self.active = false
                        let original = Date()
                        let rounded = Date(timeIntervalSinceReferenceDate:
                        (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                        let timezone = TimeZone.current
                        let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
                        let date = rounded.addingTimeInterval(seconds)
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
                        self.scheduler = Scheduler(id: ID, name: nil, dailyTimes: [DailyTimes(activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime)], schedulerDate: date, lastModifiedDate: date, createdDate: date)
                        group.leave()
                    }
                })
            }
            
            group.notify(queue: .main) {
                activityIndicatorView.stopAnimating()
                self.initializeForm()
            }
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
            
//            let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
//            if nav.topViewController is MasterActivityContainerController {
//                let homeTab = nav.topViewController as! MasterActivityContainerController
//                homeTab.customSegmented.setIndex(index: 2)
//                homeTab.changeToIndex(index: 2)
//            }
            self.tabBarController?.selectedIndex = 1
            if #available(iOS 13.0, *) {
                self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
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
        if let scheduler = scheduler, scheduler.dailyTimes != nil {
            let dailyTimes = scheduler.dailyTimes!
            for index in 0...dailyTimes.count - 1 {
                form +++
                    Section()
                    <<< ActiveDaysRow("\(index)") {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.delegate = self
                        $0.value = dailyTimes[index].activeDays ?? []
                    }
                    
                    <<< TextRow("Length\(index)") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.title = "Length"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    
                    <<< DateTimeInlineRow("\(type.categoryText)\(index)") {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.title = "\(type.categoryText)"
                        $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        $0.minuteInterval = 5
                        $0.dateFormatter?.dateStyle = .none
                        $0.dateFormatter?.timeStyle = .short
                        $0.value = dailyTimes[index].startTime
                    }.onChange { [weak self] row in
                        self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                        self!.scheduler.dailyTimes![index].startTime = row.value
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
                
                    <<< DateTimeInlineRow("\(type.subcategoryText)\(index)") {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        $0.title = "\(type.subcategoryText)"
                        $0.minuteInterval = 5
                        $0.dateFormatter?.dateStyle = .none
                        $0.dateFormatter?.timeStyle = .short
                        $0.value = dailyTimes[index].endTime
                    }.onChange { [weak self] row in
                        self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                        self!.scheduler.dailyTimes![index].endTime = row.value
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
                
                <<< ButtonRow("Add Additional Schedule") { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.textLabel?.textAlignment = .center
                    row.cell.accessoryType = .none
                    row.title = row.tag
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    }.onCellSelection({ _,_ in
                        self.addSection()
                    })
                
                self.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self.type.categoryText)\(index)", endRowTag: "\(self.type.subcategoryText)\(index)", index: index)
            }
        }
    }
    
    fileprivate func addSection() {
        if scheduler.dailyTimes != nil, scheduler.dailyTimes!.count < 7 {
            var dateComp = DateComponents()
            dateComp.hour = 9
            dateComp.minute = 0
            dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            let startTime = Calendar.current.date(from: dateComp)
            dateComp.hour = 17
            dateComp.minute = 0
            dateComp.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            let endTime = Calendar.current.date(from: dateComp)
            
            let dailyTime = DailyTimes(activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime)
            scheduler.dailyTimes!.append(dailyTime)
            let index = scheduler.dailyTimes!.count - 1
            
            var section = self.form.allSections[0]
            if let buttonRow: ButtonRow = self.form.rowBy(tag: "Add Additional Schedule"), let buttonRowIndex = buttonRow.indexPath?.item {
                section.insert(DateTimeInlineRow("\(type.subcategoryText)\(index)") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    $0.title = "\(type.subcategoryText)"
                    $0.minuteInterval = 5
                    $0.dateFormatter?.dateStyle = .none
                    $0.dateFormatter?.timeStyle = .short
                    $0.value = scheduler.dailyTimes![index].endTime
                }.onChange { [weak self] row in
                    self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                    self!.scheduler.dailyTimes![index].endTime = row.value
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
                }, at: buttonRowIndex)
                
                section.insert(DateTimeInlineRow("\(type.categoryText)\(index)") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "\(type.categoryText)"
                    $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    $0.minuteInterval = 5
                    $0.dateFormatter?.dateStyle = .none
                    $0.dateFormatter?.timeStyle = .short
                    $0.value = scheduler.dailyTimes![index].startTime
                }.onChange { [weak self] row in
                    self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                    self!.scheduler.dailyTimes![index].startTime = row.value
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
                }, at: buttonRowIndex)
                
                section.insert(TextRow("Length\(index)") {
                    $0.cell.isUserInteractionEnabled = false
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.title = "Length"
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }, at: buttonRowIndex)
                
                section.insert(ActiveDaysRow("\(index)") {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.delegate = self
                    $0.value = scheduler.dailyTimes![index].activeDays ?? []
                }, at: buttonRowIndex)
                
                self.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self.type.categoryText)\(index)", endRowTag: "\(self.type.subcategoryText)\(index)", index: index)
            }
        }
    }
    
    fileprivate func updateLength(lengthRowTag: String, startRowTag: String, endRowTag: String, index: Int) {
        if let lengthRow : TextRow = form.rowBy(tag: lengthRowTag), let startRow : DateTimeInlineRow = form.rowBy(tag: startRowTag), let startValue = startRow.value, let endRow : DateTimeInlineRow = form.rowBy(tag: endRowTag), let endValue = endRow.value {
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
            if scheduler.dailyTimes != nil {
                scheduler.dailyTimes![index].length = length
            }
        }
    }
    
}

extension SchedulerViewController: ActiveDaysDelegate {
    func updateIndexes(index: Int, indexes: [Int]) {
        if scheduler.dailyTimes != nil {
            for i in 0...scheduler.dailyTimes!.count - 1 {
                if i != index, let activeDays = scheduler.dailyTimes![i].activeDays {
                    for ind in indexes {
                        if let firstIndex = activeDays.firstIndex(of: ind) {
                            scheduler.dailyTimes![i].activeDays!.remove(at: firstIndex)
                        }
                    }
                    if let row : ActiveDaysRow = form.rowBy(tag: "\(i)") {
                        row.value = scheduler.dailyTimes![i].activeDays ?? []
                        row.updateCell()
                    }
                }
            }
            if let row : ActiveDaysRow = form.rowBy(tag: "\(index)") {
                row.value = indexes
                row.updateCell()
                scheduler.dailyTimes![index].activeDays = indexes
            }
        }
    }
}

