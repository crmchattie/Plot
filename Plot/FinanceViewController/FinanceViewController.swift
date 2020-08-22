//
//  FinanceViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

protocol HomeBaseFinance: class {
//    func sendLists(lists: [ListContainer])
}

class FinanceViewController: UIViewController {
    weak var delegate: HomeBaseFinance?
    
}
