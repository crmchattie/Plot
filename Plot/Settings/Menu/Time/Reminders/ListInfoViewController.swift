//
//  ListInfoViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/30/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit

class ListInfoViewController: UITableViewController {
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
        
        title = "Lists Information"
        
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        
        let barButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.rightBarButtonItem = barButton
        
        sections = Array(lists.keys).sorted { s1, s2 in
            if s1 == ListSourceOptions.plot.name {
                return true
            } else if s2 == ListSourceOptions.plot.name {
                return false
            }
            return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
        }
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(listsUpdated), name: .listsUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func listsUpdated() {
        sections = Array(lists.keys).sorted { s1, s2 in
            if s1 == ListSourceOptions.plot.name {
                return true
            } else if s2 == ListSourceOptions.plot.name {
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
        viewPlaceholder.add(for: tableView, title: .emptyLists, subtitle: .emptyLists, priority: .medium, position: .top)
    }
    
    @objc fileprivate func newItem() {
        if !networkController.activityService.lists.keys.contains(ListSourceOptions.apple.name) || !networkController.activityService.lists.keys.contains(ListSourceOptions.google.name) {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "External List", style: .default, handler: { (_) in
                let destination = SignInAppleGoogleViewController(networkController: self.networkController)
                destination.networkController = self.networkController
                destination.title = "Lists"
                destination.delegate = self
                self.navigationController?.pushViewController(destination, animated: true)
            }))
                        
            alert.addAction(UIAlertAction(title: "Plot List", style: .default, handler: { (_) in
                let destination = ListDetailViewController(networkController: self.networkController)
                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                destination.navigationItem.leftBarButtonItem = cancelBarButton
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                print("User click Dismiss button")
            }))
            
            self.present(alert, animated: true, completion: {
                print("completion block")
            })
            
        } else {
            let destination = ListDetailViewController(networkController: self.networkController)
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
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
        let headerView = ListAccountView()
        if let list = ListSourceOptions(rawValue: sections[section]) {
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
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textColor = .label
        let section = sections[indexPath.section]
        let listSorted = lists[section]?.sorted()
        cell.textLabel?.text = listSorted?[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let listSorted = lists[section]?.sorted()
        if let list = listSorted?[indexPath.row] {
            listInfo(list: list)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    fileprivate func listInfo(list: ListType) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
        
    @objc func updatePrimaryList(_ sender: TapGesture) {
        let section = sender.item
        networkController.activityService.updatePrimaryListFB(value: sections[section])
        tableView.reloadData()
    }
}

extension ListInfoViewController: UpdateWithGoogleAppleSignInDelegate {
    func UpdateWithGoogleAppleSignIn() {
        for (key, _) in lists {
            print(key)
        }
        sections = Array(lists.keys).sorted { s1, s2 in
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
