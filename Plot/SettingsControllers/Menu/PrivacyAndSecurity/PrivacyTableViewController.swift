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
    
    var privacyElements = [SwitchObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Privacy"

        createDataSource()
    }
    
    fileprivate func createDataSource() {
        let biometricsState = userDefaults.currentBoolObjectState(for: userDefaults.biometricalAuth)
        let biometricsObject = SwitchObject(Biometrics().title, subtitle: nil, state: biometricsState, defaultsKey: userDefaults.biometricalAuth)
        privacyElements.append(biometricsObject)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return privacyElements.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: switchCellID, for: indexPath) as? SwitchTableViewCell ?? SwitchTableViewCell()
        cell.currentViewController = self
        cell.setupCell(object: privacyElements[indexPath.row], index: indexPath.row)
        return cell        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SwitchTableViewCell {
            cell.switchAccessory.isOn = !cell.switchAccessory.isOn
            privacyElements[indexPath.row].state = cell.switchAccessory.isOn
        }
    }
}
