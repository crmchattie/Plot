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
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.rightBarButtonItem = barButton
        
        sections = Array(calendars.keys).sorted { s1, s2 in
            if s1 == CalendarSourceOptions.plot.name {
                return true
            } else if s2 == CalendarSourceOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(calendarsUpdated), name: .calendarsUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func calendarsUpdated() {
        sections = Array(calendars.keys).sorted { s1, s2 in
            if s1 == CalendarSourceOptions.plot.name {
                return true
            } else if s2 == CalendarSourceOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
        tableView.reloadData()
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyCalendars, subtitle: .emptyCalendars, priority: .medium, position: .top)
    }
    
    @objc fileprivate func newItem() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Plot Calendar", style: .default, handler: { (_) in
            let destination = CalendarDetailViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }))
        
        if !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.apple.name) || !networkController.activityService.calendars.keys.contains(CalendarSourceOptions.google.name) {
            alert.addAction(UIAlertAction(title: "External Calendar", style: .default, handler: { (_) in
                let destination = SignInAppleGoogleViewController()
                destination.networkController = self.networkController
                destination.title = "Calendars"
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = .label
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
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
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
