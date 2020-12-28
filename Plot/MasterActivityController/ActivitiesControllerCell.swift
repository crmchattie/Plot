//
//  ActivitiesControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol ActivitiesControllerCellDelegate: class {
    func cellTapped(activity: Activity)
    func openMap(forActivity activity: Activity)
    func openChat(forConversation conversationID: String?, activityID: String?)
}

class ActivitiesControllerCell: BaseContainerCell, UITableViewDataSource, UITableViewDelegate, ActivityCellDelegate, UpdateInvitationDelegate {
    weak var delegate: ActivitiesControllerCellDelegate?
    
    var tableView = UITableViewWithReloadCompletion()
    var activities = [Activity]() {
        didSet {
            setupViews()
            tableView.reloadData()
        }
    }
    var invitations: [String: Invitation] = [:]
    
    let activityCellID = "activityCellID"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        tableView.backgroundColor = backgroundColor
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func setupViews() {
        super.setupViews()
        addSubview(tableView)
        tableView.fillSuperview(padding: .init(top: 10, left: 5, bottom: 5, right: 5))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath) as? ActivityCell ?? ActivityCell()
        cell.selectionStyle = .none
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
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
        tableView.deselectRow(at: indexPath, animated: true)
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
        InvitationsFetcher.update(invitation: invitation) { result in
            if result {
//                self.invitations[invitation.activityID] = invitation
            }
        }
    }
}



