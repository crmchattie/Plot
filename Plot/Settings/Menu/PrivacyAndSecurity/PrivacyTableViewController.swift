//
//  PrivacyTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


private let privacyTableViewCellID = "PrivacyTableViewCellID"

class PrivacyTableViewController: SwitchTableViewController {
    
    let accountSettingsCellId = "userProfileCell"
    
    var privacyElements = [SwitchObject]()
    var privacyPolicySection = [(icon: UIImage(named: "Privacy") , title: "Privacy Policy")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Privacy"
        tableView.register(AccountSettingsTableViewCell.self, forCellReuseIdentifier: accountSettingsCellId)

        createDataSource()
    }
    
    fileprivate func createDataSource() {
        let biometricsState = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        let biometricsObject = SwitchObject(Biometrics().title, subtitle: nil, state: biometricsState, defaultsKey: userDefaults.biometricalAuth)
        privacyElements.append(biometricsObject)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return privacyElements.count
        } else {
            return privacyPolicySection.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellID, for: indexPath) as? SwitchTableViewCell ?? SwitchTableViewCell()
            cell.currentViewController = self
            cell.setupCell(object: privacyElements[indexPath.row], index: indexPath.row)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: accountSettingsCellId,
                                                     for: indexPath) as? AccountSettingsTableViewCell ?? AccountSettingsTableViewCell()
            cell.icon.image = privacyPolicySection[indexPath.row].icon
            cell.title.text = privacyPolicySection[indexPath.row].title
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let cell = tableView.cellForRow(at: indexPath) as? SwitchTableViewCell {
                cell.switchAccessory.isOn = !cell.switchAccessory.isOn
                privacyElements[indexPath.row].state = cell.switchAccessory.isOn
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
            let destination = WebViewController()
            destination.controllerTitle = "Privacy Policy"
            destination.urlString = "https://plotliving.com/privacy"
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}
