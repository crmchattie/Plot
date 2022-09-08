//
//  PackingListViewController.swift
//  Plot
//
//  Created by Cory McHattie on 5/2/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Eureka
import SplitRow
import Firebase

protocol UpdatePackinglistDelegate: AnyObject {
    func updatePackinglist(packinglist: Packinglist)
}

class PackinglistViewController: FormViewController {
    weak var delegate : UpdatePackinglistDelegate?
          
    var packinglist: Packinglist!
    
    var users = [User]()
    var filteredUsers = [User]()
    var selectedFalconUsers = [User]()
    
    var activities = [Activity]()
    var conversations = [Conversation]()
    
    var activity: Activity!

    fileprivate var active: Bool = false
    fileprivate var movingBackwards: Bool = true
    var connectedToAct = true
    var comingFromLists = false
    
    var weather: [DailyWeatherElement]!
    var startDateTime: Date?
    var endDateTime: Date?
    
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
      
        configureTableView()
        
        if packinglist != nil {
            active = true
            
        } else {
            if let currentUserID = Auth.auth().currentUser?.uid {
                let ID = Database.database().reference().child(userPackinglistsEntity).child(currentUserID).childByAutoId().key ?? ""
                packinglist = Packinglist(dictionary: ["ID": ID as AnyObject])
                packinglist.name = "PackingListName"
                packinglist.createdDate = Date()
            }
        }
        setupRightBarButton()

        initializeForm()
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.movingBackwards && !comingFromLists {
            delegate?.updatePackinglist(packinglist: packinglist)
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
        navigationItem.title = "Packing List"
    }
    
    func setupRightBarButton() {
        if !comingFromLists || !active {
            let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(close))
            navigationItem.rightBarButtonItem = plusBarButton
        } else {
            let dotsImage = UIImage(named: "dots")
            if #available(iOS 11.0, *) {
                let plusBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
                
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
        delegate?.updatePackinglist(packinglist: packinglist)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func goToExtras() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if connectedToAct {
            if packinglist.conversationID == nil {
                alert.addAction(UIAlertAction(title: "Connect Packing List/Activity to a Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                }))
            } else {
                alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                    print("User click Approve button")
                    self.goToChat()

                    
                }))
            }
        } else if packinglist.conversationID == nil {
            alert.addAction(UIAlertAction(title: "Connect Packing List to a Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

            }))
        } else {
            alert.addAction(UIAlertAction(title: "Go to Chat", style: .default, handler: { (_) in
                print("User click Approve button")
                self.goToChat()

                
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Share Packing List", style: .default, handler: { (_) in
            print("User click Edit button")
            self.share()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            print("User click Dismiss button")
        }))

        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        print("shareButtonTapped")
        
    }
        
        @objc func goToChat() {
//            if let conversationID = packinglist.conversationID {
//                if let convo = conversations.first(where: {$0.chatID == conversationID}) {
//                    self.chatLogController = ChatLogController(collectionViewLayout: AutoSizingCollectionViewFlowLayout())
//                    self.messagesFetcher = MessagesFetcher()
//                    self.messagesFetcher?.delegate = self
//                    self.messagesFetcher?.loadMessagesData(for: convo)
//                }
//            } else {
//                let destination = ChooseChatTableViewController()
//                let navController = UINavigationController(rootViewController: destination)
//                destination.delegate = self
//                if let activity = packinglist.activity {
//                    destination.activity = activity
//                }
//                destination.packinglist = packinglist
//                destination.conversations = conversations
//                destination.pinnedConversations = conversations
//                destination.filteredConversations = conversations
//                destination.filteredPinnedConversations = conversations
//                present(navController, animated: true, completion: nil)
//            }
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
            if active, let packinglist = packinglist {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                $0.value = packinglist.name
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                $0.cell.textField.becomeFirstResponder()
            }
            }.onChange() { [unowned self] row in
                if let rowValue = row.value {
                    self.packinglist.name = rowValue
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
            <<< LabelRow("Participants") { row in
                row.cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                row.cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                row.cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                row.cell.accessoryType = .disclosureIndicator
                row.cell.textLabel?.textAlignment = .left
                row.cell.selectionStyle = .default
                row.title = row.tag
                if packinglist.admin == nil || packinglist.admin == Auth.auth().currentUser?.uid {
                    row.value = String(self.selectedFalconUsers.count + 1)
                } else {
                    row.value = String(self.selectedFalconUsers.count)
                }
            }.onCellSelection({ _, row in
                self.openParticipantsInviter()
            }).cellUpdate { cell, row in
                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
                cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
                cell.textLabel?.textAlignment = .left
            }
        }
    }
    
    fileprivate func weatherRow() {
        if let weather = self.weather {
            print("updating weather row")
            var section = self.form.allSections[0]
            if let locationRow: ButtonRow = self.form.rowBy(tag: "Packing List Name"), let index = locationRow.indexPath?.item {
                section.insert(WeatherRow("Weather") { row in
                        row.value = weather
                        row.reload()
                    }, at: index+1)
            }
        } else if let weatherRow: WeatherRow = self.form.rowBy(tag: "Weather"), let index = weatherRow.indexPath?.item {
            let section = self.form.allSections[0]
            section.remove(at: index)
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
        destination.ownerID = packinglist.admin
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
}

extension PackinglistViewController: UpdateInvitees {
    func updateInvitees(selectedFalconUsers: [User]) {
        if let inviteesRow: LabelRow = form.rowBy(tag: "Participants") {
            self.selectedFalconUsers = selectedFalconUsers
            if packinglist.admin == nil || packinglist.admin == Auth.auth().currentUser?.uid {
                inviteesRow.value = String(self.selectedFalconUsers.count + 1)
            } else {
                inviteesRow.value = String(self.selectedFalconUsers.count)
            }
            inviteesRow.updateCell()
            
//            if active {
//                showActivityIndicator()
//                let createActivity = ActivityActions(activity: activity, active: active, selectedFalconUsers: selectedFalconUsers)
//                createActivity.updateActivityParticipants()
//                hideActivityIndicator()
//
//            }
            
        }
    }
}
