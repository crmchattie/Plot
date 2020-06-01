//
//  PhotosViewController.swift
//  
//
//  Created by Cory McHattie on 8/7/19.
//

import UIKit
import Firebase
import SDWebImage

protocol UpdateActivityPhotosDelegate: class {
    func updateActivityPhotos(activityPhotos: [String])
}

class PhotosViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    weak var delegate : UpdateActivityPhotosDelegate?
    
    let cellId = "cellId"
    let avatarOpener = AvatarOpener()
    var activityID = String()
    
    var imageURLs = [String]()
    var selectedImageURL = String()
    var images = [UIImage]()
    var selectedImages = [UIImage]()
    var selectedArray = [IndexPath]()
    let viewPlaceholder = ViewPlaceholder()
    
    fileprivate var movingBackwards: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        setupNav()
        avatarOpener.delegate = self
        collectionView?.register(ActivityImageCell.self, forCellWithReuseIdentifier: cellId)
        fetchPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)        
        if self.movingBackwards {
            print("moving backwards")
            delegate?.updateActivityPhotos(activityPhotos: imageURLs)
        }
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        navigationItem.title = "Activity Photos"
        collectionView?.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
    
    fileprivate func setupNav() {
        let downloadImage = UIImage(named: "downloadNav")
        if imageURLs.count > 0 || images.count > 0 {
            navigationItem.rightBarButtonItem = nil
            if #available(iOS 11.0, *) {
                let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadImage))
                let downloadBarButton = UIButton(type: .system)
                downloadBarButton.setImage(downloadImage, for: .normal)
                downloadBarButton.addTarget(self, action: #selector(downloadImages), for: .touchUpInside)
                navigationItem.rightBarButtonItems = [addBarButton, UIBarButtonItem(customView: downloadBarButton)]
            } else {
                let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(uploadImage))
                let downloadBarButton = UIBarButtonItem(image: downloadImage, style: .plain, target: self, action: #selector(downloadImages))
                navigationItem.rightBarButtonItems = [addBarButton, downloadBarButton]
            }
        } else {
            navigationItem.rightBarButtonItems = nil
            if #available(iOS 11.0, *) {
                let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(uploadImage))
                navigationItem.rightBarButtonItem = addBarButton
            } else {
                let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(uploadImage))
                navigationItem.rightBarButtonItem = addBarButton
            }
        }
    }
    
    fileprivate func fetchPhotos() {
        for imageURL in imageURLs {
            guard let url = URL(string: imageURL) else {
                print("no URL")
                return
            }
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url)
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                        self.collectionView?.reloadData()
                        self.checkIfThereAnyPhotos()
                    }
                }
            }
        }
        checkIfThereAnyPhotos()
    }
    
    func checkIfThereAnyPhotos() {
        setupNav()
        if imageURLs.count > 0 || images.count > 0 {
            viewPlaceholder.remove(from: view, priority: .medium)
        } else {
            viewPlaceholder.add(for: view, title: .emptyPhotos, subtitle: .emptyPhotos, priority: .medium, position: .top)
        }
        collectionView?.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if navigationItem.rightBarButtonItem?.title != "Cancel" {
            selectedImageURL = imageURLs[indexPath.item]
            let imageView = (collectionView.cellForItem(at: indexPath) as! ActivityImageCell).photoImageView
            avatarOpener.handleAvatarOpening(avatarView: imageView, at: self,
                                             isEditButtonEnabled: true, title: .activities)
        } else {
            if selectedArray.contains(indexPath) {
                if let index = self.selectedArray.firstIndex(of: indexPath) {
                    selectedArray.remove(at: index)
                    selectedImages.remove(at: index)
                }
            } else {
                selectedArray.append(indexPath)
                selectedImages.append(images[indexPath.item])
            }
            self.collectionView?.reloadData()
            updateBottomBar()
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ActivityImageCell
//        cell.photoImageView.sd_setImage(with: URL(string:imageURLs[indexPath.item]), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
//        })
        cell.photoImageView.image = images[indexPath.item]
        if selectedArray.contains(indexPath) {
            cell.selectedImageCheck.isHidden = false
        } else {
            cell.selectedImageCheck.isHidden = true
        }
        return cell
    }
    
    fileprivate func updateBottomBar() {
        if selectedArray.count > 0 {
            navigationController?.isToolbarHidden = false
            let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(toolbarTouchHandler))
            let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteImages))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            navigationController?.toolbar.setItems([item, flexibleSpace, trash], animated: true)
        } else {
            navigationController?.isToolbarHidden = true
        }
    }

    @objc fileprivate func uploadImage() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        avatarOpener.delegate = self
        avatarOpener.handleAvatarOpeningActivity(at: self,
                                         isEditButtonEnabled: true, title: .activities)
        
    }
    
    @objc fileprivate func downloadImages() {
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDownload))
        navigationItem.rightBarButtonItems = [cancelBarButton]
    }
    
    @objc fileprivate func cancelDownload() {
        setupNav()
        selectedArray = [IndexPath]()
        selectedImages = [UIImage]()
        navigationController?.isToolbarHidden = true
        collectionView?.reloadData()
    }
    
    @objc fileprivate func toolbarTouchHandler() {
        let activity = UIActivityViewController(activityItems: selectedImages, applicationActivities: nil) //possible error
        self.present(activity, animated: true, completion: nil)
    }
    
    @objc fileprivate func deleteImages() {
        let storage = Storage.storage()
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        let photoUpdatingGroup = DispatchGroup()
        
        for image in selectedImages {
            photoUpdatingGroup.enter()
            if let index = self.images.firstIndex(of: image) {
                let url = imageURLs[index]
                let storageReference = storage.reference(forURL: url)
                storageReference.delete { _ in }
                images.remove(at: index)
                imageURLs.remove(at: index)
            }
            photoUpdatingGroup.leave()
        }
        checkIfThereAnyPhotos()
        activityReference.updateChildValues(["activityPhotos": self.imageURLs as AnyObject])
        cancelDownload()
    }
}

extension PhotosViewController: AvatarOpenerDelegate {
    func avatarOpener(avatarPickerDidPick image: UIImage) {
        print("avatar opening delegate")
        navigationController?.view.isUserInteractionEnabled = false
        deleteCurrentPhoto { (_) in
            self.updateActivityImage(with: image, completion: { (isUpdated) in
                self.navigationController?.view.isUserInteractionEnabled = true
                guard isUpdated else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: thumbnailUploadError, controller: self)
                    return
                }
            })
        }
        images.append(image)
        checkIfThereAnyPhotos()
        let lastItemIndex = NSIndexPath(item: images.count - 1, section: 0)
        collectionView?.scrollToItem(at: lastItemIndex as IndexPath, at: .bottom, animated: true)
    }
    
    func avatarOpener(didPerformDeletionAction: Bool) {
        navigationController?.view.isUserInteractionEnabled = false
        deleteCurrentPhoto { (isDeleted) in
            self.navigationController?.view.isUserInteractionEnabled = true
            guard isDeleted else {
                basicErrorAlertWith(title: basicErrorTitleForAlert, message: deletionErrorMessage, controller: self)
                return
            }
        }
        checkIfThereAnyPhotos()
    }
}

extension PhotosViewController { // delete
    
    typealias CurrentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
    func deleteCurrentPhoto(completion: @escaping CurrentPictureDeletionCompletionHandler) {
        guard self.selectedImageURL != "" else { completion(true); return }
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: self.selectedImageURL)
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        if let index = imageURLs.firstIndex(of: self.selectedImageURL) {
            imageURLs.remove(at: index)
            images.remove(at: index)
            checkIfThereAnyPhotos()
        }

        storageReference.delete { _ in
            activityReference.updateChildValues(["activityPhotos": self.imageURLs as AnyObject])
            completion(true)
        }
    }
}

extension PhotosViewController { // update
    
    typealias UpdateActivityImageCompletionHandler = (_ success: Bool) -> Void
    func updateActivityImage(with image: UIImage, completion: @escaping UpdateActivityImageCompletionHandler) {
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        var images = [(image: UIImage, quality: CGFloat, key: String)]()
        images.append((image: image, quality: 0.5, key: "activityPhotos"))
        
        let photoUpdatingGroup = DispatchGroup()
        for _ in images {
            photoUpdatingGroup.enter()
        }
        
        for imageElement in images {
            uploadAvatarForActivityToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
                self.imageURLs.append(url)
                self.checkIfThereAnyPhotos()
                activityReference.updateChildValues([imageElement.key: self.imageURLs], withCompletionBlock: { (_, _) in
                    photoUpdatingGroup.leave()
                })
            }
        }
        
        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            completion(true)
        })
    }
}

