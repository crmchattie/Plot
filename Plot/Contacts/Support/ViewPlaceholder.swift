//
//  ViewPlaceholder.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/6/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit

enum ViewPlaceholderPriority: CGFloat {
    case low = 0.1
    case medium = 0.5
    case high = 1.0
}

enum ViewPlaceholderPosition {
    case top
    case center
    case fill
}

enum ViewPlaceholderTitle: String {
    case denied = "Plot doesn't have access to your contacts"
    case emptyContacts = "You don't have any Plot Users yet"
    case emptyChat = "You don't have any active conversations yet"
    case emptyTime = "You don't have any tasks or events yet"
    case emptyEvents = "You don't have any events or tasks that match the filter(s) and/or keyword search"
    case emptyEventsMain = "You don't have any events yet"
    case emptyTasksMain = "You don't have any tasks yet"
    case emptyUsers = "No users available to invite"
    case emptyPhotos = "You don't have any photos yet"
    case emptyFiles = "You don't have any docs yet"
    case emptyRecipes = "Could not find any recipes that match the filter(s) and/or keyword search"
    case emptyTasks = "Could not find any tasks that match the filter(s) and/or keyword search"
    case emptyGoals = "Could not find any goals that match the filter(s) and/or keyword search"
    case emptySearch = "Could not find any items that match the filter(s)"
    case emptySearchTemplate = "Could not find any items that match the keyword search"
    case emptyPlaces = "Could not find any places that match the filter(s) and/or keyword search"
    case emptyLocationSearch = "Please search for locations above"
    case emptyNotifications = "You don't have any notifications yet"
    case emptyInvitedActivities = "You have not yet been invited to any events"
    case emptyFilteredInvitedActivities = "You don't have any pending invitations"
    case emptyLists = "You are not connected to any lists yet"
    case emptyIngredients = "Please search for ingredients and grocery items above"
    case emptyAccounts = "You are not connected to any accounts yet"
    case emptyMealProducts = "Please search for ingredients, grocery items and restaurant menu items above"
    case emptyTransactionRules = "You have not created any transaction rules"
    case emptyHealth = "You don't have any health metrics yet"
    case emptyCalendars = "You are not connected to any calendars yet"
    case emptyAnalytics = "Analytics about your time, health and finances will appear here once set-up and created"
}

enum ViewPlaceholderSubtitle: String {
    case empty = ""
    case denied = "Please go to your iPhone Settings –– Privacy –– Contacts. Then select ON for Plot. If you have Privacy Restrictions ON, please go to Screen Time - Content & Privacy Restrictions - Contacts. Then select ALLOW for Plot"
    case emptyContacts = "You can invite your friends to Plot with the notepad button in the upper right corner"
    case emptyChat = "You can create your first conversation with the notepad button in the upper right corner"
    case emptyTime = "Add an event or task with the plus button in the upper right corner"
    case emptyEventsMain = "You can allow Plot to access events from the Calendar App and/or add an event with the plus button in the upper right corner"
    case emptyTasksEvents = "Update the filters and/or keyword search in the upper right corner"
    case emptyTasksMain = "You can allow Plot to access events from the Reminders App and/or add a task with the plus button in the upper right corner"
    case emptyPhotos = "You can add photos with the plus button in the upper right corner"
    case emptyFiles = "You can add docs with the plus button in the upper right corner"
    case emptyRecipesEvents = "You can update the search via the search bar and/or by adjusting filters in the upper right corner"
    case emptySearch = "You can update the search by adjusting the search text and/or filters in the upper right corner"
    case emptySearchTemplate = "You can update the search by adjusting the keyword search"
    case emptyInvitedActivities = "Once you are invited to an event it will appear here"
    case emptyFilteredInvitedActivities = "New invitations will appear here"
    case emptyMap = "Activities will appear here and on the map as pins"
    case emptyLists = "You can add a list with the plus button in the upper right corner"
    case emptyAccounts = "You can add an account with the plus button in the upper right corner"
    case emptyTransactionRules = "You can add a transaction rule with the plus button in the upper right corner"
    case emptyHealth = "You can allow Plot to access health metrics from the Health App and/or add a metric with the plus button in the upper right corner"
    case emptyCalendars = "You can add a calendar with the plus button in the upper right corner"
    case emptyAnalytics = "Set-up your time, health and finances on the home tab or create tasks, events and more on the discover tab"
}

class ViewPlaceholder: UIView {
    
    var title = UILabel()
    var subtitle = UILabel()
    
    var placeholderPriority: ViewPlaceholderPriority = .low
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
        title.font = .preferredFont(forTextStyle: .body)
        title.textColor = .secondaryLabel
        title.textAlignment = .center
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false
        title.adjustsFontForContentSizeCategory = true
        
        subtitle.font = .preferredFont(forTextStyle: .footnote)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.adjustsFontForContentSizeCategory = true
        
        addSubview(title)
        
        title.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        title.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
//        title.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        addSubview(subtitle)
        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5).isActive = true
        subtitle.leftAnchor.constraint(equalTo: leftAnchor, constant: 35).isActive = true
        subtitle.rightAnchor.constraint(equalTo: rightAnchor, constant: -35).isActive = true
//        subtitle.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func add(for view: UIView, title: ViewPlaceholderTitle, subtitle: ViewPlaceholderSubtitle, priority: ViewPlaceholderPriority, position: ViewPlaceholderPosition) {
        
        guard priority.rawValue >= placeholderPriority.rawValue else { return }
        placeholderPriority = priority
        self.title.text = title.rawValue
        self.subtitle.text = subtitle.rawValue
        
        if position == .center {
            self.title.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        }
        if position == .top {
            self.title.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        }
        
        DispatchQueue.main.async {
            view.addSubview(self)
            if position == .fill {
                self.title.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
                self.topAnchor.constraint(equalTo: view.topAnchor, constant: 90).isActive = true
                self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
                self.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
            } else {
                if #available(iOS 11.0, *) {
                    self.topAnchor.constraint(equalTo: view.topAnchor, constant: 175).isActive = true
                } else {
                    self.topAnchor.constraint(equalTo: view.topAnchor, constant: 135).isActive = true
                }
                self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
                self.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width - 20).isActive = true
            }
        }
    }
    
    func remove(from view: UIView, priority: ViewPlaceholderPriority) {
        guard priority.rawValue >= placeholderPriority.rawValue else { return }
        for subview in view.subviews where subview is ViewPlaceholder {
            DispatchQueue.main.async {
                subview.removeFromSuperview()
            }
        }
    }
}
