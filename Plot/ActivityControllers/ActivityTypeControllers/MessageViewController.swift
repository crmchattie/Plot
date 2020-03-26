//
//  MessageViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    
    let messageText = "Hey! Download Plot on the App Store. https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1"


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Share"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        extendedLayoutIncludesOpaqueBars = true
        
        sendMessage()
    }

    func sendMessage() {
        let shareText = "This is text message to share"
        guard let url = URL(string: "http://swiftdevcenter.com/"),
            let image = UIImage(named: "myImage.png")
            else { return }
        let shareContent: [Any] = [shareText, url, image]
        let activityController = UIActivityViewController(activityItems: shareContent,
                                                          applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)

        //Completion handler
        activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
        Bool, arrayReturnedItems: [Any]?, error: Error?) in
            if completed {
                print("share completed")
                return
            } else {
                print("cancel")
            }
            if let shareError = error {
                print("error while sharing: \(shareError.localizedDescription)")
            }
        }
    }


}

