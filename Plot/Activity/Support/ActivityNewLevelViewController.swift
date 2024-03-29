//
//  NewActivityCategoryViewController.swift
//  Plot
//
//  Created by Cory McHattie on 12/1/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol ActivityNewLevelDelegate: AnyObject {
    func update()
}

class ActivityNewLevelViewController: FormViewController {
    weak var delegate : ActivityNewLevelDelegate?
    var level = String()
    var name: String? = nil
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New \(level)"
        configureTableView()
        initializeForm()
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
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelBarButton
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
        navigationOptions = .Disabled
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let row: TextRow = self.form.rowBy(tag: "Name"), let value = row.value, let currentUser = Auth.auth().currentUser?.uid {
            if level == "Category" {
                Database.database().reference().child(userActivityCategoriesEntity).child(currentUser).child(value).setValue(value)
            } else if level == "Subcategory" {
                Database.database().reference().child(userActivitySubcategoriesEntity).child(currentUser).child(value).setValue(value)
            }
        }
        self.delegate?.update()
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++
            Section()
            <<< TextRow("Name") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textField?.textColor = .label
                $0.title = $0.tag
                if let name = name {
                    $0.value = name
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    //$0.cell.textField.becomeFirstResponder()
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .label
            }.onChange() { [unowned self] row in
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
    }
        
    
}
