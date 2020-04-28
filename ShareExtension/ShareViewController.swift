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
    fileprivate var imageURLs = [String]()
    fileprivate let plotAppGroup = "group.immaturecreations.plot"
    private var sharedContainer : UserDefaults?
    private var url: NSURL?
    private var imageType = ""
    private var vSpinner : UIView?
    let photoUpdatingGroup = DispatchGroup()

    
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
    
    private func getImage(activity: Activity){
        if let item = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            var images = [UIImage]()
            for ele in item.attachments! {
                photoUpdatingGroup.enter()
                print("item.attachments!======&gt;&gt;&gt; \(ele )")
                let itemProvider = ele
                print(itemProvider)
                if itemProvider.hasItemConformingToTypeIdentifier("public.jpeg") {
                    imageType = "public.jpeg"
                }
                if itemProvider.hasItemConformingToTypeIdentifier("public.png") {
                    imageType = "public.png"
                }
                
                if itemProvider.hasItemConformingToTypeIdentifier(imageType){
                    itemProvider.loadItem(forTypeIdentifier: imageType, options: nil, completionHandler: { (item, error) in
                        
                        var imgData: Data!
                        if let url = item as? URL {
                            imgData = try! Data(contentsOf: url)
                            if let img = UIImage(data: imgData) {
                                images.append(img)
                                self.photoUpdatingGroup.leave()
                            }
                        }
                    })
                }
            }
            photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
                self.storeImages(images: images, activity: activity)
            })
        }
    }
    
    private func storeImages(images: [UIImage], activity: Activity) {
        var imageList = [(image: UIImage, quality: CGFloat, key: String)]()
        
        if activity.activityPhotos != nil {
            imageURLs = activity.activityPhotos!
        } else {
            imageURLs = [String]()
        }
        
        for image in images {
            imageList.append((image: image, quality: 0.5, key: "activityPhotos"))
            photoUpdatingGroup.enter()
        }
    
        for imageElement in imageList {
            uploadAvatarForActivityToFirebaseStorageUsingImage(imageElement.image, quality: imageElement.quality) { (url) in
                print("url \(url)")
                self.imageURLs.append(url)
                self.photoUpdatingGroup.leave()
            }
        }
        
        photoUpdatingGroup.notify(queue: DispatchQueue.main, execute: {
            if !self.imageURLs.isEmpty {
                let activityReference = Database.database().reference().child("activities").child(activity.activityID!).child("metaData")
                activityReference.updateChildValues(["activityPhotos": self.imageURLs])
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
        getImage(activity: activity)
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
