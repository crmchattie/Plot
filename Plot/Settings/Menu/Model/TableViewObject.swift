//
//  TableViewObject.swift
//  Plot
//
//  Created by Cory McHattie on 8/26/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit

class TableViewObject: NSObject {
    var icon: UIImage?
    var title: String?
    
    init(icon: UIImage?, title: String?) {
        super.init()
        self.icon = icon
        self.title = title
    }
}
