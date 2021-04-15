//
//  ListService.swift
//  Plot
//
//  Created by Cory McHattie on 12/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

class ListService {
    let checklistFetcher = ChecklistFetcher()
    let activitylistFetcher = ActivitylistFetcher()
    let grocerylistFetcher = GrocerylistFetcher()
    
    var listList = [ListContainer]()
    var checklists = [Checklist]()
    var activitylists = [Activitylist]()
    var grocerylists = [Grocerylist]()
    
    func grabLists() {
        let dispatchGroup = DispatchGroup()
        DispatchQueue.main.async { [unowned self] in
            dispatchGroup.enter()
            checklistFetcher.fetchChecklists { (checklists) in
                for checklist in checklists {
                    if checklist.name == "nothing" { continue }
                    if let items = checklist.items, Array(items.keys)[0] == "name" { continue }
                    self.checklists.append(checklist)
                }
                self.observeChecklistsForCurrentUser()
                dispatchGroup.leave()
            }
            dispatchGroup.enter()
            activitylistFetcher.fetchActivitylists { (activitylists) in
                for activitylist in activitylists where activitylist.name != "nothing" {
                    if let items = activitylist.items, Array(items.keys)[0] == "name" { continue }
                    self.activitylists.append(activitylist)
                }
                self.observeActivitylistsForCurrentUser()
                dispatchGroup.leave()
            }
            dispatchGroup.enter()
            grocerylistFetcher.fetchGrocerylists { (grocerylists) in
                for grocerylist in grocerylists where grocerylist.name == "nothing" {
                    self.grocerylists.append(grocerylist)
                }
                self.observeGrocerylistsForCurrentUser()
                dispatchGroup.leave()
            }
            dispatchGroup.notify(queue: .main) {
                self.listList = (self.checklists.map { ListContainer(grocerylist: nil, checklist: $0, activitylist: nil, packinglist: nil) } + self.activitylists.map { ListContainer(grocerylist: nil, checklist: nil, activitylist: $0, packinglist: nil) } + self.grocerylists.map { ListContainer(grocerylist: $0, checklist: nil, activitylist: nil, packinglist: nil) }).sorted { $0.lastModifiedDate > $1.lastModifiedDate }
            }
        }
    }
    
    func observeChecklistsForCurrentUser() {
        self.checklistFetcher.observeChecklistForCurrentUser(checklistsAdded: { [weak self] checklistsAdded in
                for checklist in checklistsAdded {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists[index] = checklist
                    } else {
                        self!.checklists.append(checklist)
                    }
                }
            }, checklistsRemoved: { [weak self] checklistsRemoved in
                for checklist in checklistsRemoved {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists.remove(at: index)
                    }
                }
            }, checklistsChanged: { [weak self] checklistsChanged in
                for checklist in checklistsChanged {
                    if let index = self!.checklists.firstIndex(where: {$0 == checklist}) {
                        self!.checklists[index] = checklist
                    }
                }
            }
        )
    }
    
    func observeActivitylistsForCurrentUser() {
        self.activitylistFetcher.observeActivitylistForCurrentUser(activitylistsAdded: { [weak self] activitylistsAdded in
                for activitylist in activitylistsAdded {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists[index] = activitylist
                    } else {
                        self!.activitylists.append(activitylist)
                    }
                }
            }, activitylistsRemoved: { [weak self] activitylistsRemoved in
                for activitylist in activitylistsRemoved {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists.remove(at: index)
                    }
                }
            }, activitylistsChanged: { [weak self] activitylistsChanged in
                for activitylist in activitylistsChanged {
                    if let index = self!.activitylists.firstIndex(where: {$0 == activitylist}) {
                        self!.activitylists[index] = activitylist
                    }
                }
            }
        )
    }
    
    func observeGrocerylistsForCurrentUser() {
        self.grocerylistFetcher.observeGrocerylistForCurrentUser(grocerylistsAdded: { [weak self] grocerylistsAdded in
            for grocerylist in grocerylistsAdded {
                if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                    self!.grocerylists[index] = grocerylist
                } else {
                    self!.grocerylists.append(grocerylist)
                }
            }
            }, grocerylistsRemoved: { [weak self] grocerylistsRemoved in
                for grocerylist in grocerylistsRemoved {
                    if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                        self!.grocerylists.remove(at: index)
                    }
                }
            }, grocerylistsChanged: { [weak self] grocerylistsChanged in
                for grocerylist in grocerylistsChanged {
                    if let index = self!.grocerylists.firstIndex(where: {$0 == grocerylist}) {
                        self!.grocerylists[index] = grocerylist
                    }
                }
            }
        )
    }
}
