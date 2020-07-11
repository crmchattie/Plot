//
//  BaseActivityMessageCell.swift
//  Plot
//
//  Created by Cory McHattie on 3/29/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import SDWebImage

class BaseActivityMessageCell: BaseMessageCell {
    
    lazy var messageImageView: UIImageView = {
        let messageImageView = UIImageView()
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.layer.masksToBounds = true
        messageImageView.isUserInteractionEnabled = false
        messageImageView.layer.cornerRadius = 15
        messageImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return messageImageView
    }()
  
    var progressView: CircleProgress = {
        let progressView = CircleProgress()
        progressView.translatesAutoresizingMaskIntoConstraints = false

        return progressView
    }()
  
    func setupImageFromLocalData(message: Message, image: UIImage) {
        messageImageView.image = image
        progressView.isHidden = true
        messageImageView.isUserInteractionEnabled = false
    }
  
    func setupImageFromURL(message: Message, messageImageUrl: URL) {
        if message.activityImageURL == "workout" || message.activityImageURL == "activityLarge" || message.activityImageURL == "meal" || message.activityImageURL == "recreation" || message.activityImageURL == "nightlife" || message.activityImageURL == "shopping" || message.activityImageURL == "event" || message.activityImageURL == "sightseeing" || message.activityImageURL == "chef" || message.activityImageURL == "trending" {
            messageImageView.image = UIImage(named: message.activityImageURL ?? "activityLarge")?.withRenderingMode(.alwaysTemplate)
            messageImageView.tintColor = UIColor.white
            messageImageView.backgroundColor = FalconPalette.defaultDarkBlue
        } else {
            progressView.startLoading()
            progressView.isHidden = false
            let options:SDWebImageOptions = [.continueInBackground, .lowPriority, .scaleDownLargeImages]
            messageImageView.sd_setImage(with: messageImageUrl, placeholderImage: nil, options: options, progress: { (_, _, _) in
              
                DispatchQueue.main.async {
                    self.progressView.progress = self.messageImageView.sd_imageProgress.fractionCompleted
                }
              
                }, completed: { (_, error, _, _) in
              
                if error != nil {
                    self.progressView.isHidden = false
                    return
                }
                self.progressView.isHidden = true
            })
        }
    }
    
    @objc func goToActivity(_ tapGesture: UITapGestureRecognizer) {
        guard let message = self.message else {
            return
        }
        self.chatLogController?.goToActivity(message: message)
    }

}
