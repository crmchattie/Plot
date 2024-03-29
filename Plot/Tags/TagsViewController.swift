//
//  TagsViewController.swift
//  Plot
//
//  Created by Cory McHattie on 10/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateTagsDelegate: AnyObject {
    func updateTags(tags: [String]?)
}

class TagsViewController: FormViewController {
    var tags: [String]?
    
    var active: Bool = true
    
    weak var delegate : UpdateTagsDelegate?
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
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
        navigationItem.title = "Tags"
        navigationOptions = .Disabled
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        self.delegate?.updateTags(tags: tags)
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func initializeForm() {
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Tags",
                               footer: nil) {
                                $0.tag = "tagsfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = .secondarySystemGroupedBackground
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return TextRow() {
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.cell.textField?.textColor = .label
                                        $0.placeholderColor = .secondaryLabel
                                        $0.placeholder = "Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = .secondarySystemGroupedBackground
                                        cell.textField?.textColor = .label
                                        row.placeholderColor = .secondaryLabel
                                    }
                                }
        }
        
        if let items = tags {
            for item in items {
                var mvs = (form.sectionBy(tag: "tagsfields") as! MultivaluedSection)
                mvs.insert(TextRow(){
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textField?.textColor = .label
                    $0.placeholderColor = .secondaryLabel
                    $0.value = item
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textField?.textColor = .label
                    row.placeholderColor = .secondaryLabel
                } , at: mvs.count - 1)
            }
        }
    }
}
