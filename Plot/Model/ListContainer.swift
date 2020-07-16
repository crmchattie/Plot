//
//  ListContainer.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation

struct ListContainer: Codable {
    
    var grocerylist: Grocerylist?
    var checklist: Checklist?
    var activitylist: Activitylist?
    var packinglist: Packinglist?

    var ID: String {
        return grocerylist?.ID ?? checklist?.ID ?? packinglist?.ID ?? activitylist?.ID ?? ""
    }
    
    var name: String {
        return grocerylist?.name ?? checklist?.name ?? packinglist?.name ?? activitylist?.name ?? ""
    }
    
    var lastModifiedDate: Date {
        return grocerylist?.lastModifiedDate ?? checklist?.lastModifiedDate ?? packinglist?.lastModifiedDate ?? activitylist?.lastModifiedDate ?? Date.distantPast
    }
    
    var createdDate: Date {
        return grocerylist?.createdDate ?? checklist?.createdDate ?? packinglist?.createdDate ?? activitylist?.createdDate ?? Date.distantPast
    }
    
    var badge: Int {
        return grocerylist?.badge ?? checklist?.badge ?? packinglist?.badge ?? activitylist?.badge ?? 0
    }
    
    var muted: Bool {
        return grocerylist?.muted ?? checklist?.muted ?? packinglist?.muted ?? activitylist?.muted ?? false
    }
    
    var pinned: Bool {
        return grocerylist?.pinned ?? checklist?.pinned ?? packinglist?.pinned ?? activitylist?.pinned ?? false
    }
    
    var type: String {
        if grocerylist != nil {
            return "grocerylist"
        } else if checklist != nil {
            return "checklist"
        } else if packinglist != nil {
            return "packinglist"
        } else if activitylist != nil {
            return "activitylist"
        } else {
            return "none"
        }
    }

}

func ==(lhs: ListContainer, rhs: ListContainer) -> Bool {
    return lhs.grocerylist == rhs.grocerylist && lhs.checklist == rhs.checklist && lhs.packinglist == rhs.packinglist && lhs.activitylist == rhs.activitylist
}

