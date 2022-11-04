//
//  MasterActivityContainerController+StartupMethods.swift
//  Plot
//
//  Created by Cory McHattie on 7/1/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

extension MasterActivityContainerController {
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        networkController.reloadKeyVariables {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func openNotification() {
        print("openNotification")
        //remove to open notifications
        if let notification = notification {
            self.notification = nil
            openNotification(forNotification: notification)
            print(notification)
        }
    }
}
