//
//  GoalRow.swift
//  Plot
//
//  Created by Cory McHattie on 11/24/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Eureka

final class GoalPickerInlineCell<T: Equatable> : Cell<T>, CellType {
    var goal: Goal?
    
    var timer: Timer?
    
    lazy var numberView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var numberTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = .label
        textField.font = UIFont.preferredFont(forTextStyle: .callout)
        textField.textAlignment = .center
        textField.adjustsFontForContentSizeCategory = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    lazy var unitView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var metricView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var metricLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var submetricView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var submetricLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var optionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override func setup() {
        detailTextLabel?.isHidden = true
        detailTextLabel?.text = nil
        
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none
        
        numberView.addSubview(numberTextField)
        numberTextField.anchor(top: numberView.topAnchor, leading: numberView.leadingAnchor, bottom: numberView.bottomAnchor, trailing: numberView.trailingAnchor, padding: .init(top: 5, left: 5, bottom: 5, right: 5))
        
        metricView.addSubview(metricLabel)
        metricLabel.anchor(top: metricView.topAnchor, leading: metricView.leadingAnchor, bottom: metricView.bottomAnchor, trailing: metricView.trailingAnchor, padding: .init(top: 5, left: 5, bottom: 5, right: 5))
        
        unitView.addSubview(unitLabel)
        unitLabel.anchor(top: unitView.topAnchor, leading: unitView.leadingAnchor, bottom: unitView.bottomAnchor, trailing: unitView.trailingAnchor, padding: .init(top: 5, left: 5, bottom: 5, right: 5))
        
        submetricView.addSubview(submetricLabel)
        submetricLabel.anchor(top: submetricView.topAnchor, leading: submetricView.leadingAnchor, bottom: submetricView.bottomAnchor, trailing: submetricView.trailingAnchor, padding: .init(top: 5, left: 5, bottom: 5, right: 5))
        
        optionView.addSubview(optionLabel)
        optionLabel.anchor(top: optionView.topAnchor, leading: optionView.leadingAnchor, bottom: optionView.bottomAnchor, trailing: optionView.trailingAnchor, padding: .init(top: 5, left: 5, bottom: 5, right: 5))
        
        let firstVerticalStackView = UIStackView(arrangedSubviews: [metricView, numberView, unitView])
        firstVerticalStackView.translatesAutoresizingMaskIntoConstraints = false
        firstVerticalStackView.spacing = 5
        let secondVerticalStackView = UIStackView(arrangedSubviews: [submetricView, optionView])
        secondVerticalStackView.translatesAutoresizingMaskIntoConstraints = false
        secondVerticalStackView.spacing = 5
        
        let stackView = VerticalStackView(arrangedSubviews: [firstVerticalStackView, secondVerticalStackView], spacing: 5)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 5
        
        contentView.addSubview(stackView)
        
        stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        stackView.leftAnchor.constraint(greaterThanOrEqualTo: textLabel!.rightAnchor, constant: 10).isActive = true
        stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 5).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -5).isActive = true
        
    }
    
    override func update() {
        print("update")
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = "Goal"
        detailTextLabel?.isHidden = true
        detailTextLabel?.text = nil
        
        guard goal != nil else {
            metricLabel.text = "Metric"
            numberTextField.text = "Number"
            unitLabel.text = "Unit"
            submetricLabel.text = "None"
            optionView.isHidden = true
            return
        }
        
        if let value = goal!.metric {
            metricLabel.text = value.rawValue
        }
        
        if let value = goal!.unit, let metric = goal!.metric, metric.units.contains(value) {
            unitView.isHidden = false
            unitLabel.text = value.rawValue
        } else if let metric = goal!.metric, metric.units.count > 0 {
            let units = metric.units
            unitView.isHidden = false
            unitLabel.text = units[0].rawValue
            goal!.unit = units[0]
        } else {
            unitLabel.text = "Unit"
            goal!.unit = nil
        }
        
        updateTextField()
                
        if let value = goal!.submetric, let metric = goal!.metric, metric.submetrics.contains(value) {
            submetricView.isHidden = false
            submetricLabel.text = value.rawValue
        } else if let metric = goal!.metric, metric.submetrics.count > 0 {
            let submetrics = metric.submetrics
            submetricView.isHidden = false
            submetricLabel.text = submetrics[0].rawValue
            goal!.submetric = submetrics[0]
        } else {
            submetricLabel.text = "None"
            goal!.submetric = nil
        }
        
        if let value = goal!.option, let options = goal!.options(), options.contains(value) {
            optionView.isHidden = false
            optionLabel.text = value
        } else if let options = goal!.options() {
            optionView.isHidden = false
            optionLabel.text = options[0]
            goal!.option = options[0]
        } else if let metric = goal!.metric, metric.submetrics.count > 0, let options = goal!.options(submetric: metric.submetrics[0]) {
            optionView.isHidden = false
            optionLabel.text = options[0]
            goal!.option = options[0]
        } else {
            optionView.isHidden = true
            goal!.option = nil
        }
    }
    
    func updateTextField() {
        let numberFormatter = NumberFormatter()
        numberFormatter.currencyCode = "USD"
        numberFormatter.maximumFractionDigits = 0
        if let unit = goal!.unit {
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
            if let number = goal!.targetNumber as? NSNumber {
                numberTextField.text = numberFormatter.string(from: number)
            } else {
                numberTextField.text = "Number"
            }
        }
    }
}

// MARK: PickerInlineRow
class _GoalPickerInlineRow : Row<GoalPickerInlineCell<String>>, NoValueDisplayTextConformance {
    public typealias InlineRow = PickerRow<String>
    open var options = [String]()
    open var noValueDisplayText: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

final class GoalPickerInlineRow<T> : _GoalPickerInlineRow, RowType, InlineRowType where T: Equatable {
    var selectedGoalProperty: SelectedGoalProperty = .metric
    required public init(tag: String?) {
        super.init(tag: tag)
        let metricTap = UITapGestureRecognizer(target: self, action: #selector(GoalPickerInlineRow.metricTapped(_:)))
        cell.metricLabel.addGestureRecognizer(metricTap)
        let unitTap = UITapGestureRecognizer(target: self, action: #selector(GoalPickerInlineRow.unitTapped(_:)))
        cell.unitLabel.addGestureRecognizer(unitTap)
        let submetricTap = UITapGestureRecognizer(target: self, action: #selector(GoalPickerInlineRow.submetricTapped(_:)))
        cell.submetricLabel.addGestureRecognizer(submetricTap)
        let optionTap = UITapGestureRecognizer(target: self, action: #selector(GoalPickerInlineRow.optionTapped(_:)))
        cell.optionLabel.addGestureRecognizer(optionTap)
        
        cell.numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingDidBegin)
        cell.numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
        onChange { row in
            switch self.selectedGoalProperty {
            case .metric:
                if let value = row.value, let updatedValue = GoalMetric(rawValue: value) {
                    if let goal = row.cell.goal, goal.targetNumber != 0 {
                        row.cell.goal = Goal(name: nil, metric: updatedValue, submetric: nil, option: nil, unit: nil, targetNumber: goal.targetNumber, currentNumber: nil)
                    } else {
                        row.cell.goal = Goal(name: nil, metric: updatedValue, submetric: nil, option: nil, unit: nil, targetNumber: nil, currentNumber: nil)
                    }
                }
            case .unit:
                if let value = row.value, let updatedValue = GoalUnit(rawValue: value) {
                    if let _ = row.cell.goal {
                        if updatedValue == .percent, let number = row.cell.goal!.number {
                            row.cell.goal?.number = number / 100
                        }
                        row.cell.goal!.unit = updatedValue
                    } else {
                        row.cell.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: updatedValue, number: nil, currentNumber: nil)
                    }
                }
            case .submetric:
                if let value = row.value, let updatedValue = GoalSubMetric(rawValue: value) {
                    if let _ = row.cell.goal {
                        row.cell.goal!.submetric = updatedValue
                    } else {
                        row.cell.goal = Goal(name: nil, metric: nil, submetric: updatedValue, option: nil, unit: nil, number: nil, currentNumber: nil)
                    }
                }
            case .option:
                if let updatedValue = row.value {
                    if let _ = row.cell.goal {
                        row.cell.goal!.option = updatedValue
                    } else {
                        row.cell.goal = Goal(name: nil, metric: nil, submetric: nil, option: updatedValue, unit: nil, number: nil, currentNumber: nil)
                    }
                }
            }
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if isExpanded {
                collapseInlineRow()
            } else {
                metricTapped(UITapGestureRecognizer())
            }
        }
    }
    
    public func setupInlineRow(_ inlineRow: InlineRow) {
        inlineRow.options = self.options
        inlineRow.displayValueFor = self.displayValueFor
        inlineRow.cell.height = { UITableView.automaticDimension }
    }
    
    @objc func metricTapped(_ sender: UITapGestureRecognizer) {
        self.options = GoalMetric.allValues
        if let goal = cell.goal, let metric = goal.metric {
            self.value = metric.rawValue
        } else {
            self.value = GoalMetric.allValues[0]
            cell.goal = Goal(name: nil, metric: GoalMetric(rawValue: GoalMetric.allValues[0]), submetric: nil, option: nil, unit: nil, targetNumber: nil, currentNumber: nil)
            cell.update()
        }
        if isExpanded, self.selectedGoalProperty != .metric {
            toggleInlineRow()
            toggleInlineRow()
        } else {
            toggleInlineRow()
        }
        self.selectedGoalProperty = .metric
        cell.numberTextField.resignFirstResponder()
    }
    
    @objc func unitTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let metric = goal.metric, metric.units.count > 0 else {
            return
        }
        var array = [String]()
        metric.units.forEach { unit in
            array.append(unit.rawValue)
        }
        self.options = array
        if let submetric = goal.submetric {
            self.value = submetric.rawValue
        } else {
            self.value = metric.units[0].rawValue
        }
        if isExpanded, self.selectedGoalProperty != .unit {
            toggleInlineRow()
            toggleInlineRow()
        } else {
            toggleInlineRow()
        }
        self.selectedGoalProperty = .unit
        cell.numberTextField.resignFirstResponder()
    }
    
    @objc func submetricTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let metric = goal.metric, metric.submetrics.count > 0 else {
            return
        }
        var array = [String]()
        metric.submetrics.forEach { submetric in
            array.append(submetric.rawValue)
        }
        self.options = array
        if let submetric = goal.submetric {
            self.value = submetric.rawValue
        } else {
            self.value = metric.submetrics[0].rawValue
        }
        if isExpanded, self.selectedGoalProperty != .submetric {
            toggleInlineRow()
            toggleInlineRow()
        } else {
            toggleInlineRow()
        }
        self.selectedGoalProperty = .submetric
        cell.numberTextField.resignFirstResponder()
    }
    
    @objc func optionTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let options = goal.options() else {
            return
        }
        self.options = options
        if let option = goal.option {
            self.value = option
        } else {
            self.value = options[0]
        }
        if isExpanded, self.selectedGoalProperty != .option {
            toggleInlineRow()
            toggleInlineRow()
        } else {
            toggleInlineRow()
        }
        self.selectedGoalProperty = .option
        cell.numberTextField.resignFirstResponder()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        collapseInlineRow()
        guard let text = textField.text, text != "Number" else {
            cell.numberTextField.text = nil
            return
        }
        
        if cell.goal != nil {
            if let unit = cell.goal!.unit, unit == .percent {
                cell.goal!.targetNumber = (Double(text.filteredNumbers) ?? 0) / 100
            } else {
                cell.goal!.targetNumber = Double(text.filteredNumbers)
            }
        } else {
            cell.goal = Goal(name: nil, metric: nil, submetric: nil, option: nil, unit: nil, targetNumber: Double(text.filteredNumbers), currentNumber: nil)
        }
        
        cell.timer?.invalidate()
        
        cell.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (_) in
            self.updateCell()
        })
    }
}

enum SelectedGoalProperty {
    case metric, unit, submetric, option
}
