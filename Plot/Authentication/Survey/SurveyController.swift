//
//  SurveyController.swift
//  Plot
//
//  Created by Cory McHattie on 3/13/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import Eureka

class SurveyController: FormViewController {
    init(survey: Survey, surveyAnswers: [String: [String]], networkController: NetworkController) {
        self.survey = survey
        self.surveyAnswers = surveyAnswers
        self.networkController = networkController
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let survey: Survey!
    var surveyAnswers = [String: [String]]()
    let networkController: NetworkController

    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = false
        edgesForExtendedLayout = []
        view.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        initializeForm()
    }
    
    @objc func nextButtonDidTap() {
        if let currentUser = Auth.auth().currentUser?.uid {
            let reference = Database.database().reference().child("users").child(currentUser).child("survey").child(self.survey.rawValue)
            reference.setValue(self.surveyAnswers)
        }
    }
    
    func initializeForm() {
        form +++
        Section()
        
        <<< ButtonRow() { row in
            row.cell.backgroundColor = .systemGroupedBackground
            row.cell.textLabel?.textAlignment = .center
            row.cell.textLabel?.textColor = .label
            row.cell.textLabel?.font = UIFont.title1.with(weight: .bold)
            row.cell.textLabel?.numberOfLines = 0
            row.title = survey.question
            row.cell.isUserInteractionEnabled = false
        }.cellUpdate({ (cell, row) in
            cell.backgroundColor = .systemGroupedBackground
            cell.textLabel?.textColor = .label
        })
        
        if survey.typeOfSection == .single {
            form +++ SelectableSection<ListCheckRow<String>>(header: nil, footer: survey.questionReason, selectionType: .singleSelection(enableDeselection: false))
            for choice in survey.choices {
                form.last! <<< ListCheckRow<String>("\(choice)_\(survey.rawValue)"){ row in
                    row.title = choice
                    row.selectableValue = choice
                    }.cellSetup { (cell, row) in
                        if self.surveyAnswers.keys.contains(self.survey.rawValue), let choiceList = self.surveyAnswers[self.survey.rawValue], let _ = choiceList.firstIndex(of: choice) {
                            row.value = choice
                        }
                        cell.accessoryType = .checkmark
                        cell.backgroundColor = .secondarySystemGroupedBackground
                        cell.textLabel?.textColor = .label
                        cell.detailTextLabel?.textColor = .secondaryLabel
                    }.onChange({ row in
                        if let rowTag = row.tag, let index = rowTag.firstIndex(of: "_") {
                            let choice = String(rowTag[...rowTag.index(index, offsetBy: -1)])
                            let filter = String(rowTag[rowTag.index(index, offsetBy: 1)...])
                            if row.value != nil {
                                print("single choice list is not empty")
                                self.surveyAnswers[filter] = [choice]
                            } else {
                                self.surveyAnswers[filter] = nil
                            }
                        }
                        print(self.surveyAnswers)
                    })
            }
        } else if survey.typeOfSection == .multiple {
            form +++ SelectableSection<ListCheckRow<String>>(header: nil, footer: survey.questionReason, selectionType: .multipleSelection)
                for choice in survey.choices {
                    form.last! <<< ListCheckRow<String>("\(choice)_\(survey.rawValue)"){ row in
                        row.title = choice
                        row.selectableValue = choice
                        row.value = nil
                        }.cellSetup { (cell, row) in
                            if self.surveyAnswers.keys.contains(self.survey.rawValue), let choiceList = self.surveyAnswers[self.survey.rawValue], let _ = choiceList.firstIndex(of: choice) {
                                row.value = choice
                            }
                            cell.accessoryType = .checkmark
                            cell.backgroundColor = .secondarySystemGroupedBackground
                            cell.textLabel?.textColor = .label
                            cell.detailTextLabel?.textColor = .secondaryLabel
                    }.onChange({ row in
                        if let rowTag = row.tag, let index = rowTag.firstIndex(of: "_") {
                            let choice = String(rowTag[...rowTag.index(index, offsetBy: -1)])
                            let filter = String(rowTag[rowTag.index(index, offsetBy: 1)...])
                            if row.value != nil {
                                if var choiceList = self.surveyAnswers[filter], !choiceList.isEmpty {
                                    if choiceList.contains(choice) {
                                        return
                                    } else {
                                        choiceList.append(choice)
                                        self.surveyAnswers[filter] = choiceList
                                    }
                                } else {
                                    self.surveyAnswers[filter] = [choice]
                                }
                            } else {
                                if var choiceList = self.surveyAnswers[filter], let indexChoice = choiceList.firstIndex(of: choice), choiceList.count > 1 {
                                    print("multiple choice list is not empty")
                                    choiceList.remove(at: indexChoice)
                                    self.surveyAnswers[filter] = choiceList
                                } else {
                                    self.surveyAnswers[filter] = nil
                                }
                            }
                        }
                        print(self.surveyAnswers)
                    })
                }
        }
        
        form +++
        Section()
        
        <<< ButtonRow(){ row in
            row.cell.backgroundColor = .systemBlue
            row.cell.textLabel?.textAlignment = .center
            row.cell.textLabel?.textColor = .white
            row.cell.textLabel?.font = UIFont.title3.with(weight: .semibold)
            row.cell.accessoryType = .none
            row.title = "Continue"
        }.onCellSelection({ _,_ in
            self.nextButtonDidTap()
        }).cellUpdate({ (cell, row) in
            cell.backgroundColor = .systemBlue
            cell.textLabel?.textColor = .white
        })
    }
}
