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

let primaryCalendarKey = "primary-calendar"

class CalendarInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    let viewPlaceholder = ViewPlaceholder()
    
    var primaryCalendar: String {
        return networkController.activityService.primaryCalendar
    }
    
    var calendars: [String: [String]] {
        return networkController.activityService.calendars
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Calendar Information"
        
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        if !networkController.activityService.calendars.keys.contains(CalendarOptions.apple.name) || !networkController.activityService.calendars.keys.contains(CalendarOptions.google.name) {
            let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newCalendar))
            navigationItem.rightBarButtonItem = barButton
        }
        
        addObservers()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(activitiesUpdated), name: .activitiesUpdated, object: nil)
    }
    
    @objc fileprivate func activitiesUpdated() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func checkIfThereAreAnyResults(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyCalendars, subtitle: .emptyCalendars, priority: .medium, position: .top)
    }
    
    @objc func newCalendar() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !calendars.keys.contains(CalendarOptions.apple.name) {
            alert.addAction(UIAlertAction(title: CalendarOptions.apple.name, style: .default, handler: { (_) in
                self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.apple.name)
            }))
        }
        
        if !calendars.keys.contains(CalendarOptions.google.name) {
            alert.addAction(UIAlertAction(title: CalendarOptions.google.name, style: .default, handler: { (_) in
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
                GIDSignIn.sharedInstance()?.signIn()
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
        let sections = Array(calendars.keys)
        let section = sections[section]
        return calendars[section]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = CalendarAccountView()
        let sections = Array(calendars.keys).sorted { s1, s2 in
            if s1 == CalendarOptions.plot.name {
                return true
            } else if s2 == CalendarOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
        if let calendar = CalendarOptions(rawValue: sections[section]) {
            headerView.nameLabel.text = calendar.name
            headerView.accountImageView.image = calendar.image
            if calendar.name == primaryCalendar {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
                headerView.infoLabel.text = "External Calendar Account"
            } else if calendar.name == "Plot" {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
                headerView.infoLabel.text = "Internal Calendar Account"
            } else {
                headerView.statusImageView.image =  .none
                headerView.infoLabel.text = "External Calendar Account"
            }
            let tap = TapGesture(target: self, action: #selector(updatePrimaryCalendar(_:)))
            tap.item = section
            headerView.addGestureRecognizer(tap)
        }
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        let sections = Array(calendars.keys)
        let section = sections[indexPath.section]
        cell.textLabel?.text = calendars[section]?.sorted()[indexPath.row]
        cell.isUserInteractionEnabled = false
        return cell
    }
        
    @objc func updatePrimaryCalendar(_ sender: TapGesture) {
        let sections = Array(calendars.keys)
        let section = sender.item
        networkController.activityService.updatePrimaryCalendarFB(value: sections[section])
        tableView.reloadData()
    }
}

extension CalendarInfoViewController: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("signed in")
        if (error == nil) {
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.google.name)
        } else {
          print("\(error.localizedDescription)")
        }
    }
}
