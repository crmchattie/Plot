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
        navigationController?.navigationBar.prefersLargeTitles = false
        
        tableView.separatorStyle = .none
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: switchCellID)
    }
    
    //  override func numberOfSections(in tableView: UITableView) -> Int {
    //    return 1
    //  }
    //
    //  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //    return 55
    //  }
    //
    //  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    //    return 100
    //  }
}
