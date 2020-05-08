//
//  ChecklistViewController.swift
//  Plot
//
//  Created by Cory McHattie on 4/30/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow

protocol UpdateChecklistDelegate: class {
    func updateChecklist(checklist: Checklist)
}

class ChecklistViewController: FormViewController {
          
    weak var delegate : UpdateChecklistDelegate?
        
    var checklist: Checklist!
    
    fileprivate var active: Bool = false
                
    override func viewDidLoad() {
    super.viewDidLoad()
        
        configureTableView()
        
        if checklist != nil {
            active = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            checklist = Checklist(dictionary: ["name" : "Checklist Name" as AnyObject])
        }
        
        initializeForm()
        
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelChecklist))

        let rightBarButton = UIButton(type: .system)
        rightBarButton.setTitle("Update", for: .normal)
        rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rightBarButton.addTarget(self, action: #selector(closeChecklist), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Checklist"
    }
    
    @objc fileprivate func cancelChecklist() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func closeChecklist() {
        delegate?.updateChecklist(checklist: checklist)
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func initializeForm() {
        form +++
        Section()
            
        <<< TextRow("Checklist Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let checklist = checklist {
                $0.value = checklist.name
                self.navigationItem.title = $0.value
            } else {
                $0.cell.textField.becomeFirstResponder()
            }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.checklist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.title = row.value
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        
        form +++
        MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder]) {
            $0.tag = "checklistfields"
            $0.addButtonProvider = { section in
                return ButtonRow(){
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.title = "Add New Item"
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textAlignment = .left
                        
                }
            }
            $0.multivaluedRowToInsertAt = { index in
                return SplitRow<TextRow, CheckRow>(){
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = TextRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.placeholder = "Item"
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = false
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    }.onChange() { _ in
                        self.updateLists()
                }
                
            }
            
        }
        
        if let items = self.checklist.items {
            for item in items {
                var mvs = (form.sectionBy(tag: "checklistfields") as! MultivaluedSection)
                mvs.insert(SplitRow<TextRow, CheckRow>() {
                    $0.rowLeftPercentage = 0.75
                    $0.rowLeft = TextRow(){
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                        $0.value = item.key
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                            row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                    }
                    $0.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = item.value
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                        }.cellUpdate { cell, row in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.tintColor = FalconPalette.defaultBlue
                            if row.value == false {
                                cell.accessoryType = .checkmark
                                cell.tintAdjustmentMode = .dimmed
                            } else {
                                cell.tintAdjustmentMode = .automatic
                            }
                    }
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    }.onChange() { _ in
                        self.updateLists()
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func updateLists() {
            if let mvs = (form.values()["checklistfields"] as? [Any?])?.compactMap({ $0 }) {
                if !mvs.isEmpty {
                    var checklistDict = [String : Bool]()
                    for element in mvs {
                        let value = element as! SplitRowValue<Swift.String, Swift.Bool>
                        if let text = value.left, let state = value.right {
                            checklistDict[text] = state
                        }
                    }
                    self.checklist.items = checklistDict
                } else {
                    self.checklist.items = nil
                }
            }
    }
}
