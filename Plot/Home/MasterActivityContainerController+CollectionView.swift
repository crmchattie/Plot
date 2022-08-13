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
        if section == .calendar {
            //
            if !sortedActivities.isEmpty || networkController.activityService.askedforAuthorization {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: activitiesControllerCell, for: indexPath) as! ActivitiesControllerCell
                cell.delegate = self
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.activities = sortedActivities
                cell.invitations = networkController.activityService.invitations
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.intColor = (indexPath.section % 5)
                cell.sectionType = section
                return cell
            }
        } else if section == .health {
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
        if section == .calendar {
            if !sortedActivities.isEmpty || networkController.activityService.askedforAuthorization {
                for activity in sortedActivities {
                    let dummyCell = ActivityCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                    var invitation: Invitation? = nil
                    if let activityID = activity.activityID, let value = self.networkController.activityService.invitations[activityID] {
                        invitation = value
                    }
                    dummyCell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
                    dummyCell.layoutIfNeeded()
                    let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                    height += estimatedSize.height
                }
                return CGSize(width: self.collectionView.frame.size.width, height: height)
            } else {
                return CGSize(width: self.collectionView.frame.size.width - 30, height: 300)
            }
        } else if section == .health {
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
                height += CGFloat(financeSections.count * 40)
                for section in financeSections {
                    if section == .financialIssues {
                        if let group = financeGroups[section] as? [MXMember] {
                            height += CGFloat(group.count * 70)
                        }
                    } else if section == .investments {
                        let object = financeGroups[section]
//                        if let object = object as? [TransactionDetails] {
//                            let totalItems = object.count - 1
//                            for index in 0...totalItems {
//                                let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
//                                dummyCell.mode = .small
//                                if index == 0 {
//                                    dummyCell.firstPosition = true
//                                }
//                                if index == totalItems {
//                                    dummyCell.lastPosition = true
//                                }
//                                dummyCell.transactionDetails = object[index]
//                                dummyCell.layoutIfNeeded()
//                                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
//                                height += estimatedSize.height
//                            }
//                        } else if let object = object as? [AccountDetails] {
//                            let totalItems = object.count - 1
//                            for index in 0...totalItems {
//                                let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
//                                dummyCell.mode = .small
//                                if index == 0 {
//                                    dummyCell.firstPosition = true
//                                }
//                                if index == totalItems {
//                                    dummyCell.lastPosition = true
//                                }
//                                dummyCell.accountDetails = object[index]
//                                dummyCell.layoutIfNeeded()
//                                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
//                                height += estimatedSize.height
//                            }
//                        } else
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
            if section == .calendar {
                if !sortedActivities.isEmpty {
                    if updatingActivities {
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
            if section == .calendar {
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
