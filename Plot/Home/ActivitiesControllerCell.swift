//
//  ActivitiesControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol ActivitiesControllerCellDelegate: AnyObject {
    func cellTapped(activity: Activity)
    func headerTapped(sectionType: SectionType)
    func updateInvitation(invitation: Invitation)
}

class ActivitiesControllerCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate, UpdateInvitationDelegate {
    weak var delegate: ActivitiesControllerCellDelegate?
    
    var networkController = NetworkController()
    var tableView = UITableView(frame: .zero, style: .insetGrouped)
    var sections = [SectionType]()
    var activities = [SectionType: [Activity]]() {
        didSet {
            setupViews()
            tableView.reloadData()
        }
    }
    var invitations: [String: Invitation] = [:]
    
    let headerCellID = "headerCellID"
    
    let viewPlaceholder = ViewPlaceholder()
    
    var participants: [String: [User]] = [:]
    
    var updatingTasks = true
    var updatingEvents = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.register(TableViewHeader.self,
                           forHeaderFooterViewReuseIdentifier: headerCellID)
        tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        tableView.backgroundColor = .systemGroupedBackground
        addSubview(tableView)
        tableView.fillSuperview()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                                                                headerCellID) as? TableViewHeader ?? TableViewHeader()
        if sections.count > 1 {
            let section = sections[section]
            if section == .tasks {
                if updatingTasks {
                    header.spinnerView.startAnimating()
                } else {
                    header.spinnerView.stopAnimating()
                }
            } else {
                if updatingTasks {
                    header.spinnerView.startAnimating()
                } else {
                    header.spinnerView.stopAnimating()
                }
            }
            header.backgroundColor = .systemGroupedBackground
            header.titleLabel.text = section.name
            header.subTitleLabel.isHidden = false
            header.delegate = self
            header.sectionType = section
        }
        return header

    }
//
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections.count > 1 {
            return 30
        } else {
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sec = sections[section]
        let activitiesCount = activities[sec]?.count ?? 0
        if activitiesCount == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyTime, subtitle: .emptyTime, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return activitiesCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let activities = activities[section] ?? []
        let activity = activities[indexPath.row]
        if section == .tasks {
            let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
            if let listID = activity.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                activity.listColor = color
            } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                activity.calendarColor = color
            }
            cell.configureCell(for: indexPath, task: activity)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
            var invitation: Invitation? = nil
            if let calendarID = activity.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                activity.calendarColor = color
            } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                activity.calendarColor = color
            }
            if let activityID = activity.activityID, let value = invitations[activityID] {
                invitation = value
            }
            cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
            cell.updateInvitationDelegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if let activities = activities[section] {
            let activity = activities[indexPath.row]
            delegate?.cellTapped(activity: activity)
        }
    }
    
    func updateInvitation(invitation: Invitation) {
        delegate?.updateInvitation(invitation: invitation)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ActivitiesControllerCell: HeaderCellDelegate {
    func viewTapped(sectionType: SectionType) {
        delegate?.headerTapped(sectionType: sectionType)
    }
}



