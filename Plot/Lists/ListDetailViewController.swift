//
//  ListDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/20/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol ListDetailDelegate: AnyObject {
    func update()
}

class ListDetailViewController: FormViewController {
    weak var delegate : ListDetailDelegate?
    
}

