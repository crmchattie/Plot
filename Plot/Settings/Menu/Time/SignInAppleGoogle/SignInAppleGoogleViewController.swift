//
//  SignInAppleGoogleViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/26/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import CodableFirebase
import GoogleSignIn

protocol UpdateWithGoogleAppleSignInDelegate: AnyObject {
    func UpdateWithGoogleAppleSignIn()
}

class SignInAppleGoogleViewController: UITableViewController {
    weak var delegate : UpdateWithGoogleAppleSignInDelegate?
    
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let signInAppleGoogleCellId = "signInAppleGoogleCellId"
    
    var lists: [String: [ListType]] {
        return networkController.activityService.lists
    }
    
    var calendars: [String: [CalendarType]] {
        return networkController.activityService.calendars
    }
    
    var firstSection = [TableViewObject]()

    var secondSection = [TableViewObject]()
    
    let apple = TableViewObject(icon: UIImage(named: "apple"), title: "Sign in with Apple")
    let google = TableViewObject(icon: UIImage(named: "google"), title: "Sign in with Google")
    
    let customFont = UIFont(name: "Roboto-Medium", size: 17)!
    
    var googleSignInColor: UIColor {
        return UIColor { (trait) -> UIColor in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor("#4285F4")
            default:
                return UIColor("#FFFFFF")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = 50
        tableView.register(SignInAppleGoogleTableViewCell.self, forCellReuseIdentifier: signInAppleGoogleCellId)
        extendedLayoutIncludesOpaqueBars = true
        createDataSource()
        
        if navigationItem.leftBarButtonItem != nil {
            navigationItem.leftBarButtonItem?.action = #selector(cancel)
        }
        if navigationItem.rightBarButtonItem != nil {
            navigationItem.rightBarButtonItem?.action = #selector(done)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.UpdateWithGoogleAppleSignIn()
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func createDataSource() {
        if title == "Lists" {
            if !lists.keys.contains(ListSourceOptions.apple.name) && !lists.keys.contains(ListSourceOptions.google.name) {
                firstSection.append(apple)
                secondSection.append(google)
            } else if !lists.keys.contains(ListSourceOptions.apple.name) {
                firstSection.append(apple)
            } else if !lists.keys.contains(ListSourceOptions.google.name) {
                firstSection.append(google)
            }
        } else if title == "Calendars" {
            if !calendars.keys.contains(CalendarSourceOptions.apple.name) && !calendars.keys.contains(CalendarSourceOptions.google.name) {
                firstSection.append(apple)
                secondSection.append(google)
            } else if !calendars.keys.contains(CalendarSourceOptions.apple.name) {
                firstSection.append(apple)
            } else if !calendars.keys.contains(CalendarSourceOptions.google.name) {
                firstSection.append(google)
            }
        } else if title == "Providers" {
            firstSection.append(apple)
            secondSection.append(google)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return firstSection.count + secondSection.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return firstSection.count
        } else {
            return secondSection.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: signInAppleGoogleCellId,
                                                 for: indexPath) as? SignInAppleGoogleTableViewCell ?? SignInAppleGoogleTableViewCell()
        cell.selectionStyle = .default
        if indexPath.section == 0 {
            cell.icon.image = firstSection[indexPath.row].icon
            cell.title.text = firstSection[indexPath.row].title
            cell.accessoryType = .none
            if firstSection[indexPath.row].title == "Sign in with Google" {
                cell.backgroundColor = googleSignInColor
                cell.title.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
            } else {
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.title.font = UIFont.body.with(weight: .bold)
            }
            return cell
        } else {
            cell.icon.image = secondSection[indexPath.row].icon
            cell.title.text = secondSection[indexPath.row].title
            cell.accessoryType = .none
            if secondSection[indexPath.row].title == "Sign in with Google" {
                cell.backgroundColor = googleSignInColor
                cell.title.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
            } else {
                cell.backgroundColor = .secondarySystemGroupedBackground
                cell.title.font = UIFont.body.with(weight: .bold)
            }
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if firstSection[indexPath.row].title == "Sign in with Google" {
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
                GIDSignIn.sharedInstance()?.signIn()
            } else {
                if title == "Lists" {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.apple.name)
                } else if title == "Calendars" {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.apple.name)
                } else if title == "Providers" {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.apple.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.apple.name)
                }
                if navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            if secondSection[indexPath.row].title == "Sign in with Google" {
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
                GIDSignIn.sharedInstance()?.signIn()
            } else {
                if title == "Lists" {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.apple.name)
                } else if title == "Calendars" {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.apple.name)
                } else if title == "Providers" {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.apple.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.apple.name)
                }
                if navigationItem.leftBarButtonItem != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SignInAppleGoogleViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let grantedScopes = user?.grantedScopes as? [String]
            print(grantedScopes)
            if let grantedScopes = grantedScopes {
                if grantedScopes.contains(googleEmailScope) && grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                } else if grantedScopes.contains(googleEmailScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                } else if grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                }
            }
            if navigationItem.leftBarButtonItem != nil {
                self.dismiss(animated: true, completion: nil)
            }
        }
        else {
          print("\(error.localizedDescription)")
        }
    }
}
