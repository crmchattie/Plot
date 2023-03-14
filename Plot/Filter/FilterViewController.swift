//
//  FilterViewController.swift
//  Plot
//
//  Created by Cory McHattie on 1/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateFilter: AnyObject {
    func updateFilter(filterDictionary : [String: [String]])
}


class FilterViewController: FormViewController {
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
          
    weak var delegate : UpdateFilter?
    
    var filters = [filter]()
    
    var filterDictionary = [String: [String]]()
                
    override func viewDidLoad() {
    super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
                
        configureTableView()
        initializeForm()
        fetchData()
        
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }

    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
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
        navigationOptions = .Disabled
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
            if filter.typeOfSection == .single {
                form +++ SelectableSection<ListCheckRow<String>>(filter.descriptionText, selectionType: .singleSelection(enableDeselection: true))
                    <<< CheckRow(filter.rawValue) {
                    $0.title = filter.titleText
                    $0.value = false
                    $0.cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.down"))
                    $0.cell.accessoryView?.tintColor = .label
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    }.cellUpdate({ (cell, row) in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .secondaryLabel
                    }).onCellSelection({ (cell, row) in
                        let name = row.value! ? "chevron.up" : "chevron.down"
                        cell.accessoryView = UIImageView(image: UIImage(systemName: name))
                        cell.accessoryView?.tintColor = .label
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
                            print("filter.rawValue \(filter.rawValue)")
                            if let choiceList = self.filterDictionary[filter.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                row.value = choice
                            }
                            cell.accessoryType = .checkmark
                            cell.backgroundColor = .secondarySystemGroupedBackground
                            cell.textLabel?.textColor = .label
                            cell.detailTextLabel?.textColor = .secondaryLabel
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
            } else if filter.typeOfSection == .multiple {
                form +++ SelectableSection<ListCheckRow<String>>(filter.descriptionText, selectionType: .multipleSelection)
                    <<< CheckRow(filter.rawValue) {
                        $0.title = filter.titleText
                        $0.value = false
                        $0.cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.down"))
                        $0.cell.accessoryView?.tintColor = .label
                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                        $0.cell.textLabel?.textColor = .label
                        $0.cell.detailTextLabel?.textColor = .secondaryLabel
                        }.cellUpdate({ (cell, row) in
                            cell.backgroundColor = .secondarySystemGroupedBackground
                            cell.textLabel?.textColor = .label
                            cell.detailTextLabel?.textColor = .secondaryLabel
                        }).onCellSelection({ (cell, row) in
                            let name = row.value! ? "chevron.up" : "chevron.down"
                            cell.accessoryView = UIImageView(image: UIImage(systemName: name))
                            cell.accessoryView?.tintColor = .label
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
                                if let choiceList = self.filterDictionary[filter.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                    row.value = choice
                                }
                                cell.accessoryType = .checkmark
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.detailTextLabel?.textColor = .secondaryLabel
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
            } else if filter.typeOfSection == .input {
                form +++ Section(filter.descriptionText)
                <<< LabelRow("\(filter.rawValue)") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = .secondaryLabel
                row.cell.accessoryType = .disclosureIndicator
                row.cell.selectionStyle = .default
                row.title = filter.titleText
                if row.tag == "location", let location = filterDictionary["location"] {
                    row.cell.accessoryType = .detailDisclosureButton
                    row.cell.textLabel?.textColor = .label
                    row.title = location[0]
                }
                }.onCellSelection({ _,row in
                    if row.tag == "location" {
                        self.openLocationFinder()
                    }
                }).cellUpdate { cell, row in
                    if row.tag == "location" {
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                        if row.title == "Location" {
                            cell.accessoryType = .disclosureIndicator
                            cell.textLabel?.textColor = .secondaryLabel
                        } else if let value = row.title, !value.isEmpty {
                            cell.accessoryType = .detailDisclosureButton
                            cell.textLabel?.textColor = .label
                        } else {
                            cell.accessoryType = .disclosureIndicator
                            cell.textLabel?.textColor = .secondaryLabel
                            cell.textLabel?.text = "Location"
                        }
                    }
                }
            } else if filter.typeOfSection == .date {
                form +++ Section(filter.descriptionText)
                <<< DateTimeInlineRow("\(filter.rawValue)") {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textLabel?.textColor = .label
                    $0.cell.detailTextLabel?.textColor = .secondaryLabel
                    $0.title = filter.titleText
                    $0.minuteInterval = 5
                    $0.dateFormatter?.dateStyle = .long
                    if filterDictionary["\(filter.rawValue)"] != nil, let value = filterDictionary["\(filter.rawValue)"], let date = value[0].toDate() {
                        $0.value = date
                        $0.updateCell()
                    } else {
                        $0.value = Date()
                        $0.updateCell()
                    }
                }.onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate { (cell, row) in
                        row.cell.backgroundColor = .secondarySystemGroupedBackground
                        row.cell.tintColor = .secondarySystemGroupedBackground
                        cell.datePicker.tintColor = .systemBlue
                        if #available(iOS 14.0, *) {
                            cell.datePicker.preferredDatePickerStyle = .inline
                        }
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                }.onChange { [weak self] row in
                    if (row.tag == "startDate" || row.tag == "endDate" || row.tag == "date"), let dateString = row.value?.toString(dateFormat: "YYYY-MM-dd'T'HH:mm:ss'Z'") {
                        self?.filterDictionary["\(filter.rawValue)"] = [dateString]
                    }
                }
            } else if filter.typeOfSection == .search {
                form +++ Section(filter.descriptionText)
                <<< TextRow("\(filter.rawValue)") {
                    $0.cell.backgroundColor = .secondarySystemGroupedBackground
                    $0.cell.textField?.textColor = .label
                    $0.placeholderColor = .secondaryLabel
                    $0.placeholder = $0.tag?.capitalized
                    if filterDictionary["\(filter.rawValue)"] != nil, let value = filterDictionary["\(filter.rawValue)"] {
                        $0.value = value[0]
                        $0.updateCell()
                    }
                    }.onChange() { [unowned self] row in
                        if let value = row.value {
                            self.filterDictionary["\(filter.rawValue)"] = [value]
                        } else {
                            self.filterDictionary["\(filter.rawValue)"] = nil
                        }
                    }
            }
        }
        
        form +++ Section()
            <<< ButtonRow("Restore Default Filters") { row in
                row.cell.backgroundColor = .systemBlue
                row.cell.textLabel?.textAlignment = .center
                row.cell.textLabel?.textColor = .white
                row.cell.accessoryType = .none
                row.title = row.tag
                }.onCellSelection({ _,_ in
                    self.filterDictionary = [String: [String]]()
                    self.form.removeAll()
                    self.initializeForm()
                }).cellUpdate({ (cell, row) in
                    cell.backgroundColor = .systemBlue
                    cell.textLabel?.textColor = .white
                })
    }
    
    func fetchData() {
        if filters.contains(.calendarCategory) {
            if let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference()
                let categories = ActivityCategory.allCases.map({ $0.rawValue }).sorted(by: >)
                if let row: CheckRow = self.form.rowBy(tag: filter.calendarCategory.rawValue), let sectionIndex = row.section?.index {
                    var section = self.form.allSections[sectionIndex]
                    categories.forEach {
                        let choice = $0
                        section.insert(
                            ListCheckRow<String>("\(choice)_\(filter.calendarCategory.rawValue)"){ row in
                                row.title = choice
                                row.selectableValue = choice
                                row.value = nil
                                row.hidden = .function([filter.calendarCategory.rawValue], { form -> Bool in
                                    let row: RowOf<Bool>! = form.rowBy(tag: filter.calendarCategory.rawValue)
                                    return row.value ?? false == false
                                })
                                }.cellSetup { (cell, row) in
                                    if self.filterDictionary.keys.contains(filter.calendarCategory.rawValue), let choiceList = self.filterDictionary[filter.calendarCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                        row.value = choice
                                    }
                                    cell.accessoryType = .checkmark
                                    cell.backgroundColor = .secondarySystemGroupedBackground
                                    cell.textLabel?.textColor = .label
                                    cell.detailTextLabel?.textColor = .secondaryLabel
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
                                            choiceList.remove(at: indexChoice)
                                            self.filterDictionary[filter] = choiceList
                                        } else {
                                            self.filterDictionary[filter] = nil
                                        }
                                    }
                                }
                            })
                            , at: section.count)
                    }
                }
                reference.child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let updatedCategories = Array(values.values).sorted(by: >)
                        if let row: CheckRow = self.form.rowBy(tag: filter.calendarCategory.rawValue), let sectionIndex = row.section?.index {
                            var section = self.form.allSections[sectionIndex]
                            updatedCategories.forEach {
                                let choice = $0
                                section.insert(
                                    ListCheckRow<String>("\(choice)_\(filter.calendarCategory.rawValue)"){ row in
                                        row.title = choice
                                        row.selectableValue = choice
                                        row.value = nil
                                        row.hidden = .function([filter.calendarCategory.rawValue], { form -> Bool in
                                            let row: RowOf<Bool>! = form.rowBy(tag: filter.calendarCategory.rawValue)
                                            return row.value ?? false == false
                                        })
                                        }.cellSetup { (cell, row) in
                                            if self.filterDictionary.keys.contains(filter.calendarCategory.rawValue), let choiceList = self.filterDictionary[filter.calendarCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                                row.value = choice
                                            }
                                            cell.accessoryType = .checkmark
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textColor = .label
                                            cell.detailTextLabel?.textColor = .secondaryLabel
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
                                                    choiceList.remove(at: indexChoice)
                                                    self.filterDictionary[filter] = choiceList
                                                } else {
                                                    self.filterDictionary[filter] = nil
                                                }
                                            }
                                        }
                                    })
                                    , at: section.count)
                            }
                        }
                    }
                })
            }
        }
        if filters.contains(.taskCategory) {
            if let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference()
                let categories = ActivityCategory.allCases.map({ $0.rawValue }).sorted(by: >)
                if let row: CheckRow = self.form.rowBy(tag: filter.taskCategory.rawValue), let sectionIndex = row.section?.index {
                    var section = self.form.allSections[sectionIndex]
                    categories.forEach {
                        let choice = $0
                        section.insert(
                            ListCheckRow<String>("\(choice)_\(filter.taskCategory.rawValue)"){ row in
                                row.title = choice
                                row.selectableValue = choice
                                row.value = nil
                                row.hidden = .function([filter.taskCategory.rawValue], { form -> Bool in
                                    let row: RowOf<Bool>! = form.rowBy(tag: filter.taskCategory.rawValue)
                                    return row.value ?? false == false
                                })
                                }.cellSetup { (cell, row) in
                                    if self.filterDictionary.keys.contains(filter.taskCategory.rawValue), let choiceList = self.filterDictionary[filter.taskCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                        row.value = choice
                                    }
                                    cell.accessoryType = .checkmark
                                    cell.backgroundColor = .secondarySystemGroupedBackground
                                    cell.textLabel?.textColor = .label
                                    cell.detailTextLabel?.textColor = .secondaryLabel
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
                                            choiceList.remove(at: indexChoice)
                                            self.filterDictionary[filter] = choiceList
                                        } else {
                                            self.filterDictionary[filter] = nil
                                        }
                                    }
                                }
                            })
                            , at: section.count)
                    }
                }
                reference.child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let updatedCategories = Array(values.values).sorted(by: >)
                        if let row: CheckRow = self.form.rowBy(tag: filter.taskCategory.rawValue), let sectionIndex = row.section?.index {
                            var section = self.form.allSections[sectionIndex]
                            updatedCategories.forEach {
                                let choice = $0
                                section.insert(
                                    ListCheckRow<String>("\(choice)_\(filter.taskCategory.rawValue)"){ row in
                                        row.title = choice
                                        row.selectableValue = choice
                                        row.value = nil
                                        row.hidden = .function([filter.taskCategory.rawValue], { form -> Bool in
                                            let row: RowOf<Bool>! = form.rowBy(tag: filter.taskCategory.rawValue)
                                            return row.value ?? false == false
                                        })
                                        }.cellSetup { (cell, row) in
                                            if self.filterDictionary.keys.contains(filter.taskCategory.rawValue), let choiceList = self.filterDictionary[filter.taskCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                                row.value = choice
                                            }
                                            cell.accessoryType = .checkmark
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textColor = .label
                                            cell.detailTextLabel?.textColor = .secondaryLabel
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
                                                    choiceList.remove(at: indexChoice)
                                                    self.filterDictionary[filter] = choiceList
                                                } else {
                                                    self.filterDictionary[filter] = nil
                                                }
                                            }
                                        }
                                    })
                                    , at: section.count)
                            }
                        }
                    }
                })
            }
        }
        if filters.contains(.goalCategory) {
            if let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference()
                let categories = ActivityCategory.allCases.map({ $0.rawValue }).sorted(by: >)
                if let row: CheckRow = self.form.rowBy(tag: filter.goalCategory.rawValue), let sectionIndex = row.section?.index {
                    var section = self.form.allSections[sectionIndex]
                    categories.forEach {
                        let choice = $0
                        section.insert(
                            ListCheckRow<String>("\(choice)_\(filter.goalCategory.rawValue)"){ row in
                                row.title = choice
                                row.selectableValue = choice
                                row.value = nil
                                row.hidden = .function([filter.goalCategory.rawValue], { form -> Bool in
                                    let row: RowOf<Bool>! = form.rowBy(tag: filter.goalCategory.rawValue)
                                    return row.value ?? false == false
                                })
                                }.cellSetup { (cell, row) in
                                    if self.filterDictionary.keys.contains(filter.goalCategory.rawValue), let choiceList = self.filterDictionary[filter.goalCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                        row.value = choice
                                    }
                                    cell.accessoryType = .checkmark
                                    cell.backgroundColor = .secondarySystemGroupedBackground
                                    cell.textLabel?.textColor = .label
                                    cell.detailTextLabel?.textColor = .secondaryLabel
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
                                            choiceList.remove(at: indexChoice)
                                            self.filterDictionary[filter] = choiceList
                                        } else {
                                            self.filterDictionary[filter] = nil
                                        }
                                    }
                                }
                            })
                            , at: section.count)
                    }
                }
                reference.child(userActivityCategoriesEntity).child(currentUser).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists(), let values = snapshot.value as? [String: String] {
                        let updatedCategories = Array(values.values).sorted(by: >)
                        if let row: CheckRow = self.form.rowBy(tag: filter.goalCategory.rawValue), let sectionIndex = row.section?.index {
                            var section = self.form.allSections[sectionIndex]
                            updatedCategories.forEach {
                                let choice = $0
                                section.insert(
                                    ListCheckRow<String>("\(choice)_\(filter.goalCategory.rawValue)"){ row in
                                        row.title = choice
                                        row.selectableValue = choice
                                        row.value = nil
                                        row.hidden = .function([filter.goalCategory.rawValue], { form -> Bool in
                                            let row: RowOf<Bool>! = form.rowBy(tag: filter.goalCategory.rawValue)
                                            return row.value ?? false == false
                                        })
                                        }.cellSetup { (cell, row) in
                                            if self.filterDictionary.keys.contains(filter.goalCategory.rawValue), let choiceList = self.filterDictionary[filter.goalCategory.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                                row.value = choice
                                            }
                                            cell.accessoryType = .checkmark
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textColor = .label
                                            cell.detailTextLabel?.textColor = .secondaryLabel
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
                                                    choiceList.remove(at: indexChoice)
                                                    self.filterDictionary[filter] = choiceList
                                                } else {
                                                    self.filterDictionary[filter] = nil
                                                }
                                            }
                                        }
                                    })
                                    , at: section.count)
                            }
                        }
                    }
                })
            }
        }
        if filters.contains(.financeAccount) {
            let accounts = networkController.financeService.accounts.sorted { (account1, account2) -> Bool in
                return account1.name > account2.name
            }
            if let row: CheckRow = self.form.rowBy(tag: filter.financeAccount.rawValue), let sectionIndex = row.section?.index {
                var section = self.form.allSections[sectionIndex]
                accounts.forEach {
                    let choice = $0.name
                    let guid = $0.guid
                    section.insert(
                        ListCheckRow<String>("\(guid)_\(filter.financeAccount.rawValue)"){ row in
                            row.title = choice
                            row.selectableValue = choice
                            row.value = nil
                            row.hidden = .function([filter.financeAccount.rawValue], { form -> Bool in
                                let row: RowOf<Bool>! = form.rowBy(tag: filter.financeAccount.rawValue)
                                return row.value ?? false == false
                            })
                            }.cellSetup { (cell, row) in
                                if self.filterDictionary.keys.contains(filter.financeAccount.rawValue), let choiceList = self.filterDictionary[filter.financeAccount.rawValue], let _ = choiceList.firstIndex(of: guid) {
                                    row.value = choice
                                }
                                cell.accessoryType = .checkmark
                                cell.backgroundColor = .secondarySystemGroupedBackground
                                cell.textLabel?.textColor = .label
                                cell.detailTextLabel?.textColor = .secondaryLabel
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
                                        choiceList.remove(at: indexChoice)
                                        self.filterDictionary[filter] = choiceList
                                    } else {
                                        self.filterDictionary[filter] = nil
                                    }
                                }
                            }
                        })
                        , at: section.count)
                }
            }

        }
    }
    
    @objc fileprivate func openLocationFinder() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = LocationFinderTableViewController()
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
//        let navigationViewController = UINavigationController(rootViewController: destination)
//        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    @objc(tableView:accessoryButtonTappedForRowWithIndexPath:) func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
            
        let alertController = UIAlertController(title: filterDictionary["location"]![0], message: nil, preferredStyle: .alert)
        let removeAddress = UIAlertAction(title: "Remove Address", style: .default) { (action:UIAlertAction) in
            if let locationRow: LabelRow = self.form.rowBy(tag: "location") {
                self.filterDictionary["lat"] = nil
                self.filterDictionary["lon"] = nil
                self.filterDictionary["zipcode"] = nil
                self.filterDictionary["city"] = nil
                self.filterDictionary["state"] = nil
                self.filterDictionary["country"] = nil
                self.filterDictionary["location"] = nil
                locationRow.title = "Location"
                locationRow.updateCell()
            }
        }
        let cancelAlert = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("You've pressed cancel")
            
        }
        alertController.addAction(removeAddress)
        alertController.addAction(cancelAlert)
        self.present(alertController, animated: true, completion: nil)
    }
        
}


extension FilterViewController: UpdateLocationDelegate {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String) {
        if let locationRow: LabelRow = form.rowBy(tag: "location") {
            if locationName != "" {
                for (_, value) in locationAddress {
                    filterDictionary["lat"] = [String(value[0])]
                    filterDictionary["lon"] = [String(value[1])]
                }
                filterDictionary["zipcode"] = [zipcode]
                filterDictionary["city"] = [city]
                filterDictionary["state"] = [state]
                filterDictionary["country"] = [country]
                filterDictionary["location"] = [locationName]
                locationRow.title = locationName
            } else {
                filterDictionary["lat"] = nil
                filterDictionary["lon"] = nil
                filterDictionary["zipcode"] = nil
                filterDictionary["city"] = nil
                filterDictionary["state"] = nil
                filterDictionary["country"] = nil
                filterDictionary["location"] = nil
                locationRow.title = "Location"
            }
            locationRow.updateCell()
        }
    }
}

