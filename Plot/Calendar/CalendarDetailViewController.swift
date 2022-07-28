//
//  CalendarDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/28/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol CalendarDetailDelegate: AnyObject {
    func update()
}

class CalendarDetailViewController: FormViewController {
    weak var delegate : CalendarDetailDelegate?
    
}

