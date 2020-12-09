//
//  MoodViewController.swift
//  Plot
//
//  Created by Cory McHattie on 12/6/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

class MoodViewController: FormViewController {
    var mood: Mood!
    var oldValue = String()
    var value = String()
    
    var active: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mood"
        setupVariables()
        configureTableView()
        initializeForm()
        oldValue = value
    }
    
    fileprivate func setupVariables() {
        if mood == nil, let currentUser = Auth.auth().currentUser?.uid {
            active = false
            let ID = Database.database().reference().child(userMoodsEntity).child(currentUser).childByAutoId().key ?? ""
            mood = Mood(id: ID, mood: nil, applicableTo: .daily, moodDate: Date(), lastModifiedDate: Date(), createdDate: Date())
        }
    }
    
    fileprivate func configureTableView() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        definesPresentationContext = true
        
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
        navigationItem.rightBarButtonItem = addBarButton
        navigationItem.rightBarButtonItem?.isEnabled = active
    }
    
    @IBAction func create(_ sender: AnyObject) {
//        if transaction.user_created ?? false, !active {
//            self.showActivityIndicator()
//            let createTransaction = TransactionActions(transaction: self.transaction, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
//            createTransaction.createNewTransaction()
//            self.hideActivityIndicator()
//        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }

    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    fileprivate func initializeForm() {
        form +++ Section()
        
        <<< DateTimeInlineRow("Time") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.title = $0.tag
            $0.minuteInterval = 5
            $0.dateFormatter?.dateStyle = .full
            $0.dateFormatter?.timeStyle = .short
            $0.value = mood.moodDate
            }.onChange { [weak self] row in
                self!.mood.moodDate = row.value
            }.onExpandInlineRow { cell, row, inlineRow in
                inlineRow.cellUpdate() { cell, row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    row.cell.tintColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.datePicker.datePickerMode = .dateAndTime
                    if #available(iOS 13.4, *) {
                        cell.datePicker.preferredDatePickerStyle = .wheels
                    }
                }
                let color = cell.detailTextLabel?.textColor
                row.onCollapseInlineRow { cell, _, _ in
                    cell.detailTextLabel?.textColor = color
                }
                cell.detailTextLabel?.textColor = cell.tintColor
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
            }
            
        
        form +++ SelectableSection<ListCheckRow<String>>("Mood", selectionType: .singleSelection(enableDeselection: false))
        
        MoodType.allCases.forEach { mood in
            form.last!
                <<< ListCheckRow<String>() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = mood.rawValue.capitalized
                    $0.cell.imageView?.image = UIImage(named: mood.image)
                    $0.selectableValue = mood.rawValue.capitalized
                    if mood.rawValue.capitalized == self.value {
                        $0.value = self.value
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange({ (row) in
                    if let value = row.value {
                        self.value = value
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                })
        }
        
    }
    
}
