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
    
    func showTaskDetailPush(task: Activity) {
        let destination = TaskViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.task = task
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showEventDetailPush(event: Activity) {
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
    
    func showTransactionDetailPush(transaction: Transaction) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showAccountDetailPush(account: MXAccount) {
        let destination = FinanceAccountViewController(networkController: self.networkController)
        destination.account = account
        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showHoldingDetailPush(holding: MXHolding) {
        let destination = FinanceHoldingViewController(networkController: self.networkController)
        destination.holding = holding
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showListDetailPush(list: ListType) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showCalendarDetailPush(calendar: CalendarType) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showWorkoutDetailPush(workout: Workout) {
        let destination = WorkoutViewController(networkController: self.networkController)
        destination.workout = workout
        ParticipantsFetcher.getParticipants(forWorkout: workout) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    func showMindfulnessDetailPush(mindfulness: Mindfulness) {
        let destination = MindfulnessViewController(networkController: self.networkController)
        destination.mindfulness = mindfulness
        ParticipantsFetcher.getParticipants(forMindfulness: mindfulness) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    
    
    
    func showTaskDetailPresent(task: Activity) {
        let destination = TaskViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.task = task
        ParticipantsFetcher.getParticipants(forActivity: task) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showEventDetailPresent(event: Activity) {
        let destination = EventViewController(networkController: networkController)
        destination.hidesBottomBarWhenPushed = true
        destination.activity = event
        destination.invitation = self.networkController.activityService.invitations[event.activityID ?? ""]
        ParticipantsFetcher.getParticipants(forActivity: event) { (participants) in
            ParticipantsFetcher.getAcceptedParticipant(forActivity: event, allParticipants: participants) { acceptedParticipant in
                destination.acceptedParticipant = acceptedParticipant
                destination.selectedFalconUsers = participants
                let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
                destination.navigationItem.leftBarButtonItem = cancelBarButton
                let navigationViewController = UINavigationController(rootViewController: destination)
                self.present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
    
    func showTransactionDetailPresent(transaction: Transaction) {
        let destination = FinanceTransactionViewController(networkController: self.networkController)
        destination.transaction = transaction
        ParticipantsFetcher.getParticipants(forTransaction: transaction) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showAccountDetailPresent(account: MXAccount) {
        let destination = FinanceAccountViewController(networkController: self.networkController)
        destination.account = account
        ParticipantsFetcher.getParticipants(forAccount: account) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showHoldingDetailPresent(holding: MXHolding) {
        let destination = FinanceHoldingViewController(networkController: self.networkController)
        destination.holding = holding
        ParticipantsFetcher.getParticipants(forHolding: holding) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showListDetailPresent(list: ListType) {
        let destination = ListDetailViewController(networkController: self.networkController)
        destination.list = list
        ParticipantsFetcher.getParticipants(forList: list) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showCalendarDetailPresent(calendar: CalendarType) {
        let destination = CalendarDetailViewController(networkController: self.networkController)
        destination.calendar = calendar
        ParticipantsFetcher.getParticipants(forCalendar: calendar) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showWorkoutDetailPresent(workout: Workout) {
        let destination = WorkoutViewController(networkController: self.networkController)
        destination.workout = workout
        ParticipantsFetcher.getParticipants(forWorkout: workout) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
    
    func showMindfulnessDetailPresent(mindfulness: Mindfulness) {
        let destination = MindfulnessViewController(networkController: self.networkController)
        destination.mindfulness = mindfulness
        ParticipantsFetcher.getParticipants(forMindfulness: mindfulness) { (participants) in
            destination.selectedFalconUsers = participants
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
            destination.navigationItem.leftBarButtonItem = cancelBarButton
            let navigationViewController = UINavigationController(rootViewController: destination)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}
