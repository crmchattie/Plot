//
//  EventsControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol EventsControllerCellDelegate: AnyObject {
    func cellTapped(activity: Activity)
    func updateInvitation(invitation: Invitation)
}

class EventsControllerCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate, UpdateInvitationDelegate {
    weak var delegate: EventsControllerCellDelegate?
    
    var tableView = UITableView(frame: .zero, style: .insetGrouped)
    var events = [Activity]() {
        didSet {
            setupViews()
            tableView.reloadData()
        }
    }
    var invitations: [String: Invitation] = [:]
    
    let eventCellID = "eventCellID"
    
    let viewPlaceholder = ViewPlaceholder()
    
    var participants: [String: [User]] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.register(EventCell.self, forCellReuseIdentifier: eventCellID)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if events.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyActivitiesMain, subtitle: .emptyActivitiesMain, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: eventCellID, for: indexPath) as? EventCell ?? EventCell()
        cell.activityDataStore = self
        let activity = events[indexPath.row]
        var invitation: Invitation? = nil
        if let activityID = activity.activityID, let value = invitations[activityID] {
            invitation = value
        }
        cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
        cell.updateInvitationDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = events[indexPath.row]
        delegate?.cellTapped(activity: activity)
    }
    
    func updateInvitation(invitation: Invitation) {
        delegate?.updateInvitation(invitation: invitation)
    }
}

extension EventsControllerCell: ActivityDataStore {
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



