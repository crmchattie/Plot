//
//  SwitchTableViewController.swift
//  FalconMessenger
//
//  Created by Roman Mizin on 8/17/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class SwitchTableViewController: UITableViewController {
    let switchCellID = "switchCellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureController()
    }
    
    fileprivate func configureController() {
        navigationItem.largeTitleDisplayMode = .never
        
        tableView = UITableView(frame: view.frame, style: .insetGrouped)
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = .systemGroupedBackground
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: switchCellID)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}
