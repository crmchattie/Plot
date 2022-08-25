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
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        extendedLayoutIncludesOpaqueBars = true
                
//        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
//        navigationItem.rightBarButtonItem = plusBarButton
                
    }
    
    fileprivate func initializeForm() {
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Sub-Tasks",
                               footer: "Add a sub-task") {
                                $0.tag = "Tasks"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add Sub-Task"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
//                let destination = ChooseTaskTableViewController()
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
        let rowType = rows[0].self
                    
        DispatchQueue.main.async { [weak self] in
            if rowType is SubtaskRow {
                if self!.subtaskList.indices.contains(self!.subtaskIndex) {
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
            if mvs.count == 1 {
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

extension SubtaskListViewController: ChooseTaskDelegate {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let group = DispatchGroup()
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    participants.append(user)
                }
                
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(participants)
        }
    }
    
    func chosenTask(mergeTask: Activity) {
        if let _ = mergeTask.name, let currentUserID = Auth.auth().currentUser?.uid {
            self.getParticipants(forActivity: mergeTask) { (participants) in
                let deleteActivity = ActivityActions(activity: mergeTask, active: true, selectedFalconUsers: participants)
                deleteActivity.deleteActivity()
            }
            
            mergeTask.participantsIDs = [currentUserID]
            mergeTask.admin = currentUserID
            
            var mvs = (form.sectionBy(tag: "Tasks") as! MultivaluedSection)
            mvs.insert(SubtaskRow() {
                $0.value = mergeTask
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
