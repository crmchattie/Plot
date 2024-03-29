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
    var activity: Activity!
        
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Checklists"
        setupMainView()
        initializeForm()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if navigationController?.visibleViewController is ChecklistViewController ||
            navigationController?.visibleViewController is GrocerylistViewController ||
            navigationController?.visibleViewController is ActivityListViewController ||
            navigationController?.visibleViewController is PackinglistViewController {
            return
        }
        delegate?.updateActivityList(listList: listList)
    }
    
    fileprivate func setupMainView() {
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.sectionIndexBackgroundColor = view.backgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        extendedLayoutIncludesOpaqueBars = true
        navigationOptions = .Disabled
    }
    
    fileprivate func initializeForm() {
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Checklists",
                               footer: "Add a checklist") {
                                $0.tag = "listsfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = .secondarySystemGroupedBackground
                                        $0.title = "Add New Checklist"
                                        }.cellUpdate { cell, row in
                                            cell.backgroundColor = .secondarySystemGroupedBackground
                                            cell.textLabel?.textAlignment = .left
                                            
                                    }
                                }
                $0.multivaluedRowToInsertAt = { index in
                    self.listIndex = index
                    self.openList()
                    return ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = "Checklist"
                    }.onCellSelection({ _,_ in
                        self.listIndex = index
                        self.openList()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.textColor = .label
                    }
                }
                                
        }
        
        for list in listList {
            if let groceryList = list.grocerylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = groceryList.name
                    self.grocerylistIndex = mvs.count - 1
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let checklist = list.checklist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = checklist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let activitylist = list.activitylist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = activitylist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: mvs.count - 1)
            } else if let packinglist = list.packinglist {
                var mvs = (form.sectionBy(tag: "listsfields") as! MultivaluedSection)
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    row.title = packinglist.name
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
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
            destination.activity = activity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let checklist = listList[listIndex].checklist {
            let destination = ChecklistViewController()
            destination.checklist = checklist
            destination.activity = activity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let activitylist = listList[listIndex].activitylist {
            let destination = ActivitylistViewController()
            destination.activitylist = activitylist
            destination.activity = activity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else if listList.indices.contains(listIndex), let packinglist = listList[listIndex].packinglist {
            let destination = PackinglistViewController()
            destination.packinglist = packinglist
            destination.activity = activity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        } else {
            let destination = ChecklistViewController()
            destination.activity = activity
            destination.delegate = self
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        let rowNumber : Int = indexes.first!.row
        let row = rows[0].self
        
        DispatchQueue.main.async { [weak self] in
            if row is ButtonRow, rows[0].title != "Add New Checklist" {
                if self!.listList.indices.contains(rowNumber) {
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
        var mvs = self.form.sectionBy(tag: "listsfields") as! MultivaluedSection
        if checklist.name != "CheckListName" {
            if mvs.allRows.count - 1 == listIndex {
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: listIndex)
            }
            let listRow = mvs.allRows[listIndex]
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
        else if mvs.allRows.count - 1 > listIndex {
            mvs.remove(at: listIndex)
        }
    }
}

extension ActivityListViewController: UpdateActivitylistDelegate {
    func updateActivitylist(activitylist: Activitylist) {
        var mvs = self.form.sectionBy(tag: "listsfields") as! MultivaluedSection
        if activitylist.name != "ActivityListName" {
            if mvs.allRows.count - 1 == listIndex {
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: listIndex)
            }
            let listRow = mvs.allRows[listIndex]
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
        else if mvs.allRows.count - 1 > listIndex {
            mvs.remove(at: listIndex)
        }
    }
}

extension ActivityListViewController: UpdatePackinglistDelegate {
    func updatePackinglist(packinglist: Packinglist) {
        var mvs = self.form.sectionBy(tag: "listsfields") as! MultivaluedSection
        if packinglist.name != "PackingListName" {
            if mvs.allRows.count - 1 == listIndex {
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: listIndex)
            }
            let listRow = mvs.allRows[listIndex]
            listRow.title = packinglist.name
            listRow.updateCell()
            if listList.indices.contains(listIndex) {
                listList[listIndex].packinglist = packinglist
            } else {
                var list = ListContainer()
                list.packinglist = packinglist
                listList.append(list)
            }
        }
        else if mvs.allRows.count - 1 > listIndex {
            mvs.remove(at: listIndex)
        }
    }
}

extension ActivityListViewController: UpdateGrocerylistDelegate {
    func updateGrocerylist(grocerylist: Grocerylist) {
        var mvs = self.form.sectionBy(tag: "listsfields") as! MultivaluedSection
        if grocerylist.name != "GroceryListName" {
            if mvs.allRows.count - 1 == listIndex {
                mvs.insert(ButtonRow() { row in
                    row.cell.backgroundColor = .secondarySystemGroupedBackground
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = .label
                    self.grocerylistIndex = listIndex
                }.onCellSelection({ cell, row in
                    self.listIndex = row.indexPath!.row
                    self.openList()
                }).cellUpdate { cell, row in
                    cell.backgroundColor = .secondarySystemGroupedBackground
                    cell.textLabel?.textColor = .label
                    cell.textLabel?.textAlignment = .left
                }, at: listIndex)
            }
            let listRow = mvs.allRows[listIndex]
            listRow.title = grocerylist.name
            listRow.updateCell()
            if listList.indices.contains(listIndex) {
                listList[listIndex].grocerylist = grocerylist
            } else {
                var list = ListContainer()
                list.grocerylist = grocerylist
                listList.append(list)
            }
        }
        else if mvs.allRows.count - 1 > listIndex {
            mvs.remove(at: listIndex)
        }
    }
}
