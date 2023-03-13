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

protocol UpdateMoodDelegate: AnyObject {
    func updateMood(mood: Mood)
}

class MoodViewController: FormViewController {
    var mood: Mood!
    var container: Container!
    var oldValue = String()
    var value = String()
    
    lazy var users: [User] = networkController.userService.users
    lazy var filteredUsers: [User] = networkController.userService.users
    lazy var tasks: [Activity] = networkController.activityService.tasks
    lazy var events: [Activity] = networkController.activityService.events
    lazy var transactions: [Transaction] = networkController.financeService.transactions
    
    var selectedFalconUsers = [User]()
    var participants = [String : [User]]()
    
    //added for EventViewController
    var movingBackwards: Bool = false
    var active: Bool = false
    var sectionChanged: Bool = false
    
    weak var delegate : UpdateMoodDelegate?
    weak var updateDiscoverDelegate : UpdateDiscover?
    
    var template: Template!
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
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
        
        if mood != nil {
            active = true
            title = "Mood"
            if let type = mood.mood {
                value = type.rawValue
            }
        } else {
            title = "New Mood"
            active = false
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userMoodEntity).child(currentUserID).childByAutoId().key ?? ""
                if let template = template {
                    mood = Mood(fromTemplate: template)
                    mood.id = ID
                } else {
                    mood = Mood(id: ID, admin: currentUserID, lastModifiedDate: Date(), createdDate: Date(), moodDate: Date(), applicableTo: .specificTime)
                    //need to fix; sloppy code that is used to stop an event from being created
                    if let container = container {
                        mood.containerID = container.id
                    }
                }
            }
        }
        
        configureTableView()
        initializeForm()
        oldValue = value
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if movingBackwards {
            self.delegate?.updateMood(mood: mood)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
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
        
        if !active {
            let plusBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
            navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
        }
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }

        navigationItem.rightBarButtonItem?.isEnabled = active
        navigationOptions = .Disabled
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: AnyObject) {
        showActivityIndicator()
        let moodAction = MoodActions(mood: self.mood, active: self.active, selectedFalconUsers: selectedFalconUsers)
        moodAction.createNewMood()
        self.delegate?.updateMood(mood: mood)
        self.hideActivityIndicator()
        if let updateDiscoverDelegate = self.updateDiscoverDelegate {
            updateDiscoverDelegate.itemCreated(title: moodCreatedMessage)
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            if !active {
                basicAlert(title: moodCreatedMessage, message: nil, controller: self.navigationController?.presentingViewController)
            } else {
                basicAlert(title: moodUpdatedMessage, message: nil, controller: self.navigationController?.presentingViewController)
            }
        }
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete Mood", style: .default, handler: { (_) in
            self.delete()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    func delete() {
        let alert = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.showActivityIndicator()
            let moodAction = MoodActions(mood: self.mood, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
            moodAction.deleteMood()
            self.hideActivityIndicator()
            if self.navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
            basicAlert(title: moodDeletedMessage, message: nil, controller: self.navigationController?.presentingViewController)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
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
                $0.dateFormatter?.dateStyle = .medium
                $0.dateFormatter?.timeStyle = .short
                $0.value = mood.moodDate
                }.onChange { [weak self] row in
                    self!.mood.moodDate = row.value
                }.onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate() { cell, row in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.tintColor = .systemBlue
                        if #available(iOS 14.0, *) {
                            cell.datePicker.preferredDatePickerStyle = .inline
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
