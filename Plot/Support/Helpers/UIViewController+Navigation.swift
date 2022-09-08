//
//  UIViewController+Navigation.swift
//  Plot
//
//  Created by Botond Magyarosi on 06.04.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase

protocol ObjectDetailShowing: UIViewController {
    
    var networkController: NetworkController { get }
    var participants: [String: [User]] { get set }
    
    func showActivityIndicator()
    func hideActivityIndicator()
}

extension ObjectDetailShowing {
    
    func showTaskDetail(task: Activity) {
        let destination = TaskViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.task = task
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showEventDetail(event: Activity) {
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = event
        destination.invitation = self.networkController.activityService.invitations[event.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: event) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: event, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                self.navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
    
    func showTranscationDetail(transaction: Transaction) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showAccountDetail(account: MXAccount) {
        let destination = FinanceAccountViewController(networkController: self.networkController)
        destination.account = account
        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showHoldingDetail(holding: MXHolding) {
        let destination = FinanceHoldingViewController(networkController: self.networkController)
        destination.holding = holding
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showListDetail(list: ListType) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showCalendarDetail(calendar: CalendarType) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
}
