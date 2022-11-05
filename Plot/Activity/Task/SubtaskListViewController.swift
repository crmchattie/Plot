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

class SubtaskListViewController: FormViewController, ObjectDetailShowing {
    var networkController = NetworkController()
    var participants = [String : [User]]()

    weak var delegate : UpdateSubtaskListDelegate?
    
    var subtaskList: [Activity]!
    var subtaskIndex: Int = 0
    
    var selectedFalconUsers = [User]()
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if navigationController?.visibleViewController is SubtaskViewController ||
            navigationController?.visibleViewController is ChooseTaskTableViewController { return
        }
        delegate?.updateSubtaskList(subtaskList: subtaskList)
    }
    
    fileprivate func setupMainView() {
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.rowHeight = UITableView.automaticDimension
        
        extendedLayoutIncludesOpaqueBars = true
                
//        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
//        navigationItem.rightBarButtonItem = plusBarButton
        
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
                $0.cell.parentTask = task
                $0.value = subtask
                $0.cell.delegate = self
                }.onCellSelection() { cell, row in
                    self.subtaskIndex = row.indexPath!.row
                    self.openSubtask()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
    }
    
    func openSubtask() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if subtaskList.indices.contains(subtaskIndex) {
            showSubtaskDetailPush(subtask: subtaskList[subtaskIndex], task: task, delegate: self, users: selectedFalconUsers)
        } else {
            showSubtaskDetailPush(subtask: nil, task: task, delegate: self, users: selectedFalconUsers)
            
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
        subtaskList.sort { (task1, task2) -> Bool in
            if !(task1.isCompleted ?? false) && !(task2.isCompleted ?? false) {
                if task1.endDate ?? Date.distantFuture == task2.endDate ?? Date.distantFuture {
                    if task1.priority == task2.priority {
                        return task1.name ?? "" < task2.name ?? ""
                    }
                    return TaskPriority(rawValue: task1.priority ?? "None")! > TaskPriority(rawValue: task2.priority ?? "None")!
                }
                return task1.endDate ?? Date.distantFuture < task2.endDate ?? Date.distantFuture
            } else if task1.isCompleted ?? false && task2.isCompleted ?? false {
                if task1.completedDate ?? 0 == task2.completedDate ?? 0 {
                    return task1.name ?? "" < task2.name ?? ""
                }
                return Int(truncating: task1.completedDate ?? 0) > Int(truncating: task2.completedDate ?? 0)
            }
            return !(task1.isCompleted ?? false)
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
                    $0.cell.parentTask = self.task
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
        if let index = subtaskList.firstIndex(where: {$0.activityID == task.activityID}), let currentUserID = Auth.auth().currentUser?.uid {
            subtaskList[index].isCompleted = task.isCompleted ?? false
            if (subtaskList[index].isCompleted ?? false) {
                let original = Date()
                let updateDate = Date(timeIntervalSinceReferenceDate:
                                    (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
                subtaskList[index].completedDate = NSNumber(value: Int((updateDate).timeIntervalSince1970))
            } else {
                subtaskList[index].completedDate = nil
            }
            
            let instanceID = Database.database().reference().child(userActivitiesEntity).child(currentUserID).childByAutoId().key ?? ""
            var instanceIDs = self.task.instanceIDs ?? []
            if let instance = self.task.instanceID {
                subtaskList[index].instanceID = instance
            } else {
                instanceIDs.append(instanceID)
                subtaskList[index].instanceIDs = instanceIDs
            }
            subtaskList[index].parentID = task.activityID
            
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
                deleteActivity.deleteActivity(updateExternal: false, updateDirectAssociation: false)
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

