//
//  PhotosViewController.swift
//  
//
//  Created by Cory McHattie on 8/7/19.
//

import UIKit
import Firebase
import SDWebImage
import MobileCoreServices
import QuickLook

protocol UpdateActivityMediaDelegate: AnyObject {
    func updateActivityMedia(activityPhotos: [String], activityFiles: [String])
}

class MediaViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var delegate : UpdateActivityMediaDelegate?
    
    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    let cellId = "cellId"
    let avatarOpener = AvatarOpener()
    
    let photosText = NSLocalizedString("Photos", comment: "")
    let filesText = NSLocalizedString("Documents", comment: "")
    
    var segmentedControl: UISegmentedControl!
    let previewVC = QLPreviewController()
    
    var activityID = String()
    var imageURLs = [String]()
    var selectedImageURL = String()
    var images = [UIImage]()
    var selectedImages = [UIImage]()
    var selectedImagesArray = [IndexPath]()
    
    var fileURLs = [String]()
    var selectedFileURL = String()
    var files = [Preview]()
    var selectedFiles = [Preview]()
    var selectedFilesArray = [IndexPath]()
    
    let viewPlaceholder = ViewPlaceholder()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        setupNav()
        avatarOpener.delegate = self
        previewVC.dataSource = self
        
        view.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        fetchPhotos()
        fetchFiles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
        delegate?.updateActivityMedia(activityPhotos: imageURLs, activityFiles: fileURLs)
    }
    
    fileprivate func setupMainView() {
        extendedLayoutIncludesOpaqueBars = true
        
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        
        title = photosText
                
        let segmentTextContent = [
            photosText,
            filesText,
        ]
        
        // Segmented control as the custom title view.
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        if #available(iOS 13.0, *) {
            segmentedControl.overrideUserInterfaceStyle = theme.userInterfaceStyle
        } else {
            // Fallback on earlier versions
        }
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.addTarget(self, action: #selector(action(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ActivityImageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.isUserInteractionEnabled = true
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        view.addSubview(collectionView)
        
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
    }
    
    /// IBAction for the segmented control.
    @IBAction func action(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.title = photosText
        } else {
            self.title = filesText
        }
        setupNav()
        updateBottomBar()
        self.collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        segmentedControl.frame = CGRect(x: view.frame.width * 0.125, y: view.safeAreaInsets.top + 10, width: view.frame.width * 0.75, height: 30)
        var frame = view.frame
        frame.origin.y = segmentedControl.frame.maxY + 10
        frame.size.height -= frame.origin.y
        collectionView.frame = frame
    }
    
    fileprivate func setupNav() {
        let downloadImage = UIImage(named: "downloadNav")
        if segmentedControl.selectedSegmentIndex == 0 {
            if imageURLs.count > 0 || images.count > 0 {
                navigationItem.rightBarButtonItem = nil
                if #available(iOS 11.0, *) {
                    let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(upload))
                    let downloadBarButton = UIButton(type: .system)
                    downloadBarButton.setImage(downloadImage, for: .normal)
                    downloadBarButton.addTarget(self, action: #selector(download), for: .touchUpInside)
                    navigationItem.rightBarButtonItems = [addBarButton, UIBarButtonItem(customView: downloadBarButton)]
                } else {
                    let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(upload))
                    let downloadBarButton = UIBarButtonItem(image: downloadImage, style: .plain, target: self, action: #selector(download))
                    navigationItem.rightBarButtonItems = [addBarButton, downloadBarButton]
                }
            } else {
                navigationItem.rightBarButtonItems = nil
                if #available(iOS 11.0, *) {
                    let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(upload))
                    navigationItem.rightBarButtonItem = addBarButton
                } else {
                    let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(upload))
                    navigationItem.rightBarButtonItem = addBarButton
                }
            }
        } else {
            if fileURLs.count > 0 || files.count > 0 {
                navigationItem.rightBarButtonItem = nil
                if #available(iOS 11.0, *) {
                    let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(upload))
                    let downloadBarButton = UIButton(type: .system)
                    downloadBarButton.setImage(downloadImage, for: .normal)
                    downloadBarButton.addTarget(self, action: #selector(download), for: .touchUpInside)
                    navigationItem.rightBarButtonItems = [addBarButton, UIBarButtonItem(customView: downloadBarButton)]
                } else {
                    let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(upload))
                    let downloadBarButton = UIBarButtonItem(image: downloadImage, style: .plain, target: self, action: #selector(download))
                    navigationItem.rightBarButtonItems = [addBarButton, downloadBarButton]
                }
            } else {
                navigationItem.rightBarButtonItems = nil
                if #available(iOS 11.0, *) {
                    let addBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(upload))
                    navigationItem.rightBarButtonItem = addBarButton
                } else {
                    let addBarButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(upload))
                    navigationItem.rightBarButtonItem = addBarButton
                }
            }
        }
    }
    
    fileprivate func fetchPhotos() {
        for imageURL in imageURLs {
            activityIndicatorView.startAnimating()
            guard let url = URL(string: imageURL) else {
                print("no URL")
                return
            }
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url)
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        activityIndicatorView.stopAnimating()
                        self.images.append(image)
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    fileprivate func fetchFiles() {
        for fileURL in fileURLs {
            guard let url = URL(string: fileURL) else {
                print("no URL")
                return
            }
            DispatchQueue.global().async {
                let ref = Storage.storage().reference().child("activityDocs").child(url.deletingPathExtension().lastPathComponent)
                // Get metadata properties
                ref.getMetadata { metadata, error in
                  if let _ = error {
                    // Uh-oh, an error occurred!
                  } else {
                    let data = try? Data(contentsOf: url)
                    if let data = data, let type = metadata!.customMetadata!["type"], let name = metadata!.customMetadata!["name"] {
                        DispatchQueue.main.async {
                            do {
                                // rename the temporary file or save it to the document or library directory if you want to keep the file
                                let suggestedFilename = url.deletingPathExtension().lastPathComponent + ".\(type)"
                                let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
                                try data.write(to: previewURL, options: .atomic)   // atomic option overwrites it if needed
                                let file = Preview(url: previewURL, displayName: name, fileName: previewURL.lastPathComponent, fileExtension: type)
                                if #available(iOS 13.0, *) {
                                    let previewGenerator = QLThumbnailGenerator()
                                    let scale = UIScreen.main.scale
                                    let request = QLThumbnailGenerator.Request(fileAt: previewURL, size: CGSize(width: (self.view.frame.width - 3) / 4, height: (self.view.frame.width - 3) / 4), scale: scale, representationTypes: .all)
                                    previewGenerator.generateBestRepresentation(for: request) { (thumbnail, error) in
                                        if let error = error {
                                            print(error.localizedDescription)
                                        } else if let thumb = thumbnail {
                                            file.thumbnail = thumb.uiImage
                                        }
                                    }
                                    self.files.append(file)
                                    self.collectionView.reloadData()
                                } else {
                                    self.files.append(file)
                                    self.collectionView.reloadData()
                                    // Fallback on earlier versions
                                }
                            } catch {
                                print(error)
                                return
                            }
                        }
                    }
                    // Metadata now contains the metadata for 'images/forest.jpg'
                  }
                }
            }
        }
    }
    
    func checkIfThereAnyItems() {
//        setupNav()
        if segmentedControl.selectedSegmentIndex == 0 {
            if imageURLs.count > 0 || images.count > 0 {
                viewPlaceholder.remove(from: view, priority: .medium)
            } else {
                viewPlaceholder.add(for: view, title: .emptyPhotos, subtitle: .emptyPhotos, priority: .medium, position: .top)
            }
        } else {
            if fileURLs.count > 0 || files.count > 0 {
                viewPlaceholder.remove(from: view, priority: .medium)
            } else {
                viewPlaceholder.add(for: view, title: .emptyFiles, subtitle: .emptyFiles, priority: .medium, position: .top)
            }
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if segmentedControl.selectedSegmentIndex == 0 {
            if navigationItem.rightBarButtonItem?.title != "Cancel" {
                selectedImageURL = imageURLs[indexPath.item]
                let imageView = (collectionView.cellForItem(at: indexPath) as! ActivityImageCell).photoImageView
                avatarOpener.handleAvatarOpening(avatarView: imageView, at: self,
                                                 isEditButtonEnabled: true, title: .activities)
            } else {
                if selectedImagesArray.contains(indexPath) {
                    if let index = self.selectedImagesArray.firstIndex(of: indexPath) {
                        selectedImagesArray.remove(at: index)
                        selectedImages.remove(at: index)
                    }
                } else {
                    selectedImagesArray.append(indexPath)
                    selectedImages.append(images[indexPath.item])
                }
            }
        } else {
            if navigationItem.rightBarButtonItem?.title != "Cancel" {
                previewVC.currentPreviewItemIndex = indexPath.row
                present(previewVC, animated: true)
            } else {
                if selectedFilesArray.contains(indexPath) {
                    if let index = self.selectedFilesArray.firstIndex(of: indexPath) {
                        selectedFilesArray.remove(at: index)
                        selectedFiles.remove(at: index)
                    }
                } else {
                    selectedFilesArray.append(indexPath)
                    selectedFiles.append(files[indexPath.item])
                }
            }
        }
        self.collectionView.reloadData()
        updateBottomBar()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        checkIfThereAnyItems()
        if segmentedControl.selectedSegmentIndex == 0 {
            print("images.count \(images.count)")
            return images.count
        } else {
            print("files.count \(files.count)")
            return files.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ActivityImageCell
        //        cell.photoImageView.sd_setImage(with: URL(string:imageURLs[indexPath.item]), placeholderImage: nil, options: [.continueInBackground, .scaleDownLargeImages], completed: { (image, error, cacheType, url) in
        //        })
        if segmentedControl.selectedSegmentIndex == 0 {
            cell.photoImageView.image = images[indexPath.item]
            if selectedImagesArray.contains(indexPath) {
                cell.selectedImageCheck.isHidden = false
            } else {
                cell.selectedImageCheck.isHidden = true
            }
        } else {
            if let thumb = files[indexPath.item].thumbnail {
                cell.photoImageView.image = thumb
                if selectedFilesArray.contains(indexPath) {
                    cell.selectedImageCheck.isHidden = false
                } else {
                    cell.selectedImageCheck.isHidden = true
                }
            }
        }
        return cell
    }
    
    fileprivate func updateBottomBar() {
        if segmentedControl.selectedSegmentIndex == 0 {
            if selectedImagesArray.count > 0 {
                navigationController?.isToolbarHidden = false
                let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(toolbarTouchHandler))
                let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteItems))
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                navigationController?.toolbar.setItems([item, flexibleSpace, trash], animated: true)
            } else {
                navigationController?.isToolbarHidden = true
            }
        } else {
            if selectedFilesArray.count > 0 {
                navigationController?.isToolbarHidden = false
                let item = UIBarButtonItem(image: UIImage(named: "ShareExternalIcon"), style: .plain, target: self, action: #selector(toolbarTouchHandler))
                let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteItems))
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                navigationController?.toolbar.setItems([item, flexibleSpace, trash], animated: true)
            } else {
                navigationController?.isToolbarHidden = true
            }
        }
    }
    
    @objc fileprivate func upload() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        if segmentedControl.selectedSegmentIndex == 0 {
            avatarOpener.delegate = self
            avatarOpener.handleAvatarOpeningActivity(at: self,
                                                     isEditButtonEnabled: true, title: .activities)
        } else {
            let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text", "com.apple.iwork.pages.pages", "public.data"], in: .import)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = true
            present(documentPicker, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func download() {
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDownload))
        navigationItem.rightBarButtonItems = [cancelBarButton]
    }
    
    @objc fileprivate func cancelDownload() {
        setupNav()
        if segmentedControl.selectedSegmentIndex == 0 {
            selectedImagesArray = [IndexPath]()
            selectedImages = [UIImage]()
        } else {
            selectedFilesArray = [IndexPath]()
            selectedFiles = [Preview]()
        }
        navigationController?.isToolbarHidden = true
        collectionView.reloadData()
    }
    
    @objc fileprivate func toolbarTouchHandler() {
        let activity = UIActivityViewController(activityItems: selectedImages, applicationActivities: nil) //possible error
        self.present(activity, animated: true, completion: nil)
    }
    
    @objc fileprivate func deleteItems() {
        if segmentedControl.selectedSegmentIndex == 0 {
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
//            checkIfThereAnyItems()
            collectionView.reloadData()
            setupNav()
            activityReference.updateChildValues(["activityPhotos": self.imageURLs as AnyObject])
            cancelDownload()
        } else {
            let storage = Storage.storage()
            let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
            let fileUpdatingGroup = DispatchGroup()
            for file in selectedFiles {
                fileUpdatingGroup.enter()
                if let index = self.files.firstIndex(of: file) {
                    let url = fileURLs[index]
                    let storageReference = storage.reference(forURL: url)
                    storageReference.delete { _ in }
                    files.remove(at: index)
                    fileURLs.remove(at: index)
                }
                fileUpdatingGroup.leave()
            }
//            checkIfThereAnyItems()
            collectionView.reloadData()
            setupNav()
            activityReference.updateChildValues(["activityFiles": self.fileURLs as AnyObject])
            cancelDownload()
        }
    }
}

extension MediaViewController: AvatarOpenerDelegate {
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
        collectionView.reloadData()
        setupNav()
//        checkIfThereAnyItems()
        let lastItemIndex = NSIndexPath(item: images.count - 1, section: 0)
        collectionView.scrollToItem(at: lastItemIndex as IndexPath, at: .bottom, animated: true)
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
//        checkIfThereAnyItems()
        collectionView.reloadData()
        setupNav()
    }
}

extension MediaViewController { // delete
    typealias CurrentPictureDeletionCompletionHandler = (_ success: Bool) -> Void
    func deleteCurrentPhoto(completion: @escaping CurrentPictureDeletionCompletionHandler) {
        guard self.selectedImageURL != "" else { completion(true); return }
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: self.selectedImageURL)
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        if let index = imageURLs.firstIndex(of: self.selectedImageURL) {
            imageURLs.remove(at: index)
            images.remove(at: index)
//            checkIfThereAnyItems()
            collectionView.reloadData()
            setupNav()
        }
        
        storageReference.delete { _ in
            activityReference.updateChildValues(["activityPhotos": self.imageURLs as AnyObject])
            completion(true)
        }
    }
}

extension MediaViewController { // update
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
//                self.checkIfThereAnyItems()
                activityReference.updateChildValues([imageElement.key: self.imageURLs], withCompletionBlock: { (_, _) in
                    photoUpdatingGroup.leave()
                })
            }
        }
        
        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            self.collectionView.reloadData()
            self.setupNav()
            completion(true)
        })
    }
}

extension MediaViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let fileUpdatingGroup = DispatchGroup()
        fileUpdatingGroup.enter()
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        print("picked url \(url.deletingPathExtension().lastPathComponent)")
        let file = Preview(url: url, displayName: url.deletingPathExtension().lastPathComponent, fileName: url.deletingPathExtension().lastPathComponent, fileExtension: url.pathExtension)
        if #available(iOS 13.0, *) {
            let previewGenerator = QLThumbnailGenerator()
            let scale = UIScreen.main.scale
            let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: (self.view.frame.width - 3) / 4, height: (self.view.frame.width - 3) / 4), scale: scale, representationTypes: .all)
            previewGenerator.generateBestRepresentation(for: request) { (thumbnail, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else if let thumb = thumbnail {
                    file.thumbnail = thumb.uiImage
                    self.files.append(file)
                    fileUpdatingGroup.leave()
                }
            }
        } else {
            files.append(file)
            fileUpdatingGroup.leave()
            // Fallback on earlier versions
        }
        fileUpdatingGroup.enter()
        uploadDocToFirebaseStorage(url, contentType: mimeTypeForPath(pathExtension: url.pathExtension), name: url.deletingPathExtension().lastPathComponent) { (url) in
            self.fileURLs.append(url)
            activityReference.updateChildValues(["activityFiles": self.fileURLs], withCompletionBlock: { (_, _) in
                fileUpdatingGroup.leave()
            })
        }
        
        fileUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            self.collectionView.reloadData()
            self.setupNav()
        })
    }
    
    func mimeTypeForPath(pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

}

extension MediaViewController {
    typealias CurrentFileDeletionCompletionHandler = (_ success: Bool) -> Void
    func deleteDocs(completion: @escaping CurrentFileDeletionCompletionHandler) {
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: self.selectedFileURL)
        let activityReference = Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder)
        
        if let index = fileURLs.firstIndex(of: self.selectedFileURL) {
            fileURLs.remove(at: index)
            files.remove(at: index)
//            checkIfThereAnyItems()
            collectionView.reloadData()
        }
        
        storageReference.delete { _ in
            activityReference.updateChildValues(["activityFiles": self.fileURLs as AnyObject])
        }
    }
}

extension MediaViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return files.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return files[index]
    }
}


