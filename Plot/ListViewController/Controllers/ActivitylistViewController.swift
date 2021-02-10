//
//  ActivitylistViewController.swift
//  Plot
//
//  Created by Cory McHattie on 7/15/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase
import CodableFirebase

protocol UpdateActivitylistDelegate: class {
    func updateActivitylist(activitylist: Activitylist)
}

class ActivitylistViewController: FormViewController {
    
    weak var delegate : UpdateActivitylistDelegate?
    
    var activitylist: Activitylist!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var activity: Activity!
    
    var userNames : [String] = []
    var userNamesString: String = ""
    
    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var connectedToAct = true
    var comingFromLists = false
    
    fileprivate var activityName: String = ""
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        configureTableView()
        
        if activitylist != nil {
            active = true
            var participantCount = self.selectedFalconUsers.count
            // If user is creating this activity (admin)
            if activitylist.admin == nil || activitylist.admin == Auth.auth().currentUser?.uid {
                participantCount += 1
            }
            
            if participantCount > 1 {
                self.userNamesString = "\(participantCount) participants"
            } else {
                self.userNamesString = "1 participant"
            }
            
            if let inviteesRow: ButtonRow = self.form.rowBy(tag: "Participants") {
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
            }
            resetBadgeForSelf()
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                activitylist = Activitylist(dictionary: ["ID": ID as AnyObject])
                activitylist.name = "ActivityListName"
                activitylist.createdDate = Date()
            }
        }
        setupRightBarButton()
        
        initializeForm()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards && !comingFromLists {
            delegate?.updateActivitylist(activitylist: activitylist)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard tableView.isEditing else { return }
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    fileprivate func configureTableView() {
        tableView.allowsMultipleSelectionDuringEditing = false
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
        tableView.separatorStyle = .none
        definesPresentationContext = true
        navigationItem.title = "Activity List"
    }
    
    func setupRightBarButton() {
        if !comingFromLists || !active || self.selectedFalconUsers.count == 0 {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            if #available(iOS 11.0, *) {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
                
                let dotsBarButton = UIButton(type: .system)
                dotsBarButton.setImage(dotsImage, for: .normal)
                dotsBarButton.addTarget(self, action: #selector(goToExtras), for: .touchUpInside)
                
                navigationItem.rightBarButtonItems = [plusBarButton, UIBarButtonItem(customView: dotsBarButton)]
            } else {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
                let dotsBarButton = UIBarButtonItem(image: dotsImage, style: .plain, target: self, action: #selector(goToExtras))
                navigationItem.rightBarButtonItems = [plusBarButton, dotsBarButton]
            }
        }
    }
    
    @objc fileprivate func close() {
        movingBackwards = false
        if !comingFromLists {
            if let activity = activity {
                activitylist.activityID = activity.activityID
            }
            self.showActivityIndicator()
            let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: selectedFalconUsers)
            createActivitylist.createNewActivitylist()
            self.hideActivityIndicator()
            delegate?.updateActivitylist(activitylist: activitylist)
            self.navigationController?.popViewController(animated: true)
            
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if active, !connectedToAct {
            alert.addAction(UIAlertAction(title: "Update Activity List", style: .default, handler: { (_) in
                print("User click Approve button")
                
                // update
                self.showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivitylist.createNewActivitylist()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity List", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activitylist with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivitylist.createNewActivitylist()
                    
                    //duplicate activitylist
                    let newActivitylistID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                    let newActivitylist = self.activitylist.copy() as! Activitylist
                    newActivitylist.ID = newActivitylistID
                    newActivitylist.admin = currentUserID
                    newActivitylist.participantsIDs = nil
                    newActivitylist.conversationID = nil
                    newActivitylist.activityID = nil
                    
                    let createNewActivitylist = ActivitylistActions(activitylist: newActivitylist, active: false, selectedFalconUsers: [])
                    createNewActivitylist.createNewActivitylist()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                }
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activitylist = self.activitylist
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate & Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    
                    //duplicate activity as if it never was deleted aka leave admin and participants intact
                    let newActivitylistID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                    let newActivitylist = self.activitylist.copy() as! Activitylist
                    newActivitylist.ID = newActivitylistID
                    
                    self.showActivityIndicator()
                    let createActivitylist = ActivitylistActions(activitylist: newActivitylist, active: false, selectedFalconUsers: [])
                    createActivitylist.createNewActivitylist()
                    self.hideActivityIndicator()
                    
                    // ChooseActivityTableViewController
                    let destination = ChooseActivityTableViewController()
                    let navController = UINavigationController(rootViewController: destination)
                    destination.delegate = self
                    destination.activitylist = self.activitylist
                    destination.activities = self.activities
                    destination.filteredActivities = self.activities
                    self.present(navController, animated: true, completion: nil)
                }
                
            }))
            
        } else if connectedToAct {
            alert.addAction(UIAlertAction(title: "Update Activity List", style: .default, handler: { (_) in
                print("User click Approve button")
                
                self.showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivitylist.createNewActivitylist()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
            }))
            
            alert.addAction(UIAlertAction(title: "Duplicate Activity List", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activitylist with updated time
                guard self.currentReachabilityStatus != .notReachable else {
                    basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
                    return
                }
                
                if let currentUserID = Auth.auth().currentUser?.uid {
                    self.showActivityIndicator()
                    let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                    createActivitylist.createNewActivitylist()
                    
                    //duplicate activitylist
                    let newActivitylistID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                    let newActivitylist = self.activitylist.copy() as! Activitylist
                    newActivitylist.ID = newActivitylistID
                    newActivitylist.admin = currentUserID
                    newActivitylist.participantsIDs = nil
                    newActivitylist.conversationID = nil
                    newActivitylist.activityID = nil
                    
                    let createNewActivitylist = ActivitylistActions(activitylist: newActivitylist, active: false, selectedFalconUsers: [])
                    createNewActivitylist.createNewActivitylist()
                    self.hideActivityIndicator()
                    
                    self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                }
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "Copy to Another Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivitylist.createNewActivitylist()
                
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activitylist = self.activitylist
                destination.activityID = self.activitylist.activityID
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
            
        } else if !connectedToAct {
            alert.addAction(UIAlertAction(title: "Create New Activity List", style: .default, handler: { (_) in
                print("User click Approve button")
                // create new activity
                
                self.showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
                createActivitylist.createNewActivitylist()
                self.hideActivityIndicator()
                
                self.navigationController?.backToViewController(viewController: MasterActivityContainerController.self)
                
            }))
            
            alert.addAction(UIAlertAction(title: "Add to Activity", style: .default, handler: { (_) in
                print("User click Edit button")
                
                // ChooseActivityTableViewController
                let destination = ChooseActivityTableViewController()
                let navController = UINavigationController(rootViewController: destination)
                destination.delegate = self
                destination.activitylist = self.activitylist
                destination.activities = self.activities
                destination.filteredActivities = self.activities
                self.present(navController, animated: true, completion: nil)
                
            }))
            
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if connectedToAct {
            if activitylist.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Activity List/Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()
                    
                    
                }))
            }
        } else if activitylist.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Activity List to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()
                
                
            }))
        }
        
        
        //        alert.addAction(UIAlertAction(title: "Share Activitylist", style: .default, handler: { (_) in
        //            print("User click Edit button")
        //            self.share()
        //        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
    
    @objc func goToChat() {
        if let conversationID = activitylist.conversationID {
            if let convo = conversations.first(where: {$0.chatID == conversationID}) {
                self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
                self.messagesFetcher = MessagesFetcher()
                self.messagesFetcher?.delegate = self
                self.messagesFetcher?.loadMessagesData(for: convo)
            }
        } else {
            let destination = ChooseChatTableViewController()
            let navController = UINavigationController(rootViewController: destination)
            destination.delegate = self
            destination.activitylist = activitylist
            destination.conversations = conversations
            destination.pinnedConversations = conversations
            destination.filteredConversations = conversations
            destination.filteredPinnedConversations = conversations
            present(navController, animated: true, completion: nil)
        }
    }
    
    func share() {
        //        if let activity = activity, let name = activity.name {
        //            let imageName = "activityLarge"
        //            if let image = UIImage(named: imageName) {
        //                let data = compressImage(image: image)
        //                let aO = ["activityName": "\(name)",
        //                            "activityID": activityID,
        //                            "activityImageURL": "\(imageName)",
        //                            "object": data] as [String: AnyObject]
        //                let activityObject = ActivityObject(dictionary: aO)
        //
        //                let alert = UIAlertController(title: "Share Activity", message: nil, preferredStyle: .actionSheet)
        //
        //                alert.addAction(UIAlertAction(title: "Inside of Plot", style: .default, handler: { (_) in
        //                    print("User click Approve button")
        //                    let destination = ChooseChatTableViewController()
        //                    let navController = UINavigationController(rootViewController: destination)
        //                    destination.activityObject = activityObject
        //                    destination.users = self.users
        //                    destination.filteredUsers = self.filteredUsers
        //                    destination.conversations = self.conversations
        //                    destination.filteredConversations = self.conversations
        //                    destination.filteredPinnedConversations = self.conversations
        //                    self.present(navController, animated: true, completion: nil)
        //
        //                }))
        //
        //                alert.addAction(UIAlertAction(title: "Outside of Plot", style: .default, handler: { (_) in
        //                    print("User click Edit button")
        //                        // Fallback on earlier versions
        //                    let shareText = "Hey! Download Plot on the App Store so I can share an activity with you."
        //                    guard let url = URL(string: "https://apps.apple.com/us/app/plot-scheduling-app/id1473764067?ls=1")
        //                        else { return }
        //                    let shareContent: [Any] = [shareText, url]
        //                    let activityController = UIActivityViewController(activityItems: shareContent,
        //                                                                      applicationActivities: nil)
        //                    self.present(activityController, animated: true, completion: nil)
        //                    activityController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
        //                    Bool, arrayReturnedItems: [Any]?, error: Error?) in
        //                        if completed {
        //                            print("share completed")
        //                            return
        //                        } else {
        //                            print("cancel")
        //                        }
        //                        if let shareError = error {
        //                            print("error while sharing: \(shareError.localizedDescription)")
        //                        }
        //                    }
        //
        //                }))
        //
        //
        //                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        //                    print("User click Dismiss button")
        //                }))
        //
        //                self.present(alert, animated: true, completion: {
        //                    print("completion block")
        //                })
        //                print("shareButtonTapped")
        //            }
        //
        //
        //        }
        
    }
    
    func initializeForm() {
        form +++
            Section()
            
            <<< TextRow("Name") {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                $0.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
                $0.placeholder = $0.tag
                if active, let activitylist = activitylist {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    $0.value = activitylist.name
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                    $0.cell.textField.becomeFirstResponder()
                }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.activitylist.name = rowValue
                }
                if row.value == nil {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                } else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textField?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.placeholderColor = ThemeManager.currentTheme().generalSubtitleColor
        }
        
        if !connectedToAct {
            form.last!
                <<< ButtonRow("Participants") { row in
                    row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    row.cell.textLabel?.textAlignment = .left
                    row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    row.cell.accessoryType = .disclosureIndicator
                    row.title = row.tag
                    if active {
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.title = self.userNamesString
                    }
                }.onCellSelection({ _,_ in
                    self.openParticipantsInviter()
                }).cellUpdate { cell, row in
                    cell.accessoryType = .disclosureIndicator
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                    cell.textLabel?.textAlignment = .left
                    if row.title == "Participants" {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                    } else {
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                    }
            }
        }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "Activity List",
                               footer: "Add an activity to list") {
                                $0.tag = "activitylistfields"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        $0.title = "Add New Activity"
                                    }.cellUpdate { cell, row in
                                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                                        cell.textLabel?.textAlignment = .left
                                        
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    self.activityName = ""
                                    self.openActivity()
                                    return LabelRow("label"){ row in
                                        
                                    }
                                    
                                }
                                
        }
        
        if let items = self.activitylist.items {
            for (key, value) in items {
                var mvs = (form.sectionBy(tag: "activitylistfields") as! MultivaluedSection)
                mvs.insert(SplitRow<ButtonRow, CheckRow>() { splitRow in
                    splitRow.rowLeftPercentage = 0.75
                    splitRow.rowLeft = ButtonRow(){ row in
                        row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        row.cell.textLabel?.textAlignment = .left
                        row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        row.cell.textLabel?.numberOfLines = 0
                        row.title = key
                        }.onCellSelection({ _, _ in
                            self.activityName = key
                            self.openActivity()
                    }).cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.numberOfLines = 0
                    }
                    splitRow.rowRight = CheckRow() {
                        $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        $0.cell.tintColor = FalconPalette.defaultBlue
                        $0.value = value
                        $0.cell.accessoryType = .checkmark
                        $0.cell.tintAdjustmentMode = .dimmed
                    }.cellUpdate { cell, row in
                        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                        cell.tintColor = FalconPalette.defaultBlue
                        if row.value == false {
                            cell.accessoryType = .checkmark
                            cell.tintAdjustmentMode = .dimmed
                        } else {
                            cell.tintAdjustmentMode = .automatic
                        }
                    }.onCellSelection({ (cell, row) in
                        self.activitylist.items![key] = row.value
                    })
                }.cellUpdate { cell, row in
                    cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                } , at: mvs.count - 1)
            }
        }
    }
    
    fileprivate func openActivity() {
        if activityName != "", let IDTypeDictionary = activitylist.IDTypeDictionary {
            let name = activityName
            if let IDType = IDTypeDictionary[name] {
                for (ID, type) in IDType {
                    self.showActivityIndicator()
                    let dispatchGroup = DispatchGroup()
                    if type == "recipe" {
                        dispatchGroup.enter()
                        Service.shared.fetchRecipesInfo(id: Int(ID)!) { (search, err) in
                            if let detailedRecipe = search {
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    let destination = RecipeDetailViewController()
                                    destination.recipe = detailedRecipe
                                    destination.detailedRecipe = detailedRecipe
                                    destination.activeList = true
                                    destination.active = true
                                    destination.listType = "activity"
                                    destination.listDelegate = self
                                    destination.activityType = type
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            } else {
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    self.hideActivityIndicator()
                                    self.activityNotFoundAlert()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                }
                            }
                        }
                    } else if type == "workout" {
                        var reference = Database.database().reference()
                        dispatchGroup.enter()
                        reference = Database.database().reference().child("workouts").child("workouts")
                        reference.child(ID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let workoutSnapshotValue = snapshot.value {
                                if let workout = try? FirebaseDecoder().decode(PreBuiltWorkout.self, from: workoutSnapshotValue) {
                                    dispatchGroup.leave()
                                    let destination = WorkoutDetailViewController()
                                    destination.workout = workout
                                    destination.activeList = true
                                    destination.active = true
                                    destination.listType = "activity"
                                    destination.listDelegate = self
                                    destination.activityType = type
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            }
                        })
                        { (error) in
                            print("workout bad")
                            dispatchGroup.leave()
                            self.hideActivityIndicator()
                            print(error.localizedDescription)
                        }
                    } else if type == "event" {
                        dispatchGroup.enter()
                        Service.shared.fetchEventsSegment(size: "50", id: ID, keyword: "", attractionId: "", venueId: "", postalCode: "", radius: "", unit: "", startDateTime: "", endDateTime: "", city: "", stateCode: "", countryCode: "", classificationName: "", classificationId: "") { (search, err) in
                            if let events = search?.embedded?.events {
                                let event = events[0]
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    let destination = EventDetailViewController()
                                    destination.event = event
                                    destination.activeList = true
                                    destination.active = true
                                    destination.listType = "activity"
                                    destination.listDelegate = self
                                    destination.activityType = type
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            } else {
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    self.hideActivityIndicator()
                                    self.activityNotFoundAlert()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                }
                            }
                        }
                    } else {
                        dispatchGroup.enter()
                        Service.shared.fetchFSDetails(id: ID) { (search, err) in
                            if let place = search?.response?.venue {
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    let destination = PlaceDetailViewController()
                                    destination.hidesBottomBarWhenPushed = true
                                    destination.place = place
                                    destination.activeList = true
                                    destination.active = true
                                    destination.listType = "activity"
                                    destination.listDelegate = self
                                    destination.activityType = type
                                    self.hideActivityIndicator()
                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            } else {
                                dispatchGroup.leave()
                                dispatchGroup.notify(queue: .main) {
                                    self.hideActivityIndicator()
                                    self.activityNotFoundAlert()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let destination = ActivityTypeViewController()
            destination.listDelegate = self
            destination.activeList = true
            self.hideActivityIndicator()
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    override func rowsHaveBeenRemoved(_ rows: [BaseRow], at indexes: [IndexPath]) {
        super.rowsHaveBeenRemoved(rows, at: indexes)
        
        DispatchQueue.main.async { [weak self] in
            if let row = rows[0] as? SplitRow<ButtonRow, CheckRow>, row.rowLeft?.title != nil, let title = row.rowLeft?.title, self!.activitylist.items != nil, let IDTypeDictionary = self!.activitylist.IDTypeDictionary {
                self!.activitylist.items![title] = nil
                if IDTypeDictionary[title] != nil {
                    self!.activitylist.IDTypeDictionary![title] = nil
                }
            }
        }
    }
    
    @objc fileprivate func openParticipantsInviter() {
        guard currentReachabilityStatus != .notReachable else {
            basicErrorAlertWith(title: basicErrorTitleForAlert, message: noInternetError, controller: self)
            return
        }
        let destination = SelectActivityMembersViewController()
        var uniqueUsers = users
        for participant in selectedFalconUsers {
            if let userIndex = users.firstIndex(where: { (user) -> Bool in
                return user.id == participant.id }) {
                uniqueUsers[userIndex] = participant
            } else {
                uniqueUsers.append(participant)
            }
        }
        destination.users = uniqueUsers
        destination.filteredUsers = uniqueUsers
        if !selectedFalconUsers.isEmpty {
            destination.priorSelectedUsers = selectedFalconUsers
        }
        destination.delegate = self
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    func getSelectedFalconUsers(forActivitylist activitylist: Activitylist, completion: @escaping ([User])->()) {
        guard let participantsIDs = activitylist.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        var selectedFalconUsers = [User]()
        let group = DispatchGroup()
        for id in participantsIDs {
            // Only if the current user is created this activity
            if activitylist.admin == currentUserID && id == currentUserID {
                continue
            }
            
            group.enter()
            let participantReference = Database.database().reference().child("users").child(id)
            participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                    dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                    let user = User(dictionary: dictionary)
                    selectedFalconUsers.append(user)
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(selectedFalconUsers)
        }
    }
    
    fileprivate func resetBadgeForSelf() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let badgeRef = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).child(activitylist.ID!).child("badge")
        badgeRef.runTransactionBlock({ (mutableData) -> TransactionResult in
            var value = mutableData.value as? Int
            value = 0
            mutableData.value = value!
            return TransactionResult.success(withValue: mutableData)
        })
    }
}

extension ActivitylistViewController: UpdateListDelegate {
    func updateRecipe(recipe: Recipe?) {
        
    }
    func updateList(recipe: Recipe?, workout: PreBuiltWorkout?, event: Event?, place: FSVenue?, activityType: String?) {
        if let _: LabelRow = form.rowBy(tag: "label"), let mvs = self.form.sectionBy(tag: "activitylistfields") as? MultivaluedSection {
            mvs.remove(at: mvs.count - 2)
        }
        
        var key = ""
        if let object = recipe, let activityType = activityType {
            key = object.title
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.title)"] = false
                activitylist.IDTypeDictionary!["\(object.title)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.title)": false]
                activitylist.IDTypeDictionary = ["\(object.title)": ["\(object.id)":"\(activityType)"]]
            }
        } else if let object = workout, let activityType = activityType {
            key = object.title
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.title)"] = false
                activitylist.IDTypeDictionary!["\(object.title)"] = ["\(object.identifier)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.title)": false]
                activitylist.IDTypeDictionary = ["\(object.title)": ["\(object.identifier)":"\(activityType)"]]
            }
        } else if let object = event, let activityType = activityType {
            key = object.name
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.name)"] = false
                activitylist.IDTypeDictionary!["\(object.name)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.name)": false]
                activitylist.IDTypeDictionary = ["\(object.name)": ["\(object.id)":"\(activityType)"]]
            }
        } else if let object = place, let activityType = activityType {
            key = object.name
            if activitylist.items != nil && activitylist.IDTypeDictionary != nil {
                activitylist.items!["\(object.name)"] = false
                activitylist.IDTypeDictionary!["\(object.name)"] = ["\(object.id)":"\(activityType)"]
            } else {
                activitylist.items = ["\(object.name)": false]
                activitylist.IDTypeDictionary = ["\(object.name)": ["\(object.id)":"\(activityType)"]]
            }
        } else {
            print("object not found")
            return
        }
        
        var mvs = (form.sectionBy(tag: "activitylistfields") as! MultivaluedSection)
        mvs.insert(SplitRow<ButtonRow, CheckRow>() { splitRow in
            splitRow.rowLeftPercentage = 0.75
            splitRow.rowLeft = ButtonRow(){ row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textAlignment = .left
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.textLabel?.numberOfLines = 0
                row.title = key
                }.onCellSelection({ cell, row in
                    self.activityName = key
                    self.openActivity()
            }).cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.numberOfLines = 0
            }
            splitRow.rowRight = CheckRow() {
                $0.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                $0.cell.tintColor = FalconPalette.defaultBlue
                $0.value = false
                $0.cell.accessoryType = .checkmark
                $0.cell.tintAdjustmentMode = .dimmed
            }.cellUpdate { cell, row in
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.tintColor = FalconPalette.defaultBlue
                if row.value == false {
                    cell.accessoryType = .checkmark
                    cell.tintAdjustmentMode = .dimmed
                } else {
                    cell.tintAdjustmentMode = .automatic
                }
            }.onCellSelection({ (cell, row) in
                self.activitylist.items![key] = row.value
            })
        }.cellUpdate { cell, row in
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        } , at: mvs.count - 1)
        
        let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: self.selectedFalconUsers)
        createActivitylist.createNewActivitylist()
    }
}

extension ActivitylistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: ButtonRow = form.rowBy(tag: "Participants") {
            if !selectedFalconUsers.isEmpty {
                self.selectedFalconUsers = selectedFalconUsers
                
                var participantCount = self.selectedFalconUsers.count
                // If user is creating this activity (admin)
                if activitylist.admin == nil || activitylist.admin == Auth.auth().currentUser?.uid {
                    participantCount += 1
                }
                
                if participantCount > 1 {
                    self.userNamesString = "\(participantCount) participants"
                } else {
                    self.userNamesString = "1 participant"
                }
                
                inviteesRow.title = self.userNamesString
                inviteesRow.updateCell()
                
            } else {
                self.selectedFalconUsers = selectedFalconUsers
                inviteesRow.title = "1 participant"
                inviteesRow.updateCell()
            }
            
            if active {
                showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: activitylist, active: active, selectedFalconUsers: selectedFalconUsers)
                createActivitylist.updateActivitylistParticipants()
                hideActivityIndicator()
                
            }
            
        }
    }
}

extension ActivitylistViewController: ChooseActivityDelegate {
    func chosenActivity(mergeActivity: Activity) {
        if connectedToAct {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let newActivitylistID = Database.database().reference().child(userActivitylistsEntity).child(currentUserID).childByAutoId().key ?? ""
                
                let groupActivityReference = Database.database().reference().child("activities").child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
                if mergeActivity.activitylistIDs != nil {
                    var activitylistIDs = mergeActivity.activitylistIDs!
                    activitylistIDs.append(newActivitylistID)
                    groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
                } else {
                    groupActivityReference.updateChildValues(["activitylistIDs": [newActivitylistID] as AnyObject])
                }
                
                let newActivitylist = self.activitylist.copy() as! Activitylist
                newActivitylist.ID = newActivitylistID
                newActivitylist.admin = mergeActivity.admin
                newActivitylist.participantsIDs = mergeActivity.participantsIDs
                newActivitylist.conversationID = mergeActivity.conversationID
                newActivitylist.activityID = mergeActivity.activityID
                
                self.getSelectedFalconUsers(forActivitylist: activitylist) { (participants) in
                    self.showActivityIndicator()
                    let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: participants)
                    createActivitylist.createNewActivitylist()
                    self.hideActivityIndicator()
                    self.addedToActAlert()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            let groupActivityReference = Database.database().reference().child("activities").child(mergeActivity.activityID!).child(messageMetaDataFirebaseFolder)
            if mergeActivity.activitylistIDs != nil {
                var activitylistIDs = mergeActivity.activitylistIDs!
                activitylistIDs.append(activitylist.ID!)
                groupActivityReference.updateChildValues(["activitylistIDs": activitylistIDs as AnyObject])
            } else {
                groupActivityReference.updateChildValues(["activitylistIDs": [activitylist.ID!] as AnyObject])
            }
            //remove participants and admin when adding
            activitylist.participantsIDs = mergeActivity.participantsIDs
            activitylist.admin = mergeActivity.admin
            activitylist.activityID = mergeActivity.activityID
            activitylist.conversationID = mergeActivity.conversationID
            
            self.getSelectedFalconUsers(forActivitylist: activitylist) { (participants) in
                self.showActivityIndicator()
                let createActivitylist = ActivitylistActions(activitylist: self.activitylist, active: self.active, selectedFalconUsers: participants)
                createActivitylist.createNewActivitylist()
                self.hideActivityIndicator()
                self.addedToActAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ActivitylistViewController: ChooseChatDelegate {
    func chosenChat(chatID: String, activityID: String?, grocerylistID: String?, checklistID: String?, packinglistID: String?, activitylistID: String?) {
        if let activitylistID = activitylistID {
            let updatedConversationID = ["conversationID": chatID as AnyObject]
            Database.database().reference().child(activitylistsEntity).child(activitylistID).updateChildValues(updatedConversationID)
            if let conversation = conversations.first(where: {$0.chatID == chatID}) {
                if conversation.activitylists != nil {
                    var activitylists = conversation.activitylists!
                    activitylists.append(activitylistID)
                    let updatedActivitylists = [activitylistsEntity: activitylists as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                } else {
                    let updatedActivitylists = [activitylistsEntity: [activitylistID] as AnyObject]
                    Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivitylists)
                }
                if let activityID = activityID {
                    Database.database().reference().child("activities").child(activityID).child(messageMetaDataFirebaseFolder).updateChildValues(updatedConversationID)
                    if conversation.activities != nil {
                        var activities = conversation.activities!
                        activities.append(activityID)
                        let updatedActivities = ["activities": activities as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    } else {
                        let updatedActivities = ["activities": [activityID] as AnyObject]
                        Database.database().reference().child("groupChats").child(conversation.chatID!).child(messageMetaDataFirebaseFolder).updateChildValues(updatedActivities)
                    }
                    Database.database().reference().child("activities").child(activityID).updateChildValues(updatedConversationID)
                }
                self.connectedToChatAlert()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension ActivitylistViewController: MessagesDelegate {
    
    func messages(shouldChangeMessageStatusToReadAt reference: DatabaseReference) {
        chatLogController?.updateMessageStatus(messageRef: reference)
    }
    
    func messages(shouldBeUpdatedTo messages: [Message], conversation: Conversation) {
        
        chatLogController?.hidesBottomBarWhenPushed = true
        chatLogController?.messagesFetcher = messagesFetcher
        chatLogController?.messages = messages
        chatLogController?.conversation = conversation
        
        if let membersIDs = conversation.chatParticipantsIDs, let uid = Auth.auth().currentUser?.uid, membersIDs.contains(uid) {
            chatLogController?.observeTypingIndicator()
            chatLogController?.configureTitleViewWithOnlineStatus()
        }
        
        chatLogController?.messagesFetcher.collectionDelegate = chatLogController
        guard let destination = chatLogController else { return }
        
        self.chatLogController?.startCollectionViewAtBottom()
        
        
        // If we're presenting a modal sheet
        if let presentedViewController = presentedViewController as? UINavigationController {
            presentedViewController.pushViewController(destination, animated: true)
        } else {
            navigationController?.pushViewController(destination, animated: true)
        }
        
        chatLogController = nil
        messagesFetcher?.delegate = nil
        messagesFetcher = nil
    }
}
