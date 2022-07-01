//
//  FinanceTagsViewController.swift
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

class FinanceTagsViewController: FormViewController {
    var tags: [String]?
    var ID: String!
    var type: String!
    
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
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Tags"
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
        
    }
    
    @IBAction func create(_ sender: AnyObject) {
        self.updateTags()
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
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add New Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return TextRow() {
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                        $0.placeholder = "Tag"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                                        row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                                    }
                                }
        }
        
        if let items = tags {
            for item in items {
                var mvs = (form.sectionBy(tag: "tagsfields") as! MultivaluedSection)
                mvs.insert(TextRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    $0.value = item
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateTags() {
        if let mvs = (form.values()["tagsfields"] as? [Any?])?.compactMap({ $0 as? String }) {
            if !mvs.isEmpty {
                var tagsArray = [String]()
                for value in mvs {
                    tagsArray.append(value)
                }
                self.tags = tagsArray
            } else {
                self.tags = []
            }
            self.delegate?.updateTags(tags: tags)
            if let currentUser = Auth.auth().currentUser?.uid {
                if type == "transaction" {
                    let updatedTags = ["tags": self.tags as AnyObject]
                    Database.database().reference().child(userFinancialTransactionsEntity).child(currentUser).child(ID).updateChildValues(updatedTags)
                } else if type == "account" {
                    let updatedTags = ["tags": self.tags as AnyObject]
                    Database.database().reference().child(userFinancialAccountsEntity).child(currentUser).child(ID).updateChildValues(updatedTags)
                }
            }
        }
    }
    
}
