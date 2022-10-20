//
//  ChooseListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateListDelegate: AnyObject {
    func update(list: ListType)
}

class ChooseListViewController: FormViewController {
    weak var delegate : UpdateListDelegate?
    var networkController: NetworkController
    
    var lists = [String: [ListType]]() {
        didSet {
            sections = Array(lists.keys).sorted { s1, s2 in
                if s1 == ListSourceOptions.plot.name {
                    return true
                } else if s2 == ListSourceOptions.plot.name {
                    return false
                }
                return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
            }
        }
    }
    var sections = [String]()
    var list: ListType!
    var listID: String?
        
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Lists"
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        configureTableView()
        initializeForm()
        
        if lists.keys.contains(ListSourceOptions.apple.name) || lists.keys.contains(ListSourceOptions.google.name) {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate func grabLists() {
        DispatchQueue.main.async {
            self.form.removeAll()
            activityIndicatorView.startAnimating()
            self.initializeForm()
        }
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationOptions = .Disabled
        
        if lists.keys.contains(ListSourceOptions.plot.name) {
            let barButton = UIBarButtonItem(title: "New List", style: .plain, target: self, action: #selector(new))
            navigationItem.rightBarButtonItem = barButton
        }
    }
    
    @objc func new(_ item:UIBarButtonItem) {
        let destination = ListDetailViewController(networkController: networkController)
        destination.delegate = self
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        activityIndicatorView.stopAnimating()
        for section in sections {
            form +++ SelectableSection<ListCheckRow<String>>(section, selectionType: .singleSelection(enableDeselection: false))
            for list in lists[section]?.sorted(by: { $0.name ?? "" < $1.name ?? "" }) ?? [] {
                form.last!
                    <<< ListCheckRow<String>() {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.detailTextLabel?.textColor = .label
                        $0.title = list.name
                        $0.selectableValue = list.name
                        if let listID = self.listID, list.id == listID {
                            $0.value = list.name
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .label
                    }.onChange({ (row) in
                        if let _ = row.value {
                            self.delegate?.update(list: list)
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
            }
        }
        
    }
    
}

extension ChooseListViewController: UpdateListDelegate {
    func update(list: ListType) {
        lists[ListSourceOptions.plot.name, default: []].append(list)
        grabLists()
    }
}
