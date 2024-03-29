//
//  RecurrencePicker.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit
import EventKit
import RRuleSwift

open class RecurrencePicker: UITableViewController {
    open var language: RecurrencePickerLanguage = .english {
        didSet {
            InternationalControl.shared.language = language
        }
    }
    open weak var delegate: RecurrencePickerDelegate?
    open var tintColor = FalconPalette.defaultBlue
    open var calendar = Calendar.current
    open var occurrenceDate: Date!
    fileprivate var occurrenceDateStatic: Date!
    open var backgroundColor: UIColor?
    open var separatorColor: UIColor?
    open var supportedCustomRecurrenceFrequencies = Constant.frequencies
    open var customRecurrenceMaximumInterval = Constant.pickerMaxRowCount
    open var isGoal = false
    fileprivate var movingBackwards = true

    fileprivate var isModal: Bool {
        return presentingViewController?.presentedViewController == self
            || (navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController && navigationController?.viewControllers.first == self)
            || tabBarController?.presentingViewController is UITabBarController
    }
    fileprivate var recurrenceRule: RecurrenceRule?
    fileprivate var selectedIndexPath = IndexPath(row: 0, section: 0)

    // MARK: - Initialization
    public convenience init(recurrenceRule: RecurrenceRule?) {
        self.init(style: .insetGrouped)
        self.recurrenceRule = recurrenceRule
    }

    // MARK: - Life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    open override func didMove(toParent parent: UIViewController?) {
        if parent == nil && movingBackwards {
            // navigation is popped
            recurrencePickerDidPickRecurrence()
        }
    }

    // MARK: - Actions
    @objc func doneButtonTapped(_ sender: UIBarButtonItem) {
        movingBackwards = false
        self.recurrencePickerDidPickRecurrence()
        if navigationItem.leftBarButtonItem != nil {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

extension RecurrencePicker {
    // MARK: - Table view data source and delegate
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Constant.basicRecurrenceStrings().count
        } else {
            return 1
        }
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constant.defaultRowHeight
    }

    open override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 1 ? recurrenceRuleText() : nil
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CellID.basicRecurrenceCell)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: CellID.basicRecurrenceCell)
        }
        cell?.backgroundColor = .secondarySystemGroupedBackground
        if indexPath.section == 0 {
            cell?.accessoryType = .none
            cell?.textLabel?.text = Constant.basicRecurrenceStrings()[indexPath.row]
        } else {
            cell?.accessoryType = .disclosureIndicator
            cell?.textLabel?.text = LocalizedString("RecurrencePicker.textLabel.custom")
        }

        let checkmark = UIImage(named: "checkmark", in: Bundle(for: type(of: self)), compatibleWith: nil)
        cell?.imageView?.image = checkmark?.withRenderingMode(.alwaysTemplate)

        if indexPath == selectedIndexPath {
            cell?.imageView?.isHidden = false
        } else {
            cell?.imageView?.isHidden = true
        }
        return cell!
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lastSelectedCell = tableView.cellForRow(at: selectedIndexPath)
        let currentSelectedCell = tableView.cellForRow(at: indexPath)

        lastSelectedCell?.imageView?.isHidden = true
        currentSelectedCell?.imageView?.isHidden = false

        selectedIndexPath = indexPath

        if indexPath.section == 0 {
            updateRecurrenceRule(withSelectedIndexPath: indexPath)
            updateRecurrenceRuleText()
            if !isModal {
                let _ = navigationController?.popViewController(animated: true)
            }
        } else {
            let customRecurrenceViewController = CustomRecurrenceViewController(style: .insetGrouped)
            customRecurrenceViewController.occurrenceDate = occurrenceDate
            customRecurrenceViewController.backgroundColor = backgroundColor
            customRecurrenceViewController.separatorColor = separatorColor
            customRecurrenceViewController.tableView.separatorStyle = .none
            customRecurrenceViewController.supportedFrequencies = supportedCustomRecurrenceFrequencies
            customRecurrenceViewController.maximumInterval = customRecurrenceMaximumInterval
            customRecurrenceViewController.delegate = self

            var rule = recurrenceRule ?? RecurrenceRule.dailyRecurrence()
            let occurrenceDateComponents = calendar.dateComponents([.weekday, .day, .month], from: occurrenceDate)
            if rule.byweekday.count == 0 {
                let weekday = EKWeekday(rawValue: occurrenceDateComponents.weekday!)!
                rule.byweekday = [weekday]
            }
            if rule.bymonthday.count == 0 {
                let monthday = occurrenceDateComponents.day
                rule.bymonthday = [monthday!]
            }
            if rule.bymonth.count == 0 {
                let month = occurrenceDateComponents.month
                rule.bymonth = [month!]
            }
            customRecurrenceViewController.recurrenceRule = rule

            navigationController?.pushViewController(customRecurrenceViewController, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RecurrencePicker {
    // MARK: - Helper
    fileprivate func commonInit() {
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.title = LocalizedString("RecurrencePicker.navigation.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizedString("Done"), style: .done, target: self, action: #selector(doneButtonTapped(_:)))
        if isModal {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString("Cancel"), style: .plain, target: self, action: #selector(closeButtonTapped(_:)))
        }
        tableView.separatorStyle = .none
        tableView.tintColor = tintColor
        tableView.backgroundColor = .systemGroupedBackground
        occurrenceDateStatic = occurrenceDate
        updateSelectedIndexPath(withRule: recurrenceRule)
    }

    fileprivate func updateSelectedIndexPath(withRule recurrenceRule: RecurrenceRule?) {
        guard let recurrenceRule = recurrenceRule else {
            selectedIndexPath = IndexPath(row: 0, section: 0)
            return
        }
        if recurrenceRule.isDailyRecurrence() {
            selectedIndexPath = IndexPath(row: 1, section: 0)
        } else if recurrenceRule.isWeekdayRecurrence() {
            selectedIndexPath = IndexPath(row: 2, section: 0)
        } else if recurrenceRule.isWeekendRecurrence() {
            selectedIndexPath = IndexPath(row: 3, section: 0)
        } else if recurrenceRule.isWeeklyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 4, section: 0)
        } else if recurrenceRule.isBiWeeklyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 5, section: 0)
        } else if recurrenceRule.isMonthlyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 6, section: 0)
        } else if recurrenceRule.isQuarterlyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 7, section: 0)
        } else if recurrenceRule.isSemiannualRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 8, section: 0)
        } else if recurrenceRule.isYearlyRecurrence(occurrence: occurrenceDate) {
            selectedIndexPath = IndexPath(row: 9, section: 0)
        } else {
            selectedIndexPath = IndexPath(row: 0, section: 1)
        }
    }

    fileprivate func updateRecurrenceRule(withSelectedIndexPath indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        
        switch indexPath.row {
        case 0:
            recurrenceRule = nil
        case 1:
            recurrenceRule = RecurrenceRule.dailyRecurrence()
        case 2:
            recurrenceRule = RecurrenceRule.weekdayRecurrence()
        case 3:
            recurrenceRule = RecurrenceRule.weekendRecurrence()
        case 4:
            let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: occurrenceDate))!
            recurrenceRule = RecurrenceRule.weeklyRecurrence(withWeekday: weekday)
        case 5:
            let weekday = EKWeekday(rawValue: calendar.component(.weekday, from: occurrenceDate))!
            recurrenceRule = RecurrenceRule.biWeeklyRecurrence(withWeekday: weekday)
        case 6:
            let monthday = calendar.component(.day, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.monthlyRecurrence(withMonthday: monthday)
        case 7:
            let monthday = calendar.component(.day, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.quarterlyRecurrence(withMonthday: monthday)
        case 8:
            let monthday = calendar.component(.day, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.semiannualRecurrence(withMonthday: monthday)
        case 9:
            let month = calendar.component(.month, from: occurrenceDate)
            recurrenceRule = RecurrenceRule.yearlyRecurrence(withMonth: month)
        default:
            break
        }
    }

    fileprivate func recurrenceRuleText() -> String? {
        return selectedIndexPath.section == 1 ? recurrenceRule?.toText(occurrenceDate: occurrenceDate) : nil
    }

    fileprivate func updateRecurrenceRuleText() {
        let footerView = tableView.footerView(forSection: 1)
        tableView.beginUpdates()
        footerView?.textLabel?.text = recurrenceRuleText()
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }

    fileprivate func recurrencePickerDidPickRecurrence() {
        if let rule = recurrenceRule {
            switch rule.frequency {
            case .daily:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth.removeAll()
            case .weekly:
                recurrenceRule?.byweekday = rule.byweekday.sorted(by: <)
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth.removeAll()
            case .monthly:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday = rule.bymonthday.sorted(by: <)
                recurrenceRule?.bymonth.removeAll()
            case .yearly:
                recurrenceRule?.byweekday.removeAll()
                recurrenceRule?.bymonthday.removeAll()
                recurrenceRule?.bymonth = rule.bymonth.sorted(by: <)
            default:
                break
            }
        }
        recurrenceRule?.startDate = occurrenceDate
        delegate?.recurrencePicker(self, didPickRecurrence: recurrenceRule)
    }
}

extension RecurrencePicker: CustomRecurrenceViewControllerDelegate {
    // MARK: - CustomRecurrenceViewController delegate
    func customRecurrenceViewController(_ controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule) {
        self.recurrenceRule = recurrenceRule
        updateRecurrenceRuleText()
    }
}
