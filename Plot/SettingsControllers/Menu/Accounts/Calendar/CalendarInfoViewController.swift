//
//  CalendarInfoViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import GoogleSignIn

class CalendarInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    var calendars: [String: [String]] {
        return networkController.activityService.calendars
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Calendar Information"
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newCalendar))
        navigationItem.rightBarButtonItem = barButton
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
    }
    
    @objc func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !calendars.keys.contains("Apple") {
            alert.addAction(UIAlertAction(title: "Apple", style: .default, handler: { (_) in
                self.networkController.activityService.grabEventKit {}
            }))
        }
        alert.addAction(UIAlertAction(title: "Google", style: .default, handler: { (_) in
            GIDSignIn.sharedInstance()?.signIn()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return calendars.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = Array(calendars.keys)
        let section = sections[section]
        return calendars[section]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        let sections = Array(calendars.keys)
        cell.textLabel?.text = sections[section]
        cell.isUserInteractionEnabled = false
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        let sections = Array(calendars.keys)
        let section = sections[indexPath.section]
        cell.textLabel?.text = calendars[section]?[indexPath.row]
        cell.isUserInteractionEnabled = false
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension CalendarInfoViewController {
    @objc private func userDidSignInGoogle(_ notification: Notification) {
        // Update screen after user successfully signed in
        
    }
}
