//
//  ChangeBirthday.swift
//  Plot
//
//  Created by Cory McHattie on 3/13/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import Eureka

protocol ChangeBirthdayDelegate: AnyObject {
    func update(birthday: Date)
}

class ChangeBirthdayController: FormViewController {
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var birthday = Date()
    weak var delegate : ChangeBirthdayDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(leftBarButtonDidTap))
        navigationItem.leftBarButtonItem = leftBarButton
        initializeForm()

    }
    
    @objc func leftBarButtonDidTap() {
        self.dismiss(animated: true)
    }
    
    func initializeForm() {
        form +++
        Section()
        
        <<< ButtonRow() { row in
            row.cell.backgroundColor = .systemGroupedBackground
            row.cell.textLabel?.textAlignment = .center
            row.cell.textLabel?.textColor = .label
            row.cell.textLabel?.font = UIFont.title1.with(weight: .bold)
            row.title = "Birthday"
            row.cell.isUserInteractionEnabled = false
        }.cellUpdate({ (cell, row) in
            cell.backgroundColor = .systemGroupedBackground
            cell.textLabel?.textColor = .label
        })
        
        form +++
        
        Section(footer: "We use your age to give you more accurate goals and benchmarks")
        
        <<< DatePickerRow(){
            $0.value = birthday
            $0.cell.datePicker.tintColor = .systemBlue
            if #available(iOS 14.0, *) {
                $0.cell.datePicker.preferredDatePickerStyle = .wheels
            }
        }.onChange({ row in
            self.birthday = row.value ?? self.birthday
        })
        
        form +++
        Section()
        
        <<< ButtonRow(){ row in
            row.cell.backgroundColor = .systemBlue
            row.cell.textLabel?.textAlignment = .center
            row.cell.textLabel?.textColor = .white
            row.cell.accessoryType = .none
            row.cell.textLabel?.font = UIFont.title3.with(weight: .semibold)
            row.title = "Done"
        }.onCellSelection({ _,_ in
            if let currentUser = Auth.auth().currentUser?.uid {
                let reference = Database.database().reference().child("users").child(currentUser).child("age")
                reference.setValue(NSNumber(value: Int((self.birthday).timeIntervalSince1970)))
            }
            self.delegate?.update(birthday: self.birthday)
            self.dismiss(animated: true)
        }).cellUpdate({ (cell, row) in
            cell.backgroundColor = .systemBlue
            cell.textLabel?.textColor = .white
        })
    }
}
