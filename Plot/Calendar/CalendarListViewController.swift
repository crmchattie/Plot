//
//  CalendarViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/28/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

protocol UpdateCalendarDelegate: AnyObject {
    func update(calendar: CalendarType)
}

class CalendarListViewController: FormViewController {
    weak var delegate : UpdateCalendarDelegate?
    
    var calendars = [CalendarType]()
    var calendar: CalendarType!
    var calendarID: String?
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Calendars"
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        activityIndicatorView.startAnimating()
        configureTableView()
        grabCalendars()
    }
    
    fileprivate func grabCalendars() {
        form.removeAll()
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
                
        let group = DispatchGroup()
        let ref = Database.database().reference()
        
        group.enter()
        Database.database().reference().child(userCalendarEntity).child(currentUserID).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists(), let calendarIDs = snapshot.value as? [String: AnyObject] {
                for (calendarID, userCalendarInfo) in calendarIDs {
                    if let userCalendar = try? FirebaseDecoder().decode(CalendarType.self, from: userCalendarInfo) {
                        group.enter()
                        ref.child(calendarEntity).child(calendarID).observeSingleEvent(of: .value, with: { snapshot in
                            if snapshot.exists(), let snapshotValue = snapshot.value {
                                if let calendar = try? FirebaseDecoder().decode(CalendarType.self, from: snapshotValue) {
                                    var _calendar = calendar
                                    _calendar.color = userCalendar.color
                                    self.calendars.append(_calendar)
                                }
                            }
                            group.leave()
                        })
                    }
                }
            } else {
                self.calendars = prebuiltCalendars
//                for calendar in prebuiltCalendars {
//
//                }
            }
            group.leave()
        })
        
        DispatchQueue.main.async {
          activityIndicatorView.stopAnimating()
          self.initializeForm()
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
        
        let barButton = UIBarButtonItem(title: "New Category", style: .plain, target: self, action: #selector(newCategory))
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func newCategory(_ item:UIBarButtonItem) {
        let destination = CalendarDetailViewController()
//        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        form +++ SelectableSection<ListCheckRow<String>>("Category", selectionType: .singleSelection(enableDeselection: false))
        
        for index in 0...calendars.count - 1 {
            form.last!
                <<< ListCheckRow<String>() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = calendars[index].name
                    $0.selectableValue = calendars[index].name
                    if let calendarID = self.calendarID, calendars[index].id == calendarID {
                        $0.value = calendars[index].name
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange({ (row) in
                    self.delegate?.update(calendar: self.calendars[index])
                    self.navigationController?.popViewController(animated: true)
                })
        }
        
    }
    
}

extension CalendarListViewController: CalendarDetailDelegate {
    func update() {
        grabCalendars()
    }
}
