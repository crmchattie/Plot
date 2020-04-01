//
//  FilterViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

protocol UpdateFilter: class {
    func updateFilter(filterDictionary : [String: [String]])
}


class FilterViewController: FormViewController {
          
    weak var delegate : UpdateFilter?
    
    var filters = [filter]()
    
    var filterDictionary = [String: [String]]()
    
    let chevronUpBlack: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
        return imageView
    }()
    
    let chevronDownBlack: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "chevronRightBlack")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ThemeManager.currentTheme().generalTitleColor
        return imageView
    }()
                
    override func viewDidLoad() {
    super.viewDidLoad()
        
        configureTableView()
        initializeForm()
        
    }

  
//    @objc fileprivate func changeTheme() {
//        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
//        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
//        tableView.sectionIndexBackgroundColor = view.backgroundColor
//        tableView.backgroundColor = view.backgroundColor
//        tableView.reloadData()
//    }


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
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelFilter))

        let rightBarButton = UIButton(type: .system)
        rightBarButton.setTitle("Update", for: .normal)
        rightBarButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        rightBarButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rightBarButton.addTarget(self, action: #selector(closeFilter), for: .touchUpInside)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Update Filters"
    }
    
    @objc fileprivate func cancelFilter() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func closeFilter() {
        delegate?.updateFilter(filterDictionary: filterDictionary)
        dismiss(animated: true, completion: nil)
    }
    
    func initializeForm() {
        
        for filter in filters {
            if filter.typeOfSection == "single" {
                form +++ SelectableSection<ListCheckRow<String>>(filter.descriptionText, selectionType: .singleSelection(enableDeselection: true))
                    <<< CheckRow(filter.rawValue) {
                    $0.title = filter.titleText
                    $0.value = false
                    $0.cell.accessoryView = UIImageView(image: UIImage(named: "chevronDownBlack")!.withRenderingMode(.alwaysTemplate))
                    $0.cell.accessoryView?.tintColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                    $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }.cellUpdate({ (cell, row) in
                        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    }).onCellSelection({ (cell, row) in
                        let name = row.value! ? "chevronUpBlack" : "chevronDownBlack"
                        cell.accessoryView = UIImageView(image: UIImage(named: name)!.withRenderingMode(.alwaysTemplate))
                        cell.accessoryView?.tintColor = ThemeManager.currentTheme().generalTitleColor
                        row.updateCell()
                    })
                for choice in filter.choices {
                    form.last! <<< ListCheckRow<String>("\(choice)_\(filter.rawValue)"){ row in
                        row.title = choice
                        row.selectableValue = choice
                        row.hidden = .function([filter.rawValue], { form -> Bool in
                            let row: RowOf<Bool>! = form.rowBy(tag: filter.rawValue)
                            return row.value ?? false == false
                        })
                        }.cellSetup { (cell, row) in
                            if self.filterDictionary.keys.contains(filter.rawValue), let choiceList = self.filterDictionary[filter.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                row.value = choice
                            }
                            cell.accessoryType = .checkmark
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        }.onChange({ row in
                            if let rowTag = row.tag, let index = rowTag.firstIndex(of: "_") {
                                let choice = String(rowTag[...rowTag.index(index, offsetBy: -1)])
                                let filter = String(rowTag[rowTag.index(index, offsetBy: 1)...])
                                if row.value != nil {
                                    print("single choice list is not empty")
                                    self.filterDictionary[filter] = [choice]
                                } else {
                                    self.filterDictionary[filter] = nil
                                }
                            }
                            print(self.filterDictionary)
                        })
                }
        } else {
            form +++ SelectableSection<ListCheckRow<String>>(filter.descriptionText, selectionType: .multipleSelection)
                <<< CheckRow(filter.rawValue) {
                        $0.title = filter.titleText
                        $0.value = false
                        $0.cell.accessoryView = UIImageView(image: UIImage(named: "chevronDownBlack")!.withRenderingMode(.alwaysTemplate))
                        $0.cell.accessoryView?.tintColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                        $0.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        $0.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        }.cellUpdate({ (cell, row) in
                            cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                            cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                            cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        }).onCellSelection({ (cell, row) in
                            let name = row.value! ? "chevronUpBlack" : "chevronDownBlack"
                            cell.accessoryView = UIImageView(image: UIImage(named: name)!.withRenderingMode(.alwaysTemplate))
                            cell.accessoryView?.tintColor = ThemeManager.currentTheme().generalTitleColor
                            row.updateCell()
                        })
                    for choice in filter.choices {
                        form.last! <<< ListCheckRow<String>("\(choice)_\(filter.rawValue)"){ row in
                            row.title = choice
                            row.selectableValue = choice
                            row.value = nil
                            row.hidden = .function([filter.rawValue], { form -> Bool in
                                let row: RowOf<Bool>! = form.rowBy(tag: filter.rawValue)
                                return row.value ?? false == false
                            })
                            }.cellSetup { (cell, row) in
                                if self.filterDictionary.keys.contains(filter.rawValue), let choiceList = self.filterDictionary[filter.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                    row.value = choice
                                }
                                cell.accessoryType = .checkmark
                                cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
                                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                        }.onChange({ row in
                            if let rowTag = row.tag, let index = rowTag.firstIndex(of: "_") {
                                let choice = String(rowTag[...rowTag.index(index, offsetBy: -1)])
                                let filter = String(rowTag[rowTag.index(index, offsetBy: 1)...])
                                if row.value != nil {
                                    if var choiceList = self.filterDictionary[filter], !choiceList.isEmpty {
                                        if choiceList.contains(choice) {
                                            return
                                        } else {
                                            choiceList.append(choice)
                                            self.filterDictionary[filter] = choiceList
                                        }
                                    } else {
                                        self.filterDictionary[filter] = [choice]
                                    }
                                } else {
                                    if var choiceList = self.filterDictionary[filter], let indexChoice = choiceList.firstIndex(of: choice), choiceList.count > 1 {
                                        print("multiple choice list is not empty")
                                        choiceList.remove(at: indexChoice)
                                        self.filterDictionary[filter] = choiceList
                                    } else {
                                        self.filterDictionary[filter] = nil
                                    }
                                }
                            }
                            print(self.filterDictionary)
                        })
                    }
                }
            }
        }
}

