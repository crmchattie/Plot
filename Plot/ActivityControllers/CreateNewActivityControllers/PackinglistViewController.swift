//
//  PackingListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/2/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow

protocol UpdatePackinglistDelegate: class {
    func updatePackinglist(packinglist: Packinglist)
}

class PackinglistViewController: FormViewController {
    weak var delegate : UpdatePackinglistDelegate?
          
    var packinglist: Packinglist!

    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var weather: [DailyWeatherElement]!
    var startDateTime: Date?
    var endDateTime: Date?
              
    override func viewDidLoad() {
        super.viewDidLoad()
      
        configureTableView()

        if packinglist != nil {
            active = true
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            packinglist = Packinglist(dictionary: ["name" : "PackingListName" as AnyObject])
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        initializeForm()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards {
            delegate?.updatePackinglist(packinglist: packinglist)
        }
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Packing List"
    }

    @objc fileprivate func close() {
        movingBackwards = false
        delegate?.updatePackinglist(packinglist: packinglist)
        self.navigationController?.popViewController(animated: true)
    }

    func initializeForm() {
        form +++
        Section()
            
        <<< TextRow("Name") {
            $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
            $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            $0.placeholder = $0.tag
            if active, let packinglist = packinglist {
                $0.value = packinglist.name
            } else {
                $0.cell.textField.becomeFirstResponder()
            }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.packinglist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
            }
    }
    
    fileprivate func weatherRow() {
        if let weather = self.weather {
            print("updating weather row")
            var section = self.form.allSections[0]
            if let locationRow: ButtonRow = self.form.rowBy(tag: "Packing List Name"), let index = locationRow.indexPath?.item {
                section.insert(WeatherRow("Weather") { row in
                        row.value = weather
                        row.reload()
                    }, at: index+1)
            }
        } else if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let index = weatherRow.indexPath?.item {
            let section = self.form.allSections[0]
            section.remove(at: index)
        }
    }
}
