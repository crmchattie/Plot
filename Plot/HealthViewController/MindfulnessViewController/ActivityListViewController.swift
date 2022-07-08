//
//  ActivityListViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 5/22/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import Contacts
import EventKit


protocol UpdateActivityListDelegate: AnyObject {
    func updateActivityList(listList: [ListContainer])
}

class ActivityListViewController: FormViewController {
    
    weak var delegate : UpdateActivityListDelegate?
    
    var listList: [ListContainer]!
    var listIndex: Int = 0
    var grocerylistIndex: Int = -1
        
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checklist"
        setupMainView()
        initializeForm()
        
    }
    
    fileprivate func setupMainView() {
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        extendedLayoutIncludesOpaqueBars = true
                
        let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(rightBarButtonTapped))
        navigationItem.rightBarButtonItem = plusBarButton
                
    }
    
    fileprivate func initializeForm() {
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete, .Reorder],
                               header: "Checklists",
                               footer: "Add a checklist") {
                                $0.tag = "listsfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add New Checklist"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                            cell.textLabel?.textAlignment = .left
                                            
                                    }
                                }
                $0.multivaluedRowToInsertAt = { index in
                    self.listIndex = index
                    self.openList()
                    return ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = "Checklist"
                    }.onCellSelection({ _,_ in
                        self.listIndex = index
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
                }
                                
        }
        
        for list in listList {
            if let groceryList = list.grocerylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = groceryList.name
                    self.grocerylistIndex = mvs.count - 1
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let checklist = list.checklist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = checklist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let activitylist = list.activitylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = activitylist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let packinglist = list.packinglist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    row.title = packinglist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            }
        }
    }
    
    @objc fileprivate func rightBarButtonTapped() {
        delegate?.updateActivityList(listList: listList)
        self.navigationController?.popViewController(animated: true)
    }
    
    func openList() {
        if listIndex == grocerylistIndex, let grocerylist = listList[listIndex].grocerylist {
            let destination = GrocerylistViewController()
            destination.grocerylist = grocerylist
            destination.delegate = self
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        } else if listList.indices.contains(listIndex), let checklist = listList[listIndex].checklist {
            let destination = ChecklistViewController()
            destination.checklist = checklist
            destination.delegate = self
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        } else if listList.indices.contains(listIndex), let activitylist = listList[listIndex].activitylist {
            let destination = ActivitylistViewController()
            destination.activitylist = activitylist
            destination.delegate = self
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        } else if listList.indices.contains(listIndex), let packinglist = listList[listIndex].packinglist {
            let destination = PackinglistViewController()
            destination.packinglist = packinglist
            destination.delegate = self
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        } else {
            let destination = ChecklistViewController()
            destination.delegate = self
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let rowType = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if rowType is ButtonRow, rows[0].title != "Add New Checklist" {
                if self!.listList.indices.contains(self!.listIndex) {
                    self!.listList.remove(at: rowNumber)
                }
                if rowNumber == self!.grocerylistIndex {
                    self!.grocerylistIndex = -1
                }
            }
        }
    }
}

extension ActivityListViewController: UpdateChecklistDelegate {
    func updateChecklist(checklist: Checklist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if checklist.name != "CheckListName" {
                listRow.baseValue = checklist
                listRow.title = checklist.name
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].checklist = checklist
                } else {
                    var list = ListContainer()
                    list.checklist = checklist
                    listList.append(list)
                }
            }
            else if mvs.allRows.count > 1 {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension ActivityListViewController: UpdateActivitylistDelegate {
    func updateActivitylist(activitylist: Activitylist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if activitylist.name != "ActivityListName" {
                listRow.baseValue = activitylist
                listRow.title = activitylist.name
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].activitylist = activitylist
                } else {
                    var list = ListContainer()
                    list.activitylist = activitylist
                    listList.append(list)
                }
            }
            else if mvs.allRows.count > 1 {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension ActivityListViewController: UpdatePackinglistDelegate {
    func updatePackinglist(packinglist: Packinglist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            let listRow = mvs.allRows[listIndex]
            if packinglist.name != "PackingListName" {
                listRow.title = packinglist.name
                listRow.baseValue = packinglist
                listRow.updateCell()
                if listList.indices.contains(listIndex) {
                    listList[listIndex].packinglist = packinglist
                } else {
                    var list = ListContainer()
                    list.packinglist = packinglist
                    listList.append(list)
                }
            } else if mvs.allRows.count > 1 {
                mvs.remove(at: listIndex)
            }
        }
    }
}

extension ActivityListViewController: UpdateGrocerylistDelegate {
    func updateGrocerylist(grocerylist: Grocerylist) {
        if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
            if grocerylist.name != "GroceryListName" {
                let listRow = mvs.allRows[grocerylistIndex]
                listRow.baseValue = grocerylist
                listRow.title = grocerylist.name
                listRow.updateCell()
                if listList.indices.contains(grocerylistIndex) {
                    listList[grocerylistIndex].grocerylist = grocerylist
                } else {
                    var list = ListContainer()
                    list.grocerylist = grocerylist
                    listList.append(list)
                }
            } else if mvs.allRows.count > 1 {
                mvs.remove(at: grocerylistIndex)
            }
        }
    }
}

extension ActivityListViewController: ChooseListDelegate {
    func chosenList(list: ListContainer) {
        if let checklist = list.checklist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if checklist.name != "CheckListName" {
                    listRow.baseValue = checklist
                    listRow.title = checklist.name
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].checklist = checklist
                    } else {
                        var list = ListContainer()
                        list.checklist = checklist
                        listList.append(list)
                    }
                }
                else if mvs.allRows.count > 1 {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let activitylist = list.activitylist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if activitylist.name != "ActivityListName" {
                    listRow.baseValue = activitylist
                    listRow.title = activitylist.name
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].activitylist = activitylist
                    } else {
                        var list = ListContainer()
                        list.activitylist = activitylist
                        listList.append(list)
                    }
                }
                else if mvs.allRows.count > 1 {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let grocerylist = list.grocerylist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if grocerylist.name != "GroceryListName" {
                    listRow.title = grocerylist.name
                    listRow.baseValue = grocerylist
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].grocerylist = grocerylist
                    } else {
                        var list = ListContainer()
                        list.grocerylist = grocerylist
                        listList.append(list)
                    }
                    grocerylistIndex = listIndex
                } else if mvs.allRows.count > 1 {
                    mvs.remove(at: listIndex)
                }
            }
        } else if let packinglist = list.packinglist {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection {
                let listRow = mvs.allRows[listIndex]
                if packinglist.name != "PackingListName" {
                    listRow.title = packinglist.name
                    listRow.baseValue = packinglist
                    listRow.updateCell()
                    if listList.indices.contains(listIndex) {
                        listList[listIndex].packinglist = packinglist
                    } else {
                        var list = ListContainer()
                        list.packinglist = packinglist
                        listList.append(list)
                    }
                } else if mvs.allRows.count > 1 {
                    mvs.remove(at: listIndex)
                }
            }
        } else {
            if let mvs = self.form.sectionBy(tag: "listsfields") as? MultivaluedSection, mvs.allRows.count > 1 {
                mvs.remove(at: listIndex)
            }
        }
    }
}
