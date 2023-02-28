//
//  MasterActivityContainerController+CollectionView.swift
//  Plot
//
//  Created by Cory McHattie on 7/1/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation

extension MasterActivityContainerController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groups.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let object = groups[indexPath.section]
        if let item = object as? Activity {
            if item.isTask ?? false {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: taskCellID, for: indexPath) as? TaskCollectionCell ?? TaskCollectionCell()
                if let listID = item.listID, let list = networkController.activityService.listIDs[listID], let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                cell.configureCell(for: indexPath, task: item)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: eventCellID, for: indexPath) as? EventCollectionCell ?? EventCollectionCell()
                if let calendarID = item.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                    cell.activityTypeButton.tintColor = UIColor(ciColor: CIColor(string: color))
                }
                var invitation: Invitation? = nil
                if let activityID = item.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                cell.configureCell(for: indexPath, activity: item, withInvitation: invitation)
                cell.updateInvitationDelegate = self
                return cell
            }
        } else if let item = object as? HealthMetric {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
            cell.configure(item)
            return cell
        } else if let item = object as? Workout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
            cell.configure(item)
            return cell
        } else if let item = object as? Mood {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
            cell.configure(item)
            return cell
        } else if let item = object as? Mindfulness {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCollectionCell
            cell.configure(item)
            return cell
        } else if let item = object as? MXMember {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            cell.member = item
            return cell
        } else if let item = object as? TransactionDetails {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            cell.transactionDetails = item
            return cell
        } else if let item = object as? AccountDetails {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            cell.accountDetails = item
            return cell
        } else if let item = object as? MXHolding {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            cell.holding = item
            return cell
        } else if let item = object as? Transaction {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            cell.firstPosition = true
            cell.lastPosition = true
            cell.transaction = item
            return cell
        } else if let item = object as? SectionType {
            if item == .time || item == .health || item == .finances {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: headerContainerCell, for: indexPath) as! HeaderContainerCell
                cell.backgroundColor = .systemGroupedBackground
                cell.titleLabel.text = item.name
                if item == .time {
                    if !activitiesSections.isEmpty {
                        if activitiesSections.count > 1 {
                            cell.spinnerView.stopAnimating()
                            cell.subTitleLabel.isHidden = true
                        } else {
                            if updatingTasks && updatingEvents && updatingGoals {
                                cell.spinnerView.startAnimating()
                            } else {
                                cell.spinnerView.stopAnimating()
                            }
                            cell.subTitleLabel.isHidden = false
                        }
                    }
                } else if item == .health {
                    if !healthMetricSections.isEmpty {
                        if healthMetricSections.count > 1 {
                            cell.spinnerView.stopAnimating()
                            cell.subTitleLabel.isHidden = true
                        } else {
                            if updatingHealth {
                                cell.spinnerView.startAnimating()
                            } else {
                                cell.spinnerView.stopAnimating()
                            }
                            cell.subTitleLabel.isHidden = false
                        }
                    }
                } else {
                    if !financeSections.isEmpty {
                        if financeSections.count > 1 {
                            cell.spinnerView.stopAnimating()
                            cell.subTitleLabel.isHidden = true
                        } else {
                            if updatingFinances {
                                cell.spinnerView.startAnimating()
                            } else {
                                cell.spinnerView.stopAnimating()
                            }
                            cell.subTitleLabel.isHidden = false
                        }
                    }
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kHeaderCell, for: indexPath) as! InterSectionHeader
                cell.backgroundColor = .systemGroupedBackground
                cell.titleLabel.text = item.name
                if item == .goals && activities[.goals] != nil {
                    if updatingGoals {
                        cell.spinnerView.startAnimating()
                    } else {
                        cell.spinnerView.stopAnimating()
                    }
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .tasks && activities[.tasks] != nil {
                    if updatingTasks {
                        cell.spinnerView.startAnimating()
                    } else {
                        cell.spinnerView.stopAnimating()
                    }
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .calendar && activities[.calendar] != nil {
                    if updatingEvents {
                        cell.spinnerView.startAnimating()
                    } else {
                        cell.spinnerView.stopAnimating()
                    }
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .cashFlow {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .balancesFinances {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .transactions, networkController.financeService.transactions.count > 3 {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .generalHealth {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .workout, networkController.healthService.workouts.count > 1 {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .mood, networkController.healthService.moods.count > 1 {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else if item == .mindfulness, networkController.healthService.mindfulnesses.count > 1 {
                    cell.view.isUserInteractionEnabled = true
                    cell.subTitleLabel.isHidden = false
                } else {
                    cell.view.isUserInteractionEnabled = false
                    cell.subTitleLabel.isHidden = true
                }
                return cell
            }
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
        cell.backgroundColor = .secondarySystemGroupedBackground
        if let item = object as? CustomType {
            cell.customType = item
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 300
        let object = groups[indexPath.section]
        if let item = object as? Activity {
            if item.isTask ?? false {
                let dummyCell = TaskCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                dummyCell.configureCell(for: indexPath, task: item)
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            } else {
                let dummyCell = EventCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                var invitation: Invitation? = nil
                if let activityID = item.activityID, let value = invitations[activityID] {
                    invitation = value
                }
                dummyCell.configureCell(for: indexPath, activity: item, withInvitation: invitation)
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            }
        } else if let item = object as? HealthMetric {
            let dummyCell = HealthMetricCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.configure(item)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? Workout {
            let dummyCell = HealthMetricCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.configure(item)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? Mood {
            let dummyCell = HealthMetricCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.configure(item)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? Mindfulness {
            let dummyCell = HealthMetricCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.configure(item)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? MXMember {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.member = item
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? TransactionDetails {
            let dummyCell = FinanceCollectionViewComparisonCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.transactionDetails = item
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? AccountDetails {
            let dummyCell = FinanceCollectionViewComparisonCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.accountDetails = item
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? MXHolding {
            let dummyCell = FinanceCollectionViewComparisonCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.holding = item
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? Transaction {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.firstPosition = true
            dummyCell.lastPosition = true
            dummyCell.transaction = item
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        } else if let item = object as? SectionType {
            if item == .time || item == .health || item == .finances {
                let dummyCell = HeaderContainerCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                dummyCell.backgroundColor = .systemGroupedBackground
                dummyCell.titleLabel.text = item.name
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            } else {
                let dummyCell = InterSectionHeader(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                dummyCell.backgroundColor = .systemGroupedBackground
                dummyCell.titleLabel.text = item.name
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            }
        } else {
            let dummyCell = SetupCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.backgroundColor = .secondarySystemGroupedBackground
            if let item = object as? CustomType {
                dummyCell.customType = item
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let object = groups[section]
        if let _ = object as? Activity {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? HealthMetric {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? Workout {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? Mood {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? Mindfulness {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? MXMember {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? TransactionDetails {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? AccountDetails {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? MXHolding {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let _ = object as? Transaction {
            return .init(top: 5, left: 0, bottom: 5, right: 0)
        } else if let item = object as? SectionType {
            if item == .time || item == .health || item == .finances {
                return .init(top: 15, left: 0, bottom: 15, right: 0)
            } else {
                return .init(top: 5, left: 0, bottom: 5, right: 0)
            }
        }
        return .init(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let _ = collectionView.cellForItem(at: indexPath) as? SetupCell, let section = groups[indexPath.section] as? CustomType {
            if section == .time {
                newCalendar()
            } else if section == .health {
                networkController.healthService.regrabHealth {}
            } else {
                openMXConnect(current_member_guid: nil, delegate: self)
            }
        } else {
            let object = groups[indexPath.section]
            if let activity = object as? Activity {
                if activity.isGoal ?? false {
                    showGoalDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                } else if !(activity.isGoal ?? false), activity.isTask ?? false {
                    showTaskDetailPresent(task: activity, updateDiscoverDelegate: nil, delegate: nil, event: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, list: nil, startDateTime: nil, endDateTime: nil)
                } else {
                    showEventDetailPresent(event: activity, updateDiscoverDelegate: nil, delegate: nil, task: nil, transaction: nil, workout: nil, mindfulness: nil, template: nil, users: nil, container: nil, startDateTime: nil, endDateTime: nil)
                }
            } else if let healthMetric = object as? HealthMetric {
                showHealthMetricDetailPush(healthMetric: healthMetric)
            } else if let workout = object as? Workout {
                showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            } else if let mood = object as? Mood {
                showMoodDetailPresent(mood: mood, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            } else if let mindfulness = object as? Mindfulness {
                showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            } else if let member = object as? MXMember {
                openMXConnect(current_member_guid: member.guid, delegate: self)
            } else if let transactionDetails = object as? TransactionDetails, let transactions = transactionsDictionary[transactionDetails] {
                showTransactionDetailDetailPush(transactionDetails: transactionDetails, allTransactions: networkController.financeService.transactions, transactions: transactions, filterDictionary: nil, selectedIndex: nil)
            } else if let accountDetails = object as? AccountDetails, let accounts = accountsDictionary[accountDetails] {
                showAccountDetailDetailPush(accountDetails: accountDetails, allAccounts: networkController.financeService.accounts, accounts: accounts, selectedIndex: nil)
            } else if let holding = object as? MXHolding {
                showHoldingDetailPresent(holding: holding, updateDiscoverDelegate: nil)
            } else if let transaction = object as? Transaction {
                showTransactionDetailPresent(transaction: transaction, updateDiscoverDelegate: nil, delegate: nil, users: nil, container: nil, movingBackwards: nil)
            } else if let section = object as? SectionType {
                if section == .time || section == .health || section == .finances {
                    goToVC(section: section)
                } else {
                    if section == .goals, !sortedGoals.isEmpty {
                        let destination = GoalsViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .tasks, !sortedTasks.isEmpty {
                        let destination = ListsViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .calendar, !sortedEvents.isEmpty {
                        let destination = CalendarViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .cashFlow {
                        let destination = FinanceViewController(networkController: networkController)
                        destination.title = section.name
                        destination.setSections = [.incomeStatement, .transactions]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .balancesFinances {
                        let destination = FinanceViewController(networkController: networkController)
                        destination.title = section.name
                        destination.setSections = [.balanceSheet, .financialAccounts]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .transactions, networkController.financeService.transactions.count > 3 {
                        let destination = FinanceDetailViewController(networkController: networkController)
                        destination.title = section.name
                        destination.setSections = [.transactions]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .generalHealth {
                        let destination = HealthViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .workout, networkController.healthService.workouts.count > 1 {
                        let destination = HealthListViewController(networkController: networkController)
                        destination.title = HealthMetricCategory.workoutsList.name
                        destination.healthMetricSections = [HealthMetricCategory.workoutsList]
                        destination.healthMetrics = [HealthMetricCategory.workoutsList: networkController.healthService.workouts]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .mood, networkController.healthService.moods.count > 1 {
                        let destination = HealthListViewController(networkController: networkController)
                        destination.title = HealthMetricCategory.moodList.name
                        destination.healthMetricSections = [HealthMetricCategory.moodList]
                        destination.healthMetrics = [HealthMetricCategory.moodList: networkController.healthService.moods]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .mindfulness, networkController.healthService.mindfulnesses.count > 1 {
                        let destination = HealthListViewController(networkController: networkController)
                        destination.title = HealthMetricCategory.mindfulnessList.name
                        destination.healthMetricSections = [HealthMetricCategory.mindfulnessList]
                        destination.healthMetrics = [HealthMetricCategory.mindfulnessList: networkController.healthService.mindfulnesses]
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    }
                }
            }
        }
    }
}
