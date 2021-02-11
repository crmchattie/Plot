//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Cory McHattie on 8/21/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Firebase

class ShareViewController: UIViewController {
    
    fileprivate var activitiesArray = [Activity]()
    fileprivate var filteredActivities = [Activity]()
    fileprivate var activity: Activity!
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    private var sharedContainer : UserDefaults?
    private var vSpinner : UIView?
    let dispatchGroup = DispatchGroup()

    var searchExtensionController: UISearchController?
    var searchBar: UISearchBar?
    
        
    let shareHeaderView = ShareHeaderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _ = Auth.auth().currentUser
        sharedContainer = UserDefaults(suiteName: plotAppGroup)
        fetchDataFromSharedContainer()
        setupUI()
        setupNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
        
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.transform = CGAffineTransform.identity
        })
    }
    
    fileprivate func setupUI() {
        view.addSubview(shareHeaderView)
        shareHeaderView.frame = view.bounds
        shareHeaderView.tableView.dataSource = self
        shareHeaderView.tableView.delegate = self
        shareHeaderView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifiers.ActivityCell)
        shareHeaderView.tableView.rowHeight = UITableView.automaticDimension
        shareHeaderView.tableView.estimatedRowHeight = 40
        shareHeaderView.tableView.separatorStyle = .none
    }
    
    fileprivate func setupNavBar() {
        let navigationItem = UINavigationItem()
        let leftButton =  UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelection))
        
        navigationItem.title = "Select Activity"
        navigationItem.leftBarButtonItem = leftButton
        shareHeaderView.navBar.items = [navigationItem]
    }

    
    // This method fetches the data to be displayed in widget from shared container.
    fileprivate func fetchDataFromSharedContainer() {
        if let sharedContainer = sharedContainer, let activities = sharedContainer.array(forKey: "ActivitiesArray") {
            for activity in activities {
                let decodedData = NSKeyedUnarchiver.unarchiveObject(with: activity as! Data) as! [String: AnyObject]
                let decodedActivity = Activity(dictionary: decodedData)
                if decodedActivity.recipeID != nil || decodedActivity.workoutID != nil || decodedActivity.eventID != nil {
                    continue
                }
                activitiesArray.append(decodedActivity)
            }
        }
    }
    
    private func getItem(activity: Activity) {
        var type = ""
        var fileURL: URL!
        var data: Data!
        if let item = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            var images = [UIImage]()
            for ele in item.attachments! {
                dispatchGroup.enter()
                print("item.attachments!======&gt;&gt;&gt; \(ele)")
                let itemProvider = ele
                print(itemProvider)
                if itemProvider.hasItemConformingToTypeIdentifier("public.jpeg") {
                    type = "public.jpeg"
                    itemProvider.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { (item, error) in
                        var imgData: Data!
                        if let url = item as? URL {
                            imgData = try! Data(contentsOf: url)
                            if let img = UIImage(data: imgData) {
                                images.append(img)
                                self.dispatchGroup.leave()
                            }
                        }
                    })
                } else if itemProvider.hasItemConformingToTypeIdentifier("public.png") {
                    type = "public.png"
                    itemProvider.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { (item, error) in
                        var imgData: Data!
                        if let url = item as? URL {
                            imgData = try! Data(contentsOf: url)
                            if let img = UIImage(data: imgData) {
                                images.append(img)
                                self.dispatchGroup.leave()
                            }
                        }
                    })
                } else if itemProvider.hasItemConformingToTypeIdentifier("public.file-url") {
                    type = "public.file-url"
                    itemProvider.loadItem(forTypeIdentifier: type, options: nil, completionHandler: { (item, error) in
                        if let url = item as? URL {
                            fileURL = url
                            data = try! Data(contentsOf: url)
                            self.dispatchGroup.leave()
                        }
                    })
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                if type == "public.jpeg" || type == "public.png" {
                    self.storeImages(images: images, activity: activity)
                } else if type == "public.file-url" {
                    self.storeFiles(data: data, url: fileURL, activity: activity)
                }
            })
        }
    }
    
    private func storeImages(images: [UIImage], activity: Activity) {
        var imageList = [(image: UIImage, quality: CGFloat, key: String)]()
        var imageURLs = [String]()
        if activity.activityPhotos != nil {
            imageURLs = activity.activityPhotos!
        } else {
            imageURLs = [String]()
        }
        
        for image in images {
            imageList.append((image: image, quality: 0.5, key: "activityPhotos"))
            dispatchGroup.enter()
        }
    
        for imageElement in imageList {
            uploadAvatarForActivityToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
                imageURLs.append(url)
                self.dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            if !imageURLs.isEmpty {
                let activityReference = Database.database().reference().child("activities").child(activity.activityID!).child("metaData")
                activityReference.updateChildValues(["activityPhotos": imageURLs])
            }
            self.hideActivityIndicator()
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        })
    }
    
    func uploadAvatarForActivityToFirebaseStorageUsingImage(_ image: UIImage, quality: CGFloat, completion: @escaping (_  imageUrl: String) -> ()) {
        let imageName = UUID().uuidString
        let ref = Storage.storage().reference().child("activityImages").child(imageName)
        
        if let uploadData = image.jpegData(compressionQuality: quality) {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                guard error == nil else { completion(""); return }
                
                ref.downloadURL(completion: { (url, error) in
                    guard error == nil, let imageURL = url else { completion(""); return }
                    completion(imageURL.absoluteString)
                })
            }
        }
    }
    
    private func storeFiles(data: Data, url: URL, activity: Activity) {
        dispatchGroup.enter()
        var fileURLs = [String]()
        if activity.activityFiles != nil {
            fileURLs = activity.activityFiles!
        } else {
            fileURLs = [String]()
        }
        uploadDocToFirebaseStorage(data, contentType: mimeTypeForPath(pathExtension: url.pathExtension), type: url.pathExtension, name: url.deletingPathExtension().lastPathComponent) { (url) in
            fileURLs.append(url)
            self.dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            if !fileURLs.isEmpty {
                let activityReference = Database.database().reference().child("activities").child(activity.activityID!).child("metaData")
                activityReference.updateChildValues(["activityFiles": fileURLs])
            }
            self.hideActivityIndicator()
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        })
    }
    
    func uploadDocToFirebaseStorage(_ data: Data, contentType: String, type: String, name: String, completion: @escaping (_  url: String) -> ()) {
        let fileName = UUID().uuidString
        let ref = Storage.storage().reference().child("activityDocs").child(fileName)
        
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        metadata.customMetadata = ["name": name, "type": type]
            
        ref.putData(data, metadata: metadata) { (metadata, error) in
            guard error == nil else { completion(""); return }
            
            ref.downloadURL(completion: { (url, error) in
                guard error == nil, let imageURL = url else { completion(""); return }
                completion(imageURL.absoluteString)
            })
        }
    }
    
    @objc func cancelSelection() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    func handleReloadTableAfterSearch() {
        filteredActivities.sort { (activity1, activity2) -> Bool in
            return activity1.startDateTime!.int64Value < activity2.startDateTime!.int64Value
        }
        DispatchQueue.main.async {
            self.shareHeaderView.tableView.reloadData()
        }
    }
    
    func showActivityIndicator() {
        self.showSpinner(onView: self.view)
        self.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.25)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
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

extension ShareViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activitiesArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ActivityCell, for: indexPath) as? ActivityCell ?? ActivityCell()
        
        let activity = activitiesArray[indexPath.row]
        cell.configureCell(for: indexPath, activity: activity)
        return cell
    }
}

extension ShareViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = activitiesArray[indexPath.item]
        showActivityIndicator()
        getItem(activity: activity)
    }
}

extension ShareViewController {
    struct Identifiers {
        static let ActivityCell = "activityCell"
    }
    
}

extension ShareViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredActivities = searchText.isEmpty ? activitiesArray :
            activitiesArray.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        return true
    }
}

extension ShareViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchExtensionController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchExtensionController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}
