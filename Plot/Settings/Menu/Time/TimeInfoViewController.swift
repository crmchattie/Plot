//
//  TimeInfoViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/25/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

let primaryCalendarKey = "primary-calendar"
let primaryReminderKey = "primary-reminder"

class TimeInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Time Information"
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        if indexPath.row == 0 {
            cell.textLabel?.text = "Lists Info"
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        else if indexPath.row == 1 {
            cell.textLabel?.text = "Calendars Info"
            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let destination = ListInfoViewController()
            destination.networkController = self.networkController
            self.navigationController?.pushViewController(destination, animated: true)
        }
        if indexPath.row == 1 {
            let destination = CalendarInfoViewController()
            destination.networkController = networkController
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
