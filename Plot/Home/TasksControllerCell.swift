//
//  RemindersControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 8/22/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol TasksControllerCellDelegate: AnyObject {
    func cellTapped(task: Activity)
}

class TasksControllerCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
    weak var delegate: TasksControllerCellDelegate?
    
    var tableView = UITableView(frame: .zero, style: .insetGrouped)
    var tasks = [Activity]() {
        didSet {
            setupViews()
            tableView.reloadData()
        }
    }
    
    let taskCellID = "taskCellID"
    
    let viewPlaceholder = ViewPlaceholder()
    
    var participants: [String: [User]] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.register(TaskCell.self, forCellReuseIdentifier: taskCellID)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        addSubview(tableView)
        tableView.fillSuperview()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tasks.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyTasksMain, subtitle: .emptyTasksMain, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: taskCellID, for: indexPath) as? TaskCell ?? TaskCell()
        cell.activityDataStore = self
        let task = tasks[indexPath.row]
        cell.configureCell(for: indexPath, task: task)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        delegate?.cellTapped(task: task)
    }
}

extension TasksControllerCell: ActivityDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.participants[activityID]
        var participants: [User] = []
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activity.admin == currentUserID && id == currentUserID {
                continue
            }
            
            if let first = olderParticipants?.filter({$0.id == id}).first {
                participants.append(first)
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
            self.participants[activityID] = participants
            completion(participants)
        }
    }
}
