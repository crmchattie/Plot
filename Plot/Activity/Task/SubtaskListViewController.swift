//
//  SubtaskListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import Contacts
import EventKit


protocol UpdateSubtaskListDelegate: AnyObject {
    func updateSubtaskList(subtaskList: [Activity])
}

class SubtaskListViewController: FormViewController {
    
    weak var delegate : UpdateSubtaskListDelegate?
    
    var subtaskList: [Activity]!
    var subtaskIndex: Int = 0
    
    var selectedFalconUsers = [User]()
    var startDateTime: Date?
    var endDateTime: Date?
    
    var tasks = [Activity]()
    var task: Activity!
        
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sub-Tasks"
        setupMainView()
        initializeForm()
        
    }
    
    fileprivate func setupMainView() {
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        extendedLayoutIncludesOpaqueBars = true
                
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem = plusBarButton
        
        navigationOptions = .Disabled
                
    }
    
    fileprivate func initializeForm() {
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Sub-Tasks",
                               footer: "Add a sub-task") {
                                $0.tag = "Tasks"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add Sub-Task"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textAlignment = .left
                                            cell.height = { 60 }
                                        }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return SubtaskRow("label"){ _ in
                                        self.subtaskIndex = index
                                        self.openSubtask()
                                    }
                                }

                            }
        
        for subtask in subtaskList {
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                $0.value = subtask
                $0.cell.delegate = self
                }.onCellSelection() { cell, row in
                    self.subtaskIndex = row.indexPath!.row
                    self.openSubtask()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        delegate?.updateSubtaskList(subtaskList: subtaskList)
        self.navigationController?.popViewController(animated: true)
    }
    
    func openSubtask() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if subtaskList.indices.contains(subtaskIndex) {
            showActivityIndicator()
            let subtaskItem = subtaskList[subtaskIndex]
            let destination = SubtaskViewController()
            destination.subtask = subtaskItem
            destination.users = selectedFalconUsers
            destination.filteredUsers = selectedFalconUsers
            destination.startDateTime = startDateTime
            destination.endDateTime = endDateTime
            destination.delegate = self
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let destination = SubtaskViewController()
            destination.users = self.selectedFalconUsers
            destination.filteredUsers = self.selectedFalconUsers
            destination.delegate = self
            destination.startDateTime = self.startDateTime
            destination.endDateTime = self.endDateTime
            self.navigationController?.pushViewController(destination, animated: true)
            
//            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//            alert.addAction(UIAlertAction(title: "New Sub-Task", style: .default, handler: { (_) in
//                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
//                    mvs.remove(at: mvs.count - 2)
//                }
//                let destination = SubtaskViewController()
//                destination.users = self.selectedFalconUsers
//                destination.filteredUsers = self.selectedFalconUsers
//                destination.delegate = self
//                destination.startDateTime = self.startDateTime
//                destination.endDateTime = self.endDateTime
//                self.navigationController?.pushViewController(destination, animated: true)
//            }))
//            alert.addAction(UIAlertAction(title: "Merge Existing Task", style: .default, handler: { (_) in
//                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
//                    mvs.remove(at: mvs.count - 2)
//                }
//                let destination = ChooseTaskTableViewController(networkController: networkController)
//                destination.needDelegate = true
//                destination.movingBackwards = true
//                destination.delegate = self
//                destination.task = self.task
//                destination.tasks = self.tasks
//                destination.filteredTasks = self.tasks
//                self.navigationController?.pushViewController(destination, animated: true)
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
//                if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
//                    mvs.remove(at: mvs.count - 2)
//                }
//            }))
//            self.present(alert, animated: true)
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let row = rows[0].self
                    
        DispatchQueue.main.async { [weak self] in
            if row is SubtaskRow, row.tag != "label" {
                if self!.subtaskList.indices.contains(rowNumber) {
                    self!.subtaskList.remove(at: rowNumber)
                    self!.sortSubtask()
                }
            }
        }
    }
    
    func sortSubtask() {
        subtaskList.sort { (subtask1, subtask2) -> Bool in
            return subtask1.startDateTime?.int64Value ?? 0 < subtask2.startDateTime?.int64Value ?? 0
        }
        if let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
            if mvs.count < 3 {
                return
            }
            for index in 0...mvs.count - 2 {
                let subtaskRow = mvs.allRows[index]
                subtaskRow.baseValue = subtaskList[index]
                subtaskRow.reload()
            }
        }
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
}

extension SubtaskListViewController: UpdateTaskDelegate {
    func updateTask(task: Activity) {
        if let _: SubtaskRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        
        if let _ = task.name {
            if subtaskList.indices.contains(subtaskIndex), let mvs = self.form.sectionBy(tag: "Tasks") as? MultivaluedSection {
                let subtaskRow = mvs.allRows[subtaskIndex]
                subtaskRow.baseValue = task
                subtaskRow.reload()
                subtaskList[subtaskIndex] = task
            } else {
                var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
                mvs.insert(SubtaskRow() {
                    $0.value = task
                    $0.cell.delegate = self
                    }.onCellSelection() { cell, row in
                        self.subtaskIndex = row.indexPath!.row
                        self.openSubtask()
                        cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_subtask", parameters: [
                    "subtask_name": task.name ?? "name" as NSObject,
                    "subtask_type": task.activityType ?? "basic" as NSObject
                ])
                subtaskList.append(task)
            }
            
            sortSubtask()
        }
    }
}

extension SubtaskListViewController: UpdateTaskCellDelegate {
    func updateCompletion(task: Activity) {
        if let index = subtaskList.firstIndex(where: {$0.activityID == task.activityID} ) {
            subtaskList[index].isCompleted = task.isCompleted ?? false
            if (subtaskList[index].isCompleted ?? false) {
                let original = Date()
                let updateDate = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                subtaskList[index].completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
            } else {
                subtaskList[index].completedDate = nil
            }
            
            let updateTask = ActivityActions(activity: subtaskList[index], active: true, selectedFalconUsers: [])
            updateTask.updateCompletion(isComplete: subtaskList[index].isCompleted ?? false)
        }
    }
}

extension SubtaskListViewController: ChooseTaskDelegate {
    func chosenTask(mergeTask: Activity) {
        if let _ = mergeTask.name, let currentUserID = Auth.auth().currentUser?.uid {
            ParticipantsFetcher.getParticipants(forActivity: mergeTask) { (participants) in
                let deleteActivity = ActivityActions(activity: mergeTask, active: true, selectedFalconUsers: participants)
                deleteActivity.deleteActivity()
            }
            
            mergeTask.participantsIDs = [currentUserID]
            mergeTask.admin = currentUserID
            
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                $0.value = mergeTask
                $0.cell.delegate = self
                }.onCellSelection() { cell, row in
                    self.subtaskIndex = row.indexPath!.row
                    self.openSubtask()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_subtask", parameters: [
                "subtask_name": mergeTask.name ?? "name" as NSObject,
                "subtask_type": mergeTask.activityType ?? "basic" as NSObject
            ])
            
            subtaskList.append(mergeTask)
            
            sortSubtask()
        }
    }
}

