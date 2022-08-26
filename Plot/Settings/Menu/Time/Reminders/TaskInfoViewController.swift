//
//  ListInfoViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class TaskInfoViewController: UITableViewController {
    var networkController = NetworkController()
    
    let viewPlaceholder = ViewPlaceholder()
    
    var primaryList: String {
        return networkController.activityService.primaryList
    }
    
    var lists: [String: [ListType]] {
        return networkController.activityService.lists
    }
    
    var sections = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        title = "Task Information"
        
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        if !networkController.activityService.lists.keys.contains(ListOptions.apple.name) || !networkController.activityService.lists.keys.contains(ListOptions.google.name) {
            let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newList))
            navigationItem.rightBarButtonItem = barButton

        }
        
        sections = Array(lists.keys).sorted { s1, s2 in
            if s1 == ListOptions.plot.name {
                return true
            } else if s2 == ListOptions.plot.name {
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
        viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .emptyLists, priority: .medium, position: .top)
    }
    
    @objc func newList() {
        let destination = SignInAppleGoogleViewController()
        destination.networkController = self.networkController
        destination.title = "Tasks"
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if lists.keys.count == 0 {
            checkIfThereAreAnyResults(isEmpty: true)
        } else {
            checkIfThereAreAnyResults(isEmpty: false)
        }
        return lists.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        return lists[section]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = TaskAccountView()
        if let list = ListOptions(rawValue: sections[section]) {
            headerView.nameLabel.text = list.name
            headerView.accountImageView.image = list.image
            if list.name == primaryList {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
//                headerView.infoLabel.text = "External List Account"
                let tap = TapGesture(target: self, action: #selector(updatePrimaryList(_:)))
                tap.item = section
                headerView.addGestureRecognizer(tap)
            } else if list.name == "Plot" {
                headerView.statusImageView.image =  UIImage(systemName: "checkmark")
//                headerView.infoLabel.text = "Internal List Account"
            } else {
                headerView.statusImageView.image =  .none
//                headerView.infoLabel.text = "External List Account"
                let tap = TapGesture(target: self, action: #selector(updatePrimaryList(_:)))
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
        cell.accessoryType = .none
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        let section = sections[indexPath.section]
        let listNames = lists[section]?.map({ $0.name ?? "" })
        cell.textLabel?.text = listNames?.sorted()[indexPath.row]
        cell.isUserInteractionEnabled = false
        return cell
    }
        
    @objc func updatePrimaryList(_ sender: TapGesture) {
        let section = sender.item
        networkController.activityService.updatePrimaryListFB(value: sections[section])
        tableView.reloadData()
    }
}

extension TaskInfoViewController: UpdateWithGoogleAppleSignInDelegate {
    func UpdateWithGoogleAppleSignIn() {
        for (key, _) in lists {
            print(key)
        }
        sections = Array(lists.keys).sorted { s1, s2 in
            if s1 == ListOptions.plot.name {
                return true
            } else if s2 == ListOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
        self.tableView.reloadData()
    }
}
