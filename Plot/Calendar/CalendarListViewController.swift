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
    
    var calendarFetcher = CalendarFetcher()
    
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
        configureTableView()
        initializeForm()
    }
    
    fileprivate func grabCalendars() {
        form.removeAll()
        activityIndicatorView.startAnimating()
        calendarFetcher.fetchCalendar { calendars in
            self.calendars = calendars.sorted()
            DispatchQueue.main.async {
              self.initializeForm()
            }
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
        
        let barButton = UIBarButtonItem(title: "New Calendar", style: .plain, target: self, action: #selector(newCategory))
        navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func newCategory(_ item:UIBarButtonItem) {
        let destination = CalendarDetailViewController()
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        activityIndicatorView.stopAnimating()
        form +++ SelectableSection<ListCheckRow<String>>("Calendar", selectionType: .singleSelection(enableDeselection: false))
        
        for calendar in calendars {
            form.last!
                <<< ListCheckRow<String>() {
                    $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    $0.cell.tintColor = FalconPalette.defaultBlue
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.title = calendar.name
                    $0.selectableValue = calendar.name
                    if let calendarID = self.calendarID, calendar.id == calendarID {
                        $0.value = calendar.name
                    }
                }.cellSetup { cell, row in
                    cell.accessoryType = .checkmark
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.tintColor = FalconPalette.defaultBlue
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                }.onChange({ (row) in
                    if let _ = row.value {
                        self.delegate?.update(calendar: calendar)
                        self.navigationController?.popViewController(animated: true)
                    }
                })
        }
        
    }
    
}

extension CalendarListViewController: CalendarDetailDelegate {
    func update() {
        grabCalendars()
    }
}
