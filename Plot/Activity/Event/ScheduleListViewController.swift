//
//  ScheduleListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/9/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import Contacts
import EventKit


protocol UpdateScheduleListDelegate: AnyObject {
    func updateScheduleList(scheduleList: [Activity])
}

class ScheduleListViewController: FormViewController {
    
    weak var delegate : UpdateScheduleListDelegate?
    
    var scheduleList: [Activity]!
    var scheduleIndex: Int = 0
    
    var acceptedParticipant = [User]()
    var startDateTime: Date?
    var endDateTime: Date?
    var locationAddress = [String : [Double]]()
    
    var activities = [Activity]()
    var activity: Activity!
        
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sub-Events"
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
                
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem = plusBarButton
                
    }
    
    fileprivate func initializeForm() {
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Sub-Events",
                               footer: "Add a sub-event") {
                                $0.tag = "Events"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add Sub-Event"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            cell.height = { 60 }
                                        }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return ScheduleRow("label"){ _ in
                                        self.scheduleIndex = index
                                        self.openSchedule()
                                    }
                                }

                            }
        
        for schedule in scheduleList {
            var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = schedule
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
        }
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        delegate?.updateScheduleList(scheduleList: scheduleList)
        self.navigationController?.popViewController(animated: true)
    }
    
    func openSchedule() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if scheduleList.indices.contains(scheduleIndex) {
            showActivityIndicator()
            let scheduleItem = scheduleList[scheduleIndex]
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
        } else {            
            let destination = ScheduleViewController()
            destination.users = self.acceptedParticipant
            destination.filteredUsers = self.acceptedParticipant
            destination.delegate = self
            destination.startDateTime = self.startDateTime
            destination.endDateTime = self.endDateTime
            self.navigationController?.pushViewController(destination, animated: true)
                        
//            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//            alert.addAction(UIAlertAction(title: "New Sub-Event", style: .default, handler: { (_) in
//                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
//                    mvs.remove(at: mvs.count - 2)
//                }
//                let destination = ScheduleViewController()
//                destination.users = self.acceptedParticipant
//                destination.filteredUsers = self.acceptedParticipant
//                destination.delegate = self
//                destination.startDateTime = self.startDateTime
//                destination.endDateTime = self.endDateTime
//                self.navigationController?.pushViewController(destination, animated: true)
//            }))
//            alert.addAction(UIAlertAction(title: "Merge Existing Event", style: .default, handler: { (_) in
//                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
//                    mvs.remove(at: mvs.count - 2)
//                }
//                let destination = ChooseEventTableViewController(networkController: networkController)
//                destination.needDelegate = true
//                destination.movingBackwards = true
//                destination.delegate = self
//                destination.event = self.activity
//                destination.events = self.activities
//                destination.filteredEvents = self.activities
//                self.navigationController?.pushViewController(destination, animated: true)
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
//                if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
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
            if row is ScheduleRow, row.tag != "label" {
                if self!.scheduleList.indices.contains(rowNumber) {
                    if let scheduleLocationAddress = self!.scheduleList[rowNumber].locationAddress {
                        for (key, _) in scheduleLocationAddress {
                            self!.locationAddress[key] = nil
                        }
                    }
                    self!.scheduleList.remove(at: rowNumber)
                    self!.sortSchedule()
                }
            }
        }
    }
    
    func sortSchedule() {
        scheduleList.sort { (schedule1, schedule2) -> Bool in
            return schedule1.startDateTime?.int64Value ?? 0 < schedule2.startDateTime?.int64Value ?? 0
        }
        if let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
            print(mvs.count)
            if mvs.count < 3 {
                return
            }
            for index in 0...mvs.count - 2 {
                let scheduleRow = mvs.allRows[index]
                scheduleRow.baseValue = scheduleList[index]
                scheduleRow.reload()
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

extension ScheduleListViewController: UpdateActivityDelegate {
    func updateActivity(activity: Activity) {
        if let _: ScheduleRow = self.form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        
        if let _ = activity.name {
            if scheduleList.indices.contains(scheduleIndex), let mvs = self.form.sectionBy(tag: "Events") as? MultivaluedSection {
                let scheduleRow = mvs.allRows[scheduleIndex]
                scheduleRow.baseValue = activity
                scheduleRow.reload()
                scheduleList[scheduleIndex] = activity
            } else {
                var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
                mvs.insert(ScheduleRow() {
                    $0.value = activity
                    }.onCellSelection() { cell, row in
                        self.scheduleIndex = row.indexPath!.row
                        self.openSchedule()
                        cell.cellResignFirstResponder()
                }, at: mvs.count - 1)
                
                Analytics.logEvent("new_schedule", parameters: [
                    "schedule_name": activity.name ?? "name" as NSObject,
                    "schedule_type": activity.activityType ?? "basic" as NSObject
                ])
                scheduleList.append(activity)
            }
            
            sortSchedule()
            if let localAddress = activity.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
        }
    }
}

extension ScheduleListViewController: ChooseActivityDelegate {    
    func chosenActivity(mergeActivity: Activity) {
        if let _ = mergeActivity.name, let currentUserID = Auth.auth().currentUser?.uid {
            ParticipantsFetcher.getParticipants(forActivity: mergeActivity) { (participants) in
                let deleteActivity = ActivityActions(activity: mergeActivity, active: true, selectedFalconUsers: participants)
                deleteActivity.deleteActivity()
            }
            
            mergeActivity.participantsIDs = [currentUserID]
            mergeActivity.admin = currentUserID
            
            var mvs = (form.sectionBy(tag: "Events") as! MultivaluedSection)
            mvs.insert(ScheduleRow() {
                $0.value = mergeActivity
                }.onCellSelection() { cell, row in
                    self.scheduleIndex = row.indexPath!.row
                    self.openSchedule()
                    cell.cellResignFirstResponder()
            }, at: mvs.count - 1)
            
            Analytics.logEvent("new_schedule", parameters: [
                "schedule_name": mergeActivity.name ?? "name" as NSObject,
                "schedule_type": mergeActivity.activityType ?? "basic" as NSObject
            ])
            
            scheduleList.append(mergeActivity)
            
            sortSchedule()
            if let localAddress = mergeActivity.locationAddress {
                for (key, value) in localAddress {
                    locationAddress[key] = value
                }
            }
        }
    }
}

