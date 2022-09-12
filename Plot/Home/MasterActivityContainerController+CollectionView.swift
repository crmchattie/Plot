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
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        if section == .time {
            if !activitiesSections.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: activitiesControllerCell, for: indexPath) as! ActivitiesControllerCell
                cell.delegate = self
                cell.updatingTasks = updatingTasks
                cell.updatingEvents = updatingEvents
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.networkController = networkController
                cell.sections = activitiesSections
                cell.activities = activities
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        }
        else if section == .health {
            if !healthMetrics.isEmpty || networkController.healthService.askedforAuthorization {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthControllerCell, for: indexPath) as! HealthControllerCell
                cell.delegate = self
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.healthMetricSections = healthMetricSections
                cell.healthMetrics = healthMetrics
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        } else {
            if !financeSections.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: financeControllerCell, for: indexPath) as! FinanceControllerCell
                cell.delegate = self
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.institutionDict = networkController.financeService.institutionDict
                cell.sections = financeSections
                cell.groups = financeGroups
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0
        let section = sections[indexPath.section]
        if section == .time {
            if !activitiesSections.isEmpty || networkController.activityService.askedforReminderAuthorization || networkController.activityService.askedforCalendarAuthorization {
                height += CGFloat(activitiesSections.count * 40)
                for task in sortedTasks {
                    let dummyCell = TaskCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                    dummyCell.configureCell(for: indexPath, task: task)
                    dummyCell.layoutIfNeeded()
                    let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                    height += estimatedSize.height
                }
                for activity in sortedEvents {
                    let dummyCell = EventCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                    dummyCell.configureCell(for: indexPath, activity: activity, withInvitation: nil)
                    dummyCell.layoutIfNeeded()
                    let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                    height += estimatedSize.height
                }
                return CGSize(width: self.collectionView.frame.size.width, height: height)
            } else {
                return CGSize(width: self.collectionView.frame.size.width - 30, height: 300)
            }
        }
        else if section == .health {
            if !healthMetrics.isEmpty || networkController.healthService.askedforAuthorization {
                height += CGFloat(healthMetricSections.count * 40)
                for key in healthMetricSections {
                    if let metrics = healthMetrics[key] {
                        height += CGFloat(metrics.count * 93)
//                        for metric in metrics {
//                            let dummyCell = HealthMetricCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
//                            dummyCell.configure(metric)
//                            dummyCell.layoutIfNeeded()
//                            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
//                            height += estimatedSize.height
//                        }
                    }
                }
                return CGSize(width: self.collectionView.frame.size.width, height: height)
            } else {
                return CGSize(width: self.collectionView.frame.size.width - 30, height: 300)
            }
        } else {
            if !financeSections.isEmpty {
                height += CGFloat(financeSections.count * 50)
                for section in financeSections {
                    if section == .financialIssues {
                        if let group = financeGroups[section] as? [MXMember] {
                            height += CGFloat(group.count * 70)
                        }
                    } else if section == .transactions {
                        let object = financeGroups[section]
                        if let object = object as? [Transaction] {
                            let totalItems = object.count - 1
                            for index in 0...totalItems {
                                let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                                dummyCell.firstPosition = true
                                dummyCell.lastPosition = true
                                dummyCell.transaction = object[index]
                                dummyCell.layoutIfNeeded()
                                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                                height += estimatedSize.height
                                if index == totalItems {
                                    height += 10
                                }
                            }
                        }
                    } else if section == .investments {
                        let object = financeGroups[section]
                        if let object = object as? [MXHolding] {
                            let totalItems = object.count - 1
                            for index in 0...totalItems {
                                let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                                dummyCell.mode = .small
                                if index == 0 {
                                    dummyCell.firstPosition = true
                                }
                                if index == totalItems {
                                    dummyCell.lastPosition = true
                                }
                                dummyCell.holding = object[index]
                                dummyCell.layoutIfNeeded()
                                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                                height += estimatedSize.height
                            }
                        }
                    } else {
                        if let group = financeGroups[section] as? [AccountDetails] {
                            height += CGFloat(group.count * 26) + 15
                        } else if let group = financeGroups[section] as? [TransactionDetails] {
                            height += CGFloat(group.count * 26) + 15
                        }
                    }
                }
                return CGSize(width: self.collectionView.frame.size.width, height: height)
            } else {
                return CGSize(width: self.collectionView.frame.size.width - 30, height: 300)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 15, left: 0, bottom: 15, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerContainerCell, for: indexPath) as! HeaderContainerCell
            let section = sections[indexPath.section]
            sectionHeader.titleLabel.text = section.name
            sectionHeader.sectionType = section
            if section == .time {
                if !activitiesSections.isEmpty {
                    if activitiesSections.count > 1 {
                        sectionHeader.spinnerView.stopAnimating()
                        sectionHeader.subTitleLabel.isHidden = true
                        sectionHeader.delegate = nil
                    } else {
                        if updatingTasks || updatingEvents {
                            sectionHeader.spinnerView.startAnimating()
                        } else {
                            sectionHeader.spinnerView.stopAnimating()
                        }
                        sectionHeader.subTitleLabel.isHidden = false
                        sectionHeader.delegate = self
                    }
                }
            } else if section == .health {
                if !healthMetrics.isEmpty {
                    if updatingHealth {
                        sectionHeader.spinnerView.startAnimating()
                    } else {
                        sectionHeader.spinnerView.stopAnimating()
                    }
                    sectionHeader.subTitleLabel.isHidden = false
                    sectionHeader.delegate = self
                } else {
                    sectionHeader.subTitleLabel.isHidden = true
                    sectionHeader.delegate = nil
                }
            } else {
                if !financeSections.isEmpty {
                    if updatingFinances {
                        sectionHeader.spinnerView.startAnimating()
                    } else {
                        sectionHeader.spinnerView.stopAnimating()
                    }
                    sectionHeader.subTitleLabel.isHidden = false
                    sectionHeader.delegate = self
                } else {
                    sectionHeader.subTitleLabel.isHidden = true
                    sectionHeader.delegate = nil
                }
            }
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        if let _ = collectionView.cellForItem(at: indexPath) as? SetupCell {
            if section == .time {
                newCalendar()
            } else if section == .health {
                networkController.healthService.grabHealth {
                    collectionView.reloadData()
                }
            } else {
                self.openMXConnect(current_member_guid: nil)
            }
        } else {
            goToVC(section: section)
        }
    }
}
