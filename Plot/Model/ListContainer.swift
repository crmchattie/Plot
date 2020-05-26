//
//  ListContainer.swift
//  Plot
//
//  Created by Cory McHattie on 5/20/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import CodableFirebase

struct ListContainer: Codable {
    
    var grocerylist: Grocerylist?
    var checklist: Checklist?
    var packinglist: Packinglist?

    var ID: String {
        return grocerylist?.ID ?? checklist?.ID ?? packinglist?.ID ?? ""
    }
    
    var lastModifiedDate: Date {
        return grocerylist?.lastModifiedDate ?? checklist?.lastModifiedDate ?? packinglist?.lastModifiedDate ?? Date.distantPast
    }
    
    var createdDate: Date {
        return grocerylist?.createdDate ?? checklist?.createdDate ?? packinglist?.createdDate ?? Date.distantPast
    }
    
    var badge: Int {
        return grocerylist?.badge ?? checklist?.badge ?? packinglist?.badge ?? 0
    }
    
    var muted: Bool {
        return grocerylist?.muted ?? checklist?.muted ?? packinglist?.muted ?? false
    }
    
    var pinned: Bool {
        return grocerylist?.pinned ?? checklist?.pinned ?? packinglist?.pinned ?? false
    }
    
    var type: String {
        if grocerylist != nil {
            return "grocerylist"
        } else if checklist != nil {
            return "checklist"
        } else if packinglist != nil {
            return "packinglist"
        } else {
            return "none"
        }
    }

}

func ==(lhs: ListContainer, rhs: ListContainer) -> Bool {
    return lhs.grocerylist == rhs.grocerylist && lhs.checklist == rhs.checklist && lhs.packinglist == rhs.packinglist
}

