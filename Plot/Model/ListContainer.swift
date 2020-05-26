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

}

func ==(lhs: ListContainer, rhs: ListContainer) -> Bool {
    return lhs.grocerylist == rhs.grocerylist && lhs.checklist == rhs.checklist && lhs.packinglist == rhs.packinglist
}

