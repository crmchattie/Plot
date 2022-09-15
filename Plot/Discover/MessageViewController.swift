//
//  MessageViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import LinkPresentation

class MessageViewController: UIViewController, UIActivityItemSource {
    var metadata: LPLinkMetadata?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = .systemGroupedBackground
    
        shareTapped()

    }
    
    // The placeholder the share sheet will use while metadata loads
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return "Hey! Download Plot on the App Store so I can share an activity with you."
    }
    
    // The item we want the user to act on.
    // In this case, it's the URL to the Wikipedia page
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.metadata?.url
    }
    
    // The metadata we want the system to represent as a rich link
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return self.metadata
    }
    
   func shareTapped() {
        guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1") else { return }
        LPMetadataProvider().startFetchingMetadata(for: url) { linkMetadata, _ in
            linkMetadata?.iconProvider = linkMetadata?.imageProvider
            self.metadata = linkMetadata
            let activityController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityController, animated: true, completion: nil)
            }
            activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
            Bool, arrayReturnedItems: [Any]?, error: Error?) in
                if completed {
                    print("share completed")
                    self.dismiss(animated: true, completion: nil)
                    return
                } else {
                    print("cancel")
                    self.dismiss(animated: true, completion: nil)
                }
                if let shareError = error {
                    print("error while sharing: \(shareError.localizedDescription)")
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
//
//print("send message")
//            let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
//            guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
//                let image = UIImage(named: "plotLogo.png")
//                else { return }
//            let shareContent: [Any] = [shareText, url]
//            let activityController = UIActivityViewController(activityItems: shareContent,
//                                                              applicationActivities: nil)
//
//            self.present(activityController, animated: true, completion: nil)

            //Completion handler
            

