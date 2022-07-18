//
//  RepeatViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/16/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateRepeatDelegate: AnyObject {
    func updateRepeat(repeat: EventRepeat)
}

class RepeatViewController: FormViewController {
    weak var delegate : UpdateRepeatDelegate?
    
    var repeatValue: EventRepeat = .Never
    
    var movingBackwards = true
    
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
        
        title = "Repeat"
        
        configureTableView()
        initializeForm()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateRepeat(repeat: repeatValue)
        }
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
        
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem = plusBarButton
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        self.delegate?.updateRepeat(repeat: repeatValue)
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<EventRepeat>>(nil, selectionType: .singleSelection(enableDeselection: false))
        
        for item in EventRepeat.allCases {
            guard item != .Custom else { continue }
            form.last!
                <<< ListCheckRow<EventRepeat>() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = item.description
                    $0.tag = item.description
                    $0.selectableValue = item
                    if item == repeatValue {
                        $0.value = repeatValue
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange({ (row) in
                    if let value = row.value {
                        if self.repeatValue == .Custom, let row: ButtonRow = self.form.rowBy(tag: "Custom") {
                            row.cell.accessoryType = .disclosureIndicator
                        }
                        self.repeatValue = value
                    }
                })
        }
        
        form +++
        Section()
        
        <<< ButtonRow("Custom") { row in
            row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            row.cell.textLabel?.textAlignment = .left
            row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            row.title = row.tag
            if repeatValue == .Custom {
                row.cell.accessoryType = .checkmark
            } else {
                row.cell.accessoryType = .disclosureIndicator
            }
            }.onCellSelection({ cell, row in
                self.openCustom()
                if let row: ListCheckRow<EventRepeat> = self.form.rowBy(tag: self.repeatValue.description) {
                    row.value = nil
                    row.updateCell()
                }
                self.repeatValue = .Custom
                cell.accessoryType = .checkmark
            }).cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.textLabel?.textAlignment = .left
                if self.repeatValue == .Custom {
                    row.cell.accessoryType = .checkmark
                } else {
                    row.cell.accessoryType = .disclosureIndicator
                }
            }
        
    }
    
    func openCustom() {
        let destination = CustomRepeatViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
}

extension RepeatViewController: UpdateCustomRepeatDelegate {
    func updateCustomRepeat(repeat: EventRepeat) {
        
    }
}
