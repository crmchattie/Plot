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
        
        setupVariables()
        configureTableView()
        initializeForm()
        oldValue = value
    }
    
    fileprivate func setupVariables() {
        if mood == nil, let currentUser = Auth.auth().currentUser?.uid {
            title = "New Mood"
            active = false
            let ID = Database.database().reference().child(userMoodsEntity).child(currentUser).childByAutoId().key ?? ""
            let original = Date()
            let rounded = Date(timeIntervalSinceReferenceDate:
            (original.timeIntervalSinceReferenceDate / 300.0).rounded(.toNearestOrEven) * 300.0)
            let timezone = TimeZone.current
            let seconds = TimeInterval(timezone.secondsFromGMT(for: Date()))
            let date = rounded.addingTimeInterval(seconds)
            mood = Mood(id: ID, mood: nil, applicableTo: .specificTime, moodDate: date, lastModifiedDate: date, createdDate: date)
        } else {
            title = "Mood"
        }
    }
    
    fileprivate func configureTableView() {
        view.backgroundColor = .systemGroupedBackground
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        definesPresentationContext = true
        
        if active {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
        } else {
            let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = addBarButton
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem?.action = #selector(cancel)
            }
        }
        navigationItem.rightBarButtonItem?.isEnabled = active
        navigationOptions = .Disabled
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        if let currentUser = Auth.auth().currentUser?.uid {
            self.showActivityIndicator()
            let createMood = MoodActions(mood: mood, active: active, currentUser: currentUser)
            createMood.createNewMood()
            self.hideActivityIndicator()
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
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
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textLabel?.textColor = .label
                $0.cell.detailTextLabel?.textColor = .secondaryLabel
                $0.title = $0.tag
                $0.minuteInterval = 5
                $0.dateFormatter?.dateStyle = .full
                $0.dateFormatter?.timeStyle = .short
                $0.value = mood.moodDate
                }.onChange { [weak self] row in
                    self!.mood.moodDate = row.value
                }.onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.datePickerMode = .dateAndTime
                        if #available(iOS 14.0, *) {
                            cell.datePicker.preferredDatePickerStyle = .inline
                            cell.datePicker.tintColor = .systemBlue
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
        
        MoodType.allCases.forEach { mood in
            form.last!
                <<< ListCheckRow<String>() {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .label
                    $0.title = mood.rawValue.capitalized
                    $0.cell.imageView?.image = UIImage(named: mood.image)
                    $0.selectableValue = mood.rawValue.capitalized
                    if mood.rawValue.capitalized == self.value {
                        $0.value = self.value
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = .label
                    cell.detailTextLabel?.textColor = .label
                }.onChange({ (row) in
                    if let value = row.value {
                        self.mood.mood = MoodType(rawValue: value)
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                    }
                })
        }
        
        form.last!
            <<< TextAreaRow("Notes") {
                $0.cell.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                $0.cell.textView?.textColor = .label
                $0.cell.placeholderLabel?.textColor = .secondaryLabel
                $0.placeholder = $0.tag
                $0.value = mood.notes
                }.cellUpdate({ (cell, row) in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textView?.backgroundColor = .secondarySystemGroupedBackground
                    cell.textView?.textColor = .label
                    cell.placeholderLabel?.textColor = .secondaryLabel
                }).onChange() { [weak self] row in
                    self!.mood.notes = row.value
                }
        
    }
    
}
