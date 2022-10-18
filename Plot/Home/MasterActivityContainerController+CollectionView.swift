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
                    item.listColor = color
                } else if let list = networkController.activityService.lists[ListSourceOptions.plot.name]?.first(where: { $0.defaultList ?? false }), let color = list.color {
                    item.listColor = color
                }
                cell.configureCell(for: indexPath, task: item)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: eventCellID, for: indexPath) as? EventCollectionCell ?? EventCollectionCell()
                if let calendarID = item.calendarID, let calendar = networkController.activityService.calendarIDs[calendarID], let color = calendar.color {
                    item.calendarColor = color
                } else if let calendar = networkController.activityService.calendars[CalendarSourceOptions.plot.name]?.first(where: { $0.defaultCalendar ?? false }), let color = calendar.color {
                    item.calendarColor = color
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
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
                            if updatingTasks && updatingEvents {
                                cell.spinnerView.startAnimating()
                            } else {
                                cell.spinnerView.stopAnimating()
                            }
                            cell.subTitleLabel.isHidden = false
                        }
                    }
                } else if item == .health {
                    if !healthMetrics.isEmpty {
                        if updatingHealth {
                            cell.spinnerView.startAnimating()
                        } else {
                            cell.spinnerView.stopAnimating()
                        }
                        cell.subTitleLabel.isHidden = false
                    } else {
                        cell.subTitleLabel.isHidden = true
                    }
                } else {
                    if !financeSections.isEmpty {
                        if updatingFinances {
                            cell.spinnerView.startAnimating()
                        } else {
                            cell.spinnerView.stopAnimating()
                        }
                        cell.subTitleLabel.isHidden = false
                    } else {
                        cell.subTitleLabel.isHidden = true
                    }
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kHeaderCell, for: indexPath) as! InterSectionHeader
                cell.backgroundColor = .systemGroupedBackground
                cell.titleLabel.text = item.name
                if item == .tasks && activities[.tasks] != nil {
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
                } else if item == .transactions, networkController.financeService.transactions.count > 3 {
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
        cell.intColor = (indexPath.section % 3)
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
                dummyCell.updateInvitationDelegate = self
                dummyCell.configureCell(for: indexPath, activity: item, withInvitation: invitation)
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            }
        } else if let item = object as? HealthMetric {
            let dummyCell = HealthMetricCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
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
            dummyCell.intColor = (indexPath.section % 3)
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
                self.openMXConnect(current_member_guid: nil)
            }
        } else {
            let object = groups[indexPath.section]
            if let activity = object as? Activity {
                if activity.isTask ?? false {
                    showTaskDetailPush(task: activity)
                } else {
                    showEventDetailPush(event: activity)
                }
            } else if let metric = object as? HealthMetric {
                let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: HealthDetailService())
                let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel, networkController: networkController)
                healthDetailViewController.segmentedControl.selectedSegmentIndex = metric.grabSegment()
                healthDetailViewController.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(healthDetailViewController, animated: true)
            } else if let member = object as? MXMember {
                openMXConnect(current_member_guid: member.guid)
            } else if let transactionDetails = object as? TransactionDetails {
                let financeDetailViewModel = FinanceDetailViewModel(accountDetails: nil, allAccounts: nil, accounts: nil, transactionDetails: transactionDetails, allTransactions: networkController.financeService.transactions, transactions: transactionsDictionary[transactionDetails], filterAccounts: nil, financeDetailService: FinanceDetailService())
                let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel, networkController: networkController)
                financeDetailViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(financeDetailViewController, animated: true)
            } else if let accountDetails = object as? AccountDetails {
                let financeDetailViewModel = FinanceDetailViewModel(accountDetails: accountDetails, allAccounts: networkController.financeService.accounts, accounts: accountsDictionary[accountDetails], transactionDetails: nil, allTransactions: nil, transactions: nil, filterAccounts: nil, financeDetailService: FinanceDetailService())
                let financeDetailViewController = FinanceBarChartViewController(viewModel: financeDetailViewModel, networkController: networkController)
                financeDetailViewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(financeDetailViewController, animated: true)
            } else if let holding = object as? MXHolding {
                let destination = FinanceHoldingViewController(networkController: networkController)
                destination.holding = holding
                destination.hidesBottomBarWhenPushed = true
                ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            } else if let transaction = object as? Transaction {
                let destination = FinanceTransactionViewController(networkController: self.networkController)
                destination.transaction = transaction
                destination.hidesBottomBarWhenPushed = true
                ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
                    destination.selectedFalconUsers = participants
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            } else if let section = object as? SectionType {
                if section == .time || section == .health || section == .finances {
                    goToVC(section: section)
                } else {
                    if section == .tasks, !sortedTasks.isEmpty {
                        let destination = ListsViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .calendar, !sortedEvents.isEmpty {
                        let destination = CalendarViewController(networkController: networkController)
                        destination.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(destination, animated: true)
                    } else if section == .transactions, networkController.financeService.transactions.count > 3 {
                        let destination = FinanceDetailViewController(networkController: networkController)
                        destination.title = SectionType.transactions.name
                        destination.setSections = [.transactions]
                        navigationController?.pushViewController(destination, animated: true)
                    }
                }
            }
        }
    }
}
