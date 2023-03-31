//
//  PromptViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/30/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import CodableFirebase

class PromptViewController: FormViewController {
    let networkController: NetworkController
    
    var prompt: String
    var promptDescription: String?
    var answer = String()
    
    init(networkController: NetworkController, prompt: String) {
        self.networkController = networkController
        self.prompt = prompt
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
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        configureTableView()
        askPrompt()
    }
    
    func askPrompt() {
        if let question = PromptQuestion(rawValue: prompt) {
            let prompt = Prompt(question: question, networkController: networkController)
            Service.shared.askPrompt(prompt: prompt.prompt) { json, err in
                if let json = json, let answer = json["res"] {
                    self.answer = answer
                } else {
                    self.answer = "An error ocurred. Please try again later"
                }
                DispatchQueue.main.async {
                    activityIndicatorView.stopAnimating()
                    self.initializeForm()
                }
            }
        }
    }

    fileprivate func configureTableView() {
        navigationItem.title = "Ask"
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        definesPresentationContext = true

        view.backgroundColor = .systemGroupedBackground
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none
        navigationOptions = .Disabled
        
        let cancelBarButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = cancelBarButton
            
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    fileprivate func initializeForm() {
        form +++
        Section()
//        <<< LabelRow("Prompt") {
//            $0.cell.backgroundColor = .systemGroupedBackground
//            $0.cell.textLabel?.textColor = .label
//            $0.cell.textLabel?.textAlignment = .center
//            $0.cell.textLabel?.numberOfLines = 0
//            $0.title = promptDescription ?? prompt
//        }.cellUpdate { cell, row in
//            cell.backgroundColor = .systemGroupedBackground
//            cell.textLabel?.textColor = .label
//        }
        
        <<< LabelRow("Answer") {
            $0.cell.backgroundColor = .systemGroupedBackground
            $0.cell.textLabel?.textColor = .label
            $0.cell.textLabel?.textAlignment = .center
            $0.cell.textLabel?.numberOfLines = 0
            $0.title = answer
        }.cellUpdate { cell, row in
            cell.backgroundColor = .systemGroupedBackground
            cell.textLabel?.textColor = .label
        }
    }
}
