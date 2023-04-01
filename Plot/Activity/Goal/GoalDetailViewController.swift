//
//  MetricViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/6/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import Firebase

protocol UpdateGoalDelegate: AnyObject {
    func update(goal: Goal?, number: Int)
}

class GoalDetailViewController: FormViewController {
    weak var delegate : UpdateGoalDelegate?
    var goal: Goal?
    var goalOld: Goal?
    var number: Int = 0
    var active = false
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        active = goal != nil
        goalOld = goal
        self.title = active ? "Goal" : "New Goal"
        configureTableView()
        initializeForm()
        updateNumberRows()
        updateDescriptionRow()
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationOptions = .Disabled
        if !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
        } else if delegate != nil {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
            navigationItem.rightBarButtonItem = plusBarButton
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = active

    }
    
    @objc func create(_ item:UIBarButtonItem) {
        delegate?.update(goal: goal, number: number)
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    fileprivate func initializeForm() {
        form +++
        Section()
        
        <<< LabelRow("Description") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.cell.accessoryType = .none
            row.cell.selectionStyle = .none
            row.cell.textLabel?.numberOfLines = 0
            if let goal = goal, let description = goal.description {
                row.title = description
                row.hidden = false
            } else {
                row.hidden = true
            }
        }.cellUpdate { cell, row in
            cell.textLabel?.textAlignment = .left
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.accessoryType = .none
        }
        
        <<< PushRow<String>("Metric") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            row.options = GoalMetric.allValues
            if let goal = goal, let value = goal.metric {
                row.value = value.rawValue
            }
        }.onPresent { from, to in
            to.title = "Metrics"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.dismissOnSelection = true
            to.dismissOnChange = true
            to.enableDeselection = false
            to.selectableRowCellUpdate = { cell, row in
                to.tableView.separatorStyle = .none
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
        }.onChange { row in
            self.updateGoal(selectedGoalProperty: .metric, value: row.value)
        }
        
        <<< PushRow<String>("Submetric") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            row.options = []
            if let goal = goal {
                if let value = goal.submetric, let metric = goal.metric, metric.allValuesSubmetrics.count > 0 {
                    row.value = value.rawValue
                    row.options = metric.allValuesSubmetrics
                } else {
                    row.hidden = true
                }
            }
        }.onPresent { from, to in
            to.title = "Submetrics"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.dismissOnSelection = true
            to.dismissOnChange = true
            to.enableDeselection = false
            to.selectableRowCellUpdate = { cell, row in
                to.tableView.separatorStyle = .none
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            if let options = row.options, !options.isEmpty {
                cell.isUserInteractionEnabled = true
            } else {
                cell.isUserInteractionEnabled = false
            }
        }.onChange { row in
            self.updateGoal(selectedGoalProperty: .submetric, value: row.value)
        }
        
        <<< MultipleSelectorRow<String>("Option") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            row.options = []
            if let goal = goal, let _ = goal.metric, let options = goal.options() {
                row.options = options
                if let value = goal.option {
                    row.value = Set(value)
                }
            } else {
                row.hidden = true
            }
        }.onPresent { from, to in
            to.title = "Options"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.selectableRowCellUpdate = { cell, row in
                to.tableView.separatorStyle = .none
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            if let options = row.options, !options.isEmpty {
                cell.isUserInteractionEnabled = true
            } else {
                cell.isUserInteractionEnabled = false
            }
        }.onChange { row in
            if let value = row.value, value.isEmpty, let options = row.options {
                row.value = Set(arrayLiteral: options[0])
            } else if let value = row.value {
                if let _ = self.goal {
                    self.goal!.option = Array(value)
                }
                self.updateDescriptionRow()
            }
        }
        
        <<< PushRow<String>("Unit") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = row.tag
            row.options = []
            if let _ = self.goal, let metric = goal!.metric {
                row.options = metric.allValuesUnits
                if let value = goal!.unit {
                    row.value = value.rawValue
                } else if metric.allValuesUnits.count > 0 {
                    goal!.unit = GoalUnit(rawValue: metric.allValuesUnits[0])
                    row.value = metric.allValuesUnits[0]
                }
            }
        }.onPresent { from, to in
            to.title = "Units"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.dismissOnSelection = true
            to.dismissOnChange = true
            to.enableDeselection = false
            to.selectableRowCellUpdate = { cell, row in
                to.tableView.separatorStyle = .none
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
            if let options = row.options, !options.isEmpty {
                cell.isUserInteractionEnabled = true
            } else {
                cell.isUserInteractionEnabled = false
            }
        }.onChange { row in
            if let value = row.value, let updatedValue = GoalUnit(rawValue: value) {
                if let _ = self.goal {
                    if updatedValue == .percent, let number = self.goal!.targetNumber {
                        self.goal!.targetNumber = number / 100
                    }
                    self.goal!.unit = updatedValue
                }
                self.updateNumberRows()
                self.updateDescriptionRow()
            }
        }
        
        <<< DecimalRow("Target") {
            $0.cell.backgroundColor = .secondarySystemGroupedBackground
            $0.cell.textField?.textColor = .secondaryLabel
            $0.title = $0.tag
            if let goal = goal, let number = goal.targetNumber {
                $0.value = number
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textField?.textColor = .secondaryLabel
        }.onChange { row in
            if let _ = self.goal {
                self.goal!.targetNumber = row.value
            } else {
                self.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: nil, period: nil, targetNumber: row.value, currentNumber: nil, metricRelationship: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricRelationshipSecond: nil, metricsRelationshipType: nil)
            }
            self.updateDescriptionRow()
        }
        
        if active, let goal = goal, goal.currentNumber != nil {
            form.last!
            <<< DecimalRow("Current") { row in
                row.cell.backgroundColor = .secondarySystemGroupedBackground
                row.cell.textField?.textColor = .secondaryLabel
                row.cell.selectionStyle = .none
                row.cell.isUserInteractionEnabled = false
                row.title = row.tag
                if let number = goal.currentNumber {
                    row.value = number
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textField?.textColor = .secondaryLabel
            }
        }
        
        form.last!
        
        <<< PushRow<String>("metricRelationship") { row in
            row.cell.backgroundColor = .secondarySystemGroupedBackground
            row.cell.textLabel?.textColor = .label
            row.cell.detailTextLabel?.textColor = .secondaryLabel
            row.title = "Relationship"
            row.options = MetricsRelationshipType.moreLessValues
            if let goal = goal, let value = goal.metricRelationship {
                row.value = value.rawValue
            } else {
                row.value = MetricsRelationshipType.equalMore.rawValue
            }
        }.onPresent { from, to in
            to.title = "Relationship"
            to.extendedLayoutIncludesOpaqueBars = true
            to.tableViewStyle = .insetGrouped
            to.dismissOnSelection = true
            to.dismissOnChange = true
            to.enableDeselection = false
            to.selectableRowCellUpdate = { cell, row in
                to.tableView.separatorStyle = .none
                to.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
                to.tableView.backgroundColor = .systemGroupedBackground
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.textColor = .secondaryLabel
                to.form.last?.footer = HeaderFooterView(title: MetricRelationshipFooter)
            }
        }.cellUpdate { cell, row in
            cell.backgroundColor = .secondarySystemGroupedBackground
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.textColor = .secondaryLabel
        }.onChange { row in
            if let value = row.value, let type = MetricsRelationshipType(rawValue: value), let _ = self.goal {
                self.goal!.metricRelationship = type
            }
            self.updateDescriptionRow()
        }
    }
    
    func updateGoal(selectedGoalProperty: SelectedGoalProperty, value: String?) {
        if let unitRow : PushRow<String> = self.form.rowBy(tag: "Unit"), let submetricRow : PushRow<String> = self.form.rowBy(tag: "Submetric"), let optionRow : MultipleSelectorRow<String> = self.form.rowBy(tag: "Option"), let relationshipRow : PushRow<String> = self.form.rowBy(tag: "metricRelationship") {
            switch selectedGoalProperty {
            case .metric:
                if let value = value, let updatedValue = GoalMetric(rawValue: value) {
                    if let _ = goal {
                        goal!.metric = updatedValue
                    } else {
                        goal = Goal(name: nil, metric: updatedValue, submetric: nil, option: nil, unit: nil, period: nil, targetNumber: nil, currentNumber: nil, metricRelationship: MetricsRelationshipType.equalMore, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricRelationshipSecond: nil, metricsRelationshipType: nil)
                    }
                    
                    //units
                    if updatedValue.units.count > 0 {
                        goal!.unit = updatedValue.units[0]
                        unitRow.value = updatedValue.units[0].rawValue
                        unitRow.options = updatedValue.allValuesUnits
                    } else {
                        goal!.unit = nil
                        unitRow.value = nil
                    }
                    
                    //submetric
                    if updatedValue.submetrics.count > 0 {
                        submetricRow.hidden = false
                        submetricRow.evaluateHidden()
                        goal!.submetric = updatedValue.submetrics[0]
                        if submetricRow.value == updatedValue.submetrics[0].rawValue {
                            if let options = goal!.options() {
                                optionRow.value = Set(arrayLiteral: options[0])
                                optionRow.options = options
                                optionRow.hidden = false
                                optionRow.evaluateHidden()
                            } else {
                                goal!.option = nil
                                optionRow.hidden = true
                                optionRow.evaluateHidden()
                                optionRow.value = nil
                            }
                        } else {
                            submetricRow.value = updatedValue.submetrics[0].rawValue
                        }
                        submetricRow.options = updatedValue.allValuesSubmetrics
                    } else {
                        goal!.submetric = nil
                        submetricRow.hidden = true
                        submetricRow.evaluateHidden()
                        submetricRow.value = nil
                    }
                    
                    relationshipRow.hidden = false
                    relationshipRow.evaluateHidden()
                    
                }
            case .submetric:
                if let value = value, let updatedValue = GoalSubMetric(rawValue: value) {
                    if let _ = goal {
                        goal!.submetric = updatedValue
                    } else {
                        goal = Goal(name: nil, metric: nil, submetric: updatedValue, option: nil, unit: nil, period: nil, targetNumber: nil, currentNumber: nil, metricRelationship: nil, frequency: nil, metricSecond: nil, submetricSecond: nil, optionSecond: nil, unitSecond: nil, periodSecond: nil, targetNumberSecond: nil, currentNumberSecond: nil, metricRelationshipSecond: nil, metricsRelationshipType: nil)
                    }
                    if let options = goal!.options() {
                        optionRow.value = Set(arrayLiteral: options[0])
                        optionRow.options = options
                        optionRow.hidden = false
                        optionRow.evaluateHidden()
                    } else {
                        goal!.option = nil
                        optionRow.hidden = true
                        optionRow.evaluateHidden()
                        optionRow.value = nil
                    }
                } else {
                    goal!.option = nil
                    optionRow.hidden = true
                    optionRow.evaluateHidden()
                    optionRow.value = nil

                }
            case .unit, .option:
                break
            }
            updateDescriptionRow()
        }
    }
    
    func updateNumberRows() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        if let goal = goal, let unit = goal.unit {
            switch unit {
            case .calories:
                numberFormatter.numberStyle = .decimal
            case .count:
                numberFormatter.numberStyle = .decimal
            case .amount:
                numberFormatter.numberStyle = .currency
            case .percent:
                numberFormatter.numberStyle = .percent
            case .multiple:
                numberFormatter.numberStyle = .decimal
            case .minutes:
                numberFormatter.numberStyle = .decimal
            case .hours:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .days:
                numberFormatter.numberStyle = .decimal
                numberFormatter.maximumFractionDigits = 1
            case .level:
                numberFormatter.numberStyle = .decimal
            }
            if let targetRow : DecimalRow = self.form.rowBy(tag: "Target") {
                targetRow.formatter = numberFormatter
                if let value = goal.targetNumber {
                    targetRow.value = value
                }
                if let currentRow : DecimalRow = self.form.rowBy(tag: "Current") {
                    currentRow.formatter = numberFormatter
                    if let value = goal.currentNumber {
                        currentRow.value = value
                    }
                }
            }
        }
    }
    
    
    func updateDescriptionRow() {
        if let descriptionRow: LabelRow = self.form.rowBy(tag: "Description") {
            if let goal = goal, let description = goal.description {
                var updatedDescription = description
                if let secondaryDescription = goal.descriptionSecondary {
                    updatedDescription += secondaryDescription
                }
                
                descriptionRow.title = updatedDescription
                descriptionRow.updateCell()
                descriptionRow.hidden = false
                descriptionRow.evaluateHidden()
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                descriptionRow.hidden = true
                descriptionRow.evaluateHidden()
                self.navigationItem.rightBarButtonItem?.isEnabled = false

            }
        }
    }
}
