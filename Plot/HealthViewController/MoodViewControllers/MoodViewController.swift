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
            let original = Date()
            let rounded = Date(timeIntervalSinceReferenceDate:
            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
            let timezone = TimeZone.current
            let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
            let date = rounded.addingTimeInterval(seconds)
            mood = Mood(id: ID, mood: nil, applicableTo: .specificTime, moodDate: date, lastModifiedDate: date, createdDate: date)
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
        if let currentUser = Auth.auth().currentUser?.uid {
            self.showActivityIndicator()
            let createMood = MoodActions(mood: mood, active: active, currentUser: currentUser)
            createMood.createNewMood()
            self.hideActivityIndicator()
            
            if active {
                self.navigationController?.popViewController(animated: true)
            } else {
                let nav = self.tabBarController!.viewControllers![1] as! UINavigationController
                if nav.topViewController is MasterActivityContainerController {
                    let homeTab = nav.topViewController as! MasterActivityContainerController
                    homeTab.customSegmented.setIndex(index: 2)
                    homeTab.changeToIndex(index: 2)
                }
                self.tabBarController?.selectedIndex = 1
                if #available(iOS 13.0, *) {
                    self.navigationController?.backToViewController(viewController: DiscoverViewController.self)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
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
        form +++
            SelectableSection<ListCheckRow<String>>(nil, selectionType: .singleSelection(enableDeselection: false))
            
            <<< DateTimeInlineRow("Time") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.dateFormatter?.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
                        cell.datePicker.timeZone = NSTimeZone(name: "UTC") as TimeZone?
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
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange({ (row) in
                    if let value = row.value {
                        self.mood.mood = MoodType(rawValue: value)
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                })
        }
        
        form.last!
            <<< TextAreaRow("Notes") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                $0.cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                $0.value = mood.notes
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    cell.textView?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.placeholderLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                }).onChange() { [weak self] row in
                    self!.mood.notes = row.value
                }
        
    }
    
}
