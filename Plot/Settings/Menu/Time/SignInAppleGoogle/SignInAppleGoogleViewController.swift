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
    
    var networkController = NetworkController()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = 50
        tableView.register(SignInAppleGoogleTableViewCell.self, forCellReuseIdentifier: signInAppleGoogleCellId)
        extendedLayoutIncludesOpaqueBars = true
        createDataSource()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.UpdateWithGoogleAppleSignIn()
    }
    
    fileprivate func createDataSource() {
        if title == "Tasks" {
            if !lists.keys.contains(ListOptions.apple.name) && !lists.keys.contains(ListOptions.google.name) {
                firstSection.append(apple)
                secondSection.append(google)
            } else if !lists.keys.contains(ListOptions.apple.name) {
                firstSection.append(apple)
            } else if !lists.keys.contains(ListOptions.google.name) {
                firstSection.append(google)
            }
        } else if title == "Calendars" {
            if !calendars.keys.contains(CalendarOptions.apple.name) && !calendars.keys.contains(CalendarOptions.google.name) {
                firstSection.append(apple)
                secondSection.append(google)
            } else if !calendars.keys.contains(CalendarOptions.apple.name) {
                firstSection.append(apple)
            } else if !calendars.keys.contains(CalendarOptions.google.name) {
                firstSection.append(google)
            }
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
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            cell.icon.image = firstSection[indexPath.row].icon
            cell.title.text = firstSection[indexPath.row].title
            cell.accessoryType = .none
            if firstSection[indexPath.row].title == "Sign in with Google" {
                cell.backgroundColor = ThemeManager.currentTheme().googleSignInBackgroundColor
                cell.title.font = UIFont(name: "Roboto-Medium", size: 17)
            } else {
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.title.font = .boldSystemFont(ofSize: 17)
            }
            return cell
        } else {
            cell.icon.image = secondSection[indexPath.row].icon
            cell.title.text = secondSection[indexPath.row].title
            cell.accessoryType = .none
            if secondSection[indexPath.row].title == "Sign in with Google" {
                cell.backgroundColor = ThemeManager.currentTheme().googleSignInBackgroundColor
                cell.title.font = UIFont(name: "Roboto-Medium", size: 17)
            } else {
                cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
                cell.title.font = .boldSystemFont(ofSize: 17)
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
                if title == "Tasks" {
                    self.networkController.activityService.updatePrimaryList(value: ListOptions.apple.name)
                } else {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.apple.name)
                }
            }
        } else {
            if secondSection[indexPath.row].title == "Sign in with Google" {
                GIDSignIn.sharedInstance().delegate = self
                GIDSignIn.sharedInstance()?.presentingViewController = self
                GIDSignIn.sharedInstance()?.signIn()
            } else {
                if title == "Tasks" {
                    self.networkController.activityService.updatePrimaryList(value: ListOptions.apple.name)
                } else {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.apple.name)
                }
            }
        }
    }
}

extension SignInAppleGoogleViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("signed in")
        if (error == nil) && title == "Tasks" {
            print("updatePrimaryCalendar")
            self.networkController.activityService.updatePrimaryList(value: ListOptions.google.name)
        }
        else if (error == nil) && title == "Calendars" {
            self.networkController.activityService.updatePrimaryCalendar(value: CalendarOptions.google.name)
        }
        else {
          print("\(error.localizedDescription)")
        }
    }
}
