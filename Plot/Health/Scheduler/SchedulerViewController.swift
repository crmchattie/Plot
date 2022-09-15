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
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        
        
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
                        let date = rounded
                        let ID = Database.database().reference().child(userSleepEntity).child(currentUser).childByAutoId().key ?? ""
                        var dateComp = DateComponents()
                        dateComp.hour = 23
                        dateComp.minute = 0
                        let startTime = Calendar.current.date(from: dateComp)
                        dateComp.hour = 7
                        dateComp.minute = 0
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
                        let date = rounded
                        let ID = Database.database().reference().child(userWorkEntity).child(currentUser).childByAutoId().key ?? ""
                        var dateComp = DateComponents()
                        dateComp.hour = 9
                        dateComp.minute = 0
                        let startTime = Calendar.current.date(from: dateComp)
                        dateComp.hour = 17
                        dateComp.minute = 0
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
        view.backgroundColor = .systemGroupedBackground
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        definesPresentationContext = true
        
        if active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        } else {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
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
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
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
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.delegate = self
                        $0.value = dailyTimes[index].activeDays ?? []
                    }
                    
                    <<< TextRow("Length\(index)") {
                        $0.cell.isUserInteractionEnabled = false
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textField?.textColor = .secondaryLabel
                        $0.title = "Length"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textField?.textColor = .secondaryLabel
                    }
                    
                    <<< DateTimeInlineRow("\(type.categoryText)\(index)") {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.detailTextLabel?.textColor = .secondaryLabel
                        $0.title = "\(type.categoryText)"
                        $0.minuteInterval = 5
                        $0.dateFormatter?.dateStyle = .none
                        $0.dateFormatter?.timeStyle = .short
                        $0.value = dailyTimes[index].startTime
                    }.onChange { [weak self] row in
                        self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                        self!.scheduler.dailyTimes![index].startTime = row.value
                    }.onExpandInlineRow { cell, row, inlineRow in
                        inlineRow.cellUpdate() { cell, row in
                            row.cell.backgroundColor = .secondarySystemGroupedBackground
                            row.cell.tintColor = .secondarySystemGroupedBackground
                            cell.datePicker.datePickerMode = .time
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
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .secondaryLabel
                    }
                
                    <<< DateTimeInlineRow("\(type.subcategoryText)\(index)") {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.detailTextLabel?.textColor = .secondaryLabel
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
                            row.cell.backgroundColor = .secondarySystemGroupedBackground
                            row.cell.tintColor = .secondarySystemGroupedBackground
                            cell.datePicker.datePickerMode = .time
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
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .secondaryLabel
                    }
                
                <<< ButtonRow("Add Additional Schedule for Other Days") { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .center
                    row.cell.accessoryType = .none
                    row.title = row.tag
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
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
            let startTime = Calendar.current.date(from: dateComp)
            dateComp.hour = 17
            dateComp.minute = 0
            let endTime = Calendar.current.date(from: dateComp)
            
            let dailyTime = DailyTimes(activeDays: nil, length: 8 * 60 * 60, startTime: startTime, endTime: endTime)
            scheduler.dailyTimes!.append(dailyTime)
            let index = scheduler.dailyTimes!.count - 1
            
            var section = self.form.allSections[0]
            if let buttonRow: ButtonRow = self.form.rowBy(tag: "Add Additional Schedule"), let buttonRowIndex = buttonRow.indexPath?.item {
                section.insert(DateTimeInlineRow("\(type.subcategoryText)\(index)") {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
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
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.datePickerMode = .time
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
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }, at: buttonRowIndex)
                
                section.insert(DateTimeInlineRow("\(type.categoryText)\(index)") {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    $0.title = "\(type.categoryText)"
                    $0.minuteInterval = 5
                    $0.dateFormatter?.dateStyle = .none
                    $0.dateFormatter?.timeStyle = .short
                    $0.value = scheduler.dailyTimes![index].startTime
                }.onChange { [weak self] row in
                    self!.updateLength(lengthRowTag: "Length\(index)", startRowTag: "\(self!.type.categoryText)\(index)", endRowTag: "\(self!.type.subcategoryText)\(index)", index: index)
                    self!.scheduler.dailyTimes![index].startTime = row.value
                }.onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.datePickerMode = .time
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
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }, at: buttonRowIndex)
                
                section.insert(TextRow("Length\(index)") {
                    $0.cell.isUserInteractionEnabled = false
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textField?.textColor = .secondaryLabel
                    $0.title = "Length"
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textField?.textColor = .secondaryLabel
                }, at: buttonRowIndex)
                
                section.insert(ActiveDaysRow("\(index)") {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
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
                length += 86400
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

