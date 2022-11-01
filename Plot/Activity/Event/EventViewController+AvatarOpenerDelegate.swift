//
//  ActivityAvatarOpenerDelegate.swift
//  Plot
//
//  Created by Cory McHattie on 7/2/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import ViewRow


extension EventViewController: AvatarOpenerDelegate {
    func avatarOpener(avatarPickerDidPick image: UIImage) {
        navigationController?.view.isUserInteractionEnabled = false
        let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
        viewRow.cell.view!.showActivityIndicator()
        deleteCurrentPhoto { (_) in
            self.updateActivityImage(with: image, completion: { (isUpdated) in
                viewRow.cell.view!.hideActivityIndicator()
                self.navigationController?.view.isUserInteractionEnabled = true
                guard isUpdated else {
                    basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self)
                    return
                }
            })
        }
        viewRow.title = nil
        viewRow.cell.height = { return CGFloat(300) }
        viewRow.cell.view!.image = image
        self.tableView.reloadData()
    }
    
    func avatarOpener(didPerformDeletionAction: Bool) {
        navigationController?.view.isUserInteractionEnabled = false
        let viewRow: ViewRow<UIImageView> = form.rowBy(tag: "Activity Image")!
        viewRow.cell.view!.showActivityIndicator()
        deleteCurrentPhoto { (isDeleted) in
            self.navigationController?.view.isUserInteractionEnabled = true
            viewRow.cell.view!.hideActivityIndicator()
            guard isDeleted else {
                basicErrorAlertWithClose(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self)
                return
            }
        }
        viewRow.cell.view!.image = nil
        viewRow.cell.height = { return CGFloat(44) }
        viewRow.title = "Cover Photo"
        self.tableView.reloadData()
    }
}

extension EventViewController { // delete
    
    typealias CurrentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
    func deleteCurrentPhoto(completion: @escaping CurrentPictureDeletionCompletionHandler) {
        guard activityAvatarURL != "" else { completion(true); return }
        print("activityAvatarURL does not equal nil")
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: activityAvatarURL)
        let activityMetaReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        self.activityAvatarURL = ""
        self.thumbnailImage = ""
        self.activity.activityOriginalPhotoURL = self.activityAvatarURL
        self.activity.activityThumbnailPhotoURL = self.thumbnailImage

        storageReference.delete { _ in
            let activityOriginalPhotoURLReference = activityMetaReference.child("activityOriginalPhotoURL")
            let activityThumbnailPhotoURLReference = activityMetaReference.child("activityThumbnailPhotoURL")
            activityOriginalPhotoURLReference.setValue(self.activity.activityOriginalPhotoURL)
            activityThumbnailPhotoURLReference.setValue(self.activity.activityThumbnailPhotoURL)
            completion(true)
        }
    }
}

extension EventViewController { // update
    
    typealias UpdateActivityImageCompletionHandler = (_ success: Bool) -> Void
    func updateActivityImage(with image: UIImage, completion: @escaping UpdateActivityImageCompletionHandler) {
        let userReference = Database.database().reference().child(activitiesEntity).child(activityID).child(messageMetaDataFirebaseFolder)
        let thumbnailImage = createImageThumbnail(image)
        var images = [(image: UIImage, quality: CGFloat, key: String)]()
        images.append((image: image, quality: 0.5, key: "activityOriginalPhotoURL"))
        images.append((image: thumbnailImage, quality: 1, key: "activityThumbnailPhotoURL"))
        
        let photoUpdatingGroup = DispatchGroup()
        for _ in images { photoUpdatingGroup.enter() }
        
        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            completion(true)
        })
    
        for imageElement in images {
            uploadImageToFirebaseStorage(imageElement.image, quality: imageElement.quality) { (url) in
                userReference.updateChildValues([imageElement.key: url], withCompletionBlock: { (_, _) in
                    photoUpdatingGroup.leave()
                })
                if imageElement.key == "activityOriginalPhotoURL" {
                    self.activityAvatarURL = url
                } else {
                    self.thumbnailImage = url
                }
            }
        }
    }
}
