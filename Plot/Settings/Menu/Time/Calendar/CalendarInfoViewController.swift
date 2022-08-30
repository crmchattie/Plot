//
//  CalendarInfoViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class CalendarInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    let viewPlaceholder = ViewPlaceholder()
    
    var primaryCalendar: String {
        return networkController.activityService.primaryCalendar
    }
    
    var calendars: [String: [CalendarType]] {
        return networkController.activityService.calendars
    }
    
    var sections = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Calendars Information"
        
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.apple.name) || !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.google.name) {
            let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newCalendar))
            navigationItem.rightBarButtonItem = barButton
        }
        
        sections = Array(calendars.keys).sorted { s1, s2 in
            if s1 == CalendarSourceOptions.plot.name {
                return true
            } else if s2 == CalendarSourceOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyCalendars, subtitle: .emptyCalendars, priority: .medium, position: .top)
    }
    
    @objc func newCalendar() {
        let destination = SignInAppleGoogleViewController()
        destination.networkController = self.networkController
        destination.title = "Calendars"
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if calendars.keys.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return calendars.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return calendars[section]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = CalendarAccountView()
        if let calendar = CalendarSourceOptions(rawValue: sections[section]) {
            headerView.nameLabel.text = calendar.name
            headerView.accountImageView.image = calendar.image
            if calendar.name == primaryCalendar {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
//                headerView.infoLabel.text = "External Calendar Account"
                let tap = TapGesture(target: self, action: #selector(updatePrimaryCalendar(_:)))
                tap.item = section
                headerView.addGestureRecognizer(tap)
            } else if calendar.name == "Plot" {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
//                headerView.infoLabel.text = "Internal Calendar Account"
            } else {
                headerView.statusImageView.image =  .none
//                headerView.infoLabel.text = "External Calendar Account"
                let tap = TapGesture(target: self, action: #selector(updatePrimaryCalendar(_:)))
                tap.item = section
                headerView.addGestureRecognizer(tap)
            }
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        let section = sections[indexPath.section]
        let calendarsSorted = calendars[section]?.sorted()
        cell.textLabel?.text = calendarsSorted?[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let calendarsSorted = calendars[section]?.sorted()
        if let calendar = calendarsSorted?[indexPath.row] {
            calendarInfo(calendar: calendar)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func calendarInfo(calendar: CalendarType) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        navigationController?.pushViewController(destination, animated: true)
    }
        
    @objc func updatePrimaryCalendar(_ sender: TapGesture) {
        let section = sender.item
        networkController.activityService.updatePrimaryCalendarFB(value: sections[section])
        tableView.reloadData()
    }
}

extension CalendarInfoViewController: UpdateWithGoogleAppleSignInDelegate {
    func UpdateWithGoogleAppleSignIn() {
        sections = Array(calendars.keys).sorted { s1, s2 in
            if s1 == ListSourceOptions.plot.name {
                return true
            } else if s2 == ListSourceOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
        self.tableView.reloadData()
    }
}
