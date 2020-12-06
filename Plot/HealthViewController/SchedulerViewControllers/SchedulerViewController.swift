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
    }
    
    fileprivate func setupVariables() {
        if scheduler == nil, let currentUser = Auth.auth().currentUser?.uid {
            active = false
            customSegmentControl = CustomMultiSegmentedControl(buttonImages: nil, buttonTitles: ["M", "T", "W", "T", "F", "S", "S"], selectedIndex: nil)
            if type == .sleep {
                let ID = Database.database().reference().child(userSleepEntity).child(currentUser).childByAutoId().key ?? ""
                scheduler = Scheduler(id: ID, name: nil, activeDays: nil, startTime: nil, endTime: nil, schedulerDate: Date(), lastModifiedDate: Date(), createdDate: Date())
            } else if type == .work {
                let ID = Database.database().reference().child(userWorkEntity).child(currentUser).childByAutoId().key ?? ""
                scheduler = Scheduler(id: ID, name: nil, activeDays: nil, startTime: nil, endTime: nil, schedulerDate: Date(), lastModifiedDate: Date(), createdDate: Date())
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
        
        customSegmentControl.constrainHeight(50)
        
        view.addSubview(customSegmentControl)
        view.addSubview(tableView)
        
        customSegmentControl.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        tableView.anchor(top: customSegmentControl.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    @IBAction func create(_ sender: AnyObject) {
//        if transaction.user_created ?? false, !active {
//            self.showActivityIndicator()
//            let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
//            createTransaction.createNewTransaction()
//            self.hideActivityIndicator()
//        }
        self.navigationController?.popViewController(animated: true)
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
                if let startRow: DateTimeInlineRow = self.form.rowBy(tag: "\(type.categoryText)"), let endRow: DateTimeInlineRow = self.form.rowBy(tag: "\(type.subcategoryText)") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startRow.value!, to: endRow.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        $0.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        $0.value = "\(minutes) minutes"
                    }
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
            <<< DateTimeInlineRow("\(type.categoryText)") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .none
                $0.dateFormatter?.timeStyle = .short
                $0.value = scheduler.startTime ?? Date()
            }.onChange { [weak self] row in
                if let lengthRow : TextRow = self?.form.rowBy(tag: "Length"), let endRow : DateTimeInlineRow = self?.form.rowBy(tag: "\(self!.type.subcategoryText)") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: row.value!, to: endRow.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        lengthRow.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        lengthRow.value = "\(minutes) minutes"
                    }
                    lengthRow.updateCell()
                }
                self!.scheduler.startTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
            <<< DateTimeInlineRow("\(type.subcategoryText)") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .none
                $0.dateFormatter?.timeStyle = .short
                $0.value = scheduler.endTime ?? Date()
            }.onChange { [weak self] row in
                if let lengthRow : TextRow = self?.form.rowBy(tag: "Length"), let startRow : DateTimeInlineRow = self?.form.rowBy(tag: "\(self!.type.categoryText)") {
                    let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startRow.value!, to: row.value!)
                    let hour = dateComponents.hour
                    let minutes = dateComponents.minute
                    if let minutes = minutes, let hour = hour {
                        lengthRow.value = "\(hour) hours \(minutes) minutes"
                    } else if let minutes = minutes {
                        lengthRow.value = "\(minutes) minutes"
                    }
                    lengthRow.updateCell()
                }
                self!.scheduler.endTime = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
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
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
        
    }
    
}

extension SchedulerViewController: CustomMultiSegmentedControlDelegate {
    func changeToIndex(indexes:[Int]) {
        scheduler.activeDays = getDaysOfWeek(integers: indexes)
    }
}

