//
//  ActivitiesControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Firebase

protocol ActivitiesControllerCellDelegate: class {
    func cellTapped(activity: Activity)
    func openMap(forActivity activity: Activity)
    func openChat(forConversation conversationID: String?, activityID: String?)
    func updateInvitation(invitation: Invitation)
}

class ActivitiesControllerCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate, ActivityCellDelegate, UpdateInvitationDelegate {
    weak var delegate: ActivitiesControllerCellDelegate?
    
    var tableView = UITableView(frame: .zero, style: .insetGrouped)
    var activities = [Activity]() {
        didSet {
            setupViews()
            tableView.reloadData()
        }
    }
    var invitations: [String: Invitation] = [:]
    
    let activityCellID = "activityCellID"
    
    let viewPlaceholder = ViewPlaceholder()
    
    var activitiesParticipants: [String: [User]] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
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
        let activity = activities[indexPath.row]
        if let activityID = activity.activityID, let _ = invitations[activityID] {
            return 168
        } else {
            return 140
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if activities.count == 0 {
            viewPlaceholder.add(for: tableView, title: .emptyActivities, subtitle: .emptyActivities, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
        }
        return activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ActivityCell ?? ActivityCell()
        cell.activityViewControllerDataStore = self
        let activity = activities[indexPath.row]
        var invitation: Invitation? = nil
        if let activityID = activity.activityID, let value = invitations[activityID] {
            invitation = value
        }
        cell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
        cell.delegate = self
        cell.updateInvitationDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let activity = activities[indexPath.row]
        delegate?.cellTapped(activity: activity)
    }
    
    func openMap(forActivity activity: Activity) {
        delegate?.openMap(forActivity: activity)
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        delegate?.openChat(forConversation: conversationID, activityID: activityID)
    }
    
    func updateInvitation(invitation: Invitation) {
        delegate?.updateInvitation(invitation: invitation)
    }
}

extension ActivitiesControllerCell: ActivityViewControllerDataStore {
    func getParticipants(forActivity activity: Activity, completion: @escaping ([User])->()) {
        guard let activityID = activity.activityID, let participantsIDs = activity.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        
        let group = DispatchGroup()
        let olderParticipants = self.activitiesParticipants[activityID]
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
            self.activitiesParticipants[activityID] = participants
            completion(participants)
        }
    }
}



