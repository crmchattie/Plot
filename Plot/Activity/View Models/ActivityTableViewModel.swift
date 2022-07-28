//
//  ActivityTableViewModel.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 6/7/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

//import Foundation

//extension ActivityTableViewController {
//
//    class ViewModel {
//
//        private var activities: [Activity]
//
//        var numberOfActivities: Int {
//            return activities.count
//        }
//
//        private func activity(at index: Int) -> Activity {
//            return activities[index]
//        }
//
////        func title(at index: Int) -> String {
////            return toDo(at: index).title ?? ""
////        }
//
////        func dueDateText(at index: Int) -> String {
////            let date = toDo(at: index).dueDate
////            return dateFormatter.string(from: date)
////        }
//
//        func editViewModel(at index: Int) -> CreateActivityViewController.ViewModel {
//            let activity = self.activity(at: index)
//            let editViewModel = CreateActivityViewController.ViewModel(activity: activity)
//            return editViewModel
//        }
//
//        func addViewModel() -> CreateActivityViewController.ViewModel {
//            let activity = Activity()
//            activities.append(activity)
//            let addViewModel = CreateActivityViewController.ViewModel(activity: activity)
//            return addViewModel
//        }
//
////        @objc private func removeActivity(_ notification: Notification) {
////            guard let userInfo = notification.userInfo,
////                let activity = userInfo[Notification.Name.deleteActivityNotification] as? Activity,
////                let index = activity.index(of: activity) else {
////                    return
////            }
////            activities.remove(at: index)
////        }
//
//        // MARK: Life Cycle
//        init(activities: [Activity] = []) {
//            self.activities = activities
//
////            NotificationCenter.default.addObserver(self, selector: #selector(removeActivity(_:)(_:)), name: .deleteActivityNotification, object: nil)
//        }
//
//        deinit {
//            NotificationCenter.default.removeObserver(self)
//        }
//    }
//}

