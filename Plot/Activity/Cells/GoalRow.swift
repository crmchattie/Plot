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
    
    lazy var numberView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondaryLabel
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var numberTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = .label
        textField.font = UIFont.preferredFont(forTextStyle: .subheadline)
        textField.textAlignment = .center
        textField.adjustsFontForContentSizeCategory = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    lazy var unitView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondaryLabel
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
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
        view.backgroundColor = .secondaryLabel
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var metricLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
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
        view.backgroundColor = .secondaryLabel
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var submetricLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
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
        view.backgroundColor = .secondaryLabel
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
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
        
        let firstVerticalStackView = UIStackView(arrangedSubviews: [metricView, unitView, numberView])
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
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = "Goal"
        detailTextLabel?.isHidden = true
        detailTextLabel?.text = nil
        
        guard goal != nil else {
            metricLabel.text = "Metric"
            numberTextField.text = "0"
            unitLabel.text = "None"
            submetricLabel.text = "None"
            optionView.isHidden = true
            return
        }
                
        if let value = goal!.number {
            numberTextField.text = "\(String(describing: value))"
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
            unitLabel.text = "None"
            goal!.unit = nil
        }
        
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
        
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
        
    public func setupInlineRow(_ inlineRow: InlineRow) {
        inlineRow.options = self.options
        inlineRow.displayValueFor = self.displayValueFor
        inlineRow.cell.height = { UITableView.automaticDimension }
    }
    
    @objc func metricTapped(_ sender: UITapGestureRecognizer) {
        self.selectedGoalProperty = .metric
        self.options = GoalMetric.allValues
        if let goal = cell.goal, goal.metric == nil {
            self.value = GoalMetric.allValues[0]
        }
        toggleInlineRow()
    }
    
    @objc func unitTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let metric = goal.metric, metric.units.count > 0 else {
            return
        }
        self.selectedGoalProperty = .unit
        var array = [String]()
        metric.units.forEach { unit in
            array.append(unit.rawValue)
        }
        self.options = array
        toggleInlineRow()
        
    }
    
    @objc func submetricTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let metric = goal.metric, metric.submetrics.count > 0 else {
            return
        }
        self.selectedGoalProperty = .submetric
        var array = [String]()
        metric.submetrics.forEach { submetric in
            array.append(submetric.rawValue)
        }
        self.options = array
        toggleInlineRow()
        
    }
    
    @objc func optionTapped(_ sender: UITapGestureRecognizer) {
        guard let goal = cell.goal, let options = goal.options() else {
            return
        }
        self.selectedGoalProperty = .option
        self.options = options
        toggleInlineRow()
        
    }
}

enum SelectedGoalProperty {
    case metric, unit, submetric, option
}
