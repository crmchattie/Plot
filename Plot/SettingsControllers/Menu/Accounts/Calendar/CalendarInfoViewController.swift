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

class CalendarInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    var calendars = ["Plot"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Calendar Information"
        
        grabAccounts()
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newCalendar))
        navigationItem.rightBarButtonItem = barButton
        
    }
    
    func grabAccounts() {
        if networkController.activityService.eventKitManager.isAuthorized {
            calendars.append("Apple")
        }
    }
    
    @objc func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if !calendars.contains("Apple") {
            alert.addAction(UIAlertAction(title: "Apple", style: .default, handler: { (_) in
                self.networkController.activityService.grabEventKit {}
            }))
        }
        alert.addAction(UIAlertAction(title: "Google", style: .default, handler: { (_) in
            print("User click Edit button")
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calendars.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.backgroundColor = view.backgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        cell.textLabel?.text = calendars[indexPath.row]
        cell.isUserInteractionEnabled = false

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
