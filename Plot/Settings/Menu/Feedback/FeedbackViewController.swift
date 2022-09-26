//
//  FeedbackViewController.swift
//  Plot
//
//  Created by Cory McHattie on 9/23/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

class FeedbackViewController: FormViewController {
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        configureTableView()
        initializeForm()
    }

    fileprivate func configureTableView() {
        navigationItem.title = "Feedback"
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        definesPresentationContext = true

        view.backgroundColor = .systemGroupedBackground
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        navigationOptions = .Disabled
        
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissView))
        navigationItem.leftBarButtonItem = cancelBarButton
        
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sendFeedback() {
        if let row: TextAreaRow = self.form.rowBy(tag: "Feedback"), let value = row.value, let currentUserID = Auth.auth().currentUser?.uid {
            let ID = Database.database().reference().child(feedBackEntity).childByAutoId().key ?? ""
            let feedback = Feedback(id: ID, feedback: value, userID: currentUserID, createdDate: Date())

            let ref = Database.database().reference().child(feedBackEntity).child(ID)
            do {
                let value = try FirebaseEncoder().encode(feedback)
                ref.setValue(value)
            } catch let error {
                print(error)
            }
        }
        
        dismissView()
    }
    
    fileprivate func initializeForm() {
        form +++
        Section()
        <<< LabelRow("Name") {
            $0.cell.backgroundColor = .systemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.textLabel?.textAlignment = .center
            $0.cell.textLabel?.numberOfLines = 0
            $0.title = "Share your feedback with us via the form below. Tell us about what you like/dislike about Plot and/or new features you are looking for so we can make your experience even better!"
        }.cellUpdate { cell, row in
            cell.backgroundColor = .systemGroupedBackground
            cell.textLabel?.textColor = .label
        }
        
        form +++ Section()
        <<< TextAreaRow("Feedback") {
            $0.placeholder = $0.tag
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textView?.textColor = .label
            $0.cell.placeholderLabel?.textColor = .secondaryLabel
        }.cellUpdate({ (cell, row) in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textView?.backgroundColor = .secondarySystemGroupedBackground
            cell.textView?.textColor = .label
        })
        
        form +++ Section()
        <<< ButtonRow("Submit") { row in
            row.cell.backgroundColor = .systemBlue
            row.cell.textLabel?.textAlignment = .center
            row.cell.textLabel?.textColor = .white
            row.cell.accessoryType = .none
            row.title = row.tag
        }.onCellSelection({ _,_ in
            self.sendFeedback()
        }).cellUpdate({ (cell, row) in
            cell.backgroundColor = .systemBlue
            cell.textLabel?.textColor = .white
        })
        
    }
}
