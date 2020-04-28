//
//  ListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class ListsViewController: UIViewController {
    
    weak var activityViewController: ActivityViewController?
    
    var activities: [Activity] = []
    
    var invitations = [String: Invitation]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    let viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
                        
        addObservers()
                
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor

    }
    
}
