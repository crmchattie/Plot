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

class ChooseCalendarViewController: FormViewController {
    weak var delegate : UpdateCalendarDelegate?
    
    var networkController: NetworkController
    
    var calendars = [String: [CalendarType]]() {
        didSet {
            sections = Array(calendars.keys).sorted { s1, s2 in
                if s1 == CalendarSourceOptions.plot.name {
                    return true
                } else if s2 == CalendarSourceOptions.plot.name {
                    return false
                }
                return s1.localizedStandardCompare(s2) == ComparisonResult.orderedAscending
            }
        }
    }
    var sections = [String]()
    var calendar: CalendarType!
    var calendarID: String?
    
    var calendarFetcher = CalendarFetcher()
    
    init(networkController: NetworkController) {
        self.networkController = networkController
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
        
        if calendars.keys.contains(CalendarSourceOptions.apple.name) || calendars.keys.contains(CalendarSourceOptions.google.name) {
            for row in form.rows {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate func grabCalendars() {
        DispatchQueue.main.async {
            self.form.removeAll()
            activityIndicatorView.startAnimating()
            self.initializeForm()
        }
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
        navigationOptions = .Disabled
        
        if calendars.keys.contains(CalendarSourceOptions.plot.name) {
            let barButton = UIBarButtonItem(title: "New Calendar", style: .plain, target: self, action: #selector(new))
            navigationItem.rightBarButtonItem = barButton
        }
    }
    
    @objc func new(_ item:UIBarButtonItem) {
        let destination = CalendarDetailViewController(networkController: networkController)
        destination.delegate = self
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    fileprivate func initializeForm() {
        activityIndicatorView.stopAnimating()
        for section in sections {
            form +++ SelectableSection<ListCheckRow<String>>(section, selectionType: .singleSelection(enableDeselection: false))
            for calendar in calendars[section]?.sorted(by: { $0.name ?? "" < $1.name ?? "" }) ?? [] {
                form.last!
                    <<< ListCheckRow<String>() {
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.detailTextLabel?.textColor = .label
                        $0.title = calendar.name
                        $0.selectableValue = calendar.name
                        if let calendarID = self.calendarID, calendar.id == calendarID {
                            $0.value = calendar.name
                        }
                    }.cellSetup { cell, row in
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.tintColor = FalconPalette.defaultBlue
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .label
                    }.onChange({ (row) in
                        if let _ = row.value {
                            self.delegate?.update(calendar: calendar)
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
            }
        }
        
    }
    
}

extension ChooseCalendarViewController: UpdateCalendarDelegate {
    func update(calendar: CalendarType) {
        calendars[CalendarSourceOptions.plot.name, default: []].append(calendar)
        grabCalendars()
    }
}
