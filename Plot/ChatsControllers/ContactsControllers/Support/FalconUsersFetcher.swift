//
//  FalconUsersFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/10/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Firebase
import PhoneNumberKit
import SDWebImage

protocol FalconUsersUpdatesDelegate: class {
    func falconUsers(shouldBeUpdatedTo users: [User])
}

public var shouldReFetchFalconUsers: Bool = false

class FalconUsersFetcher: NSObject {
    
    //PhoneNumberKit is a library that allows for parsing of phone numbers
    let phoneNumberKit = PhoneNumberKit()
    var users = [User]()
    var userID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    //set class as delegate for protocol
    weak var delegate: FalconUsersUpdatesDelegate?
    
    //represents a particular location in your Firebase Database and can be used for reading or writing data to that Firebase Database location.
    var reference: DatabaseReference!
    
    //database query
    var userQuery: DatabaseQuery!
    var relationshipQuery: DatabaseQuery!
    
    
    //listens for a database event
    var userHandle = [DatabaseHandle]()
    
    //allows different work items to run at the same time and update at different times
    var group = DispatchGroup()
    
    
    fileprivate func clearObserversAndUsersIfNeeded() {
        //removes all falcon users from collection - do not understand = research; possibly will stop redundant falcon users due to ViewWillAppear() ContactsController
        self.users.removeAll()
        if reference != nil {
            for handle in userHandle {
                reference.removeObserver(withHandle: handle)
            }
        }
    }
    
    func fetchFalconUsers(asynchronously: Bool) {
        
        //check is user exists
        if userID == nil {
            return
        }
        
        clearObserversAndUsersIfNeeded()

        reference = Database.database().reference()
        
        //add Plot user
        reference.child("relationships").child(self.userID!).child("acdmpzhmDWaBdcEo17DRMt8gwCh1").setValue("true")

        //create check if user exists in relationship table and return relationships
        reference.child("relationships").child(userID!).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                //grab all relationships
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else { return }
                //iterate over the children to grab users' info
                for child in children {
                    self.reference.child("users").child(child.key).observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.exists() {
                            guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                                                        
                            dictionary.updateValue(child.key as AnyObject, forKey: "id")
                            if let thumbnailURLString = User(dictionary: dictionary).thumbnailPhotoURL, let thumbnailURL = URL(string: thumbnailURLString) {
                                SDWebImagePrefetcher.shared.prefetchURLs([thumbnailURL])
                            }
                            
                            //add user to self.users unless user already was added, then update user's dictionary - will continuously add current user since current user is removed below
                            if let index = self.users.firstIndex(where: { (user) -> Bool in
                                return user.id == User(dictionary: dictionary).id
                            }) {
                                let user = User(dictionary: dictionary)
                                self.users[index] = user
                            } else {
                                let user = User(dictionary: dictionary)
                                if let _ = user.name {
                                    self.users.append(user)
                                } else {
                                    self.reference.child("relationships").child(self.userID!).child(user.id!).removeValue()
                                }
                            }
                            
                            self.users = self.sortUsers(users: self.users)
//                            self.users = self.rearrangeUsers(users: self.users)
                            
                            //remove current user from users array
                            if let index = self.users.firstIndex(where: { (user) -> Bool in
                                return user.id == self.userID!
                            }) {
                                self.users.remove(at: index)
                            }
                            
                            if asynchronously {
                                self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
                                //                                print("Updated delegate")
                            }
                            
                            if !asynchronously {
                                self.group.leave()
                                print("leaving group")
                            }
                        } else {
                            print("Nothing found")
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            } else {
                print("nothing found")
            }
        }, withCancel: { (error) in
            print(error.localizedDescription)
        })
        
        if asynchronously {
            print("fetching async")
            fetchAsynchronously()
        } else {
            print("fetching sync")
            fetchSynchronously()
        }
    }
    
    fileprivate func fetchSynchronously() {
        
        var preparedNumbers = [String]()
        for number in localPhones {
            do {
                //possibly useless; just adds a plus sign and takes up memory
                let countryCode = try phoneNumberKit.parse(number).countryCode
                let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
                preparedNumbers.append("+" + String(countryCode) + String(nationalNumber))
                group.enter()
                print("entering group")
            } catch {}
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            print("Contacts load finished Plot")
            self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
        })
        
        for preparedNumber in preparedNumbers {
            fetchAndObserveFalconUser(for: preparedNumber, asynchronously: false)
        }
    }
    
    fileprivate func fetchAsynchronously() {
        //add Plot user
        
        var preparedNumber = String()
        for number in localPhones {
            do {
                //possibly useless; just adds a plus sign and takes up memory
                let countryCode = try phoneNumberKit.parse(number).countryCode
                let nationalNumber = try phoneNumberKit.parse(number).nationalNumber
                //update number format
                preparedNumber = "+" + String(countryCode) + String(nationalNumber)
                //        print("Prepared Number: \(preparedNumber)")
            } catch {}
            
            fetchAndObserveFalconUser(for: preparedNumber, asynchronously: true)
        }
    }
    
    //need to redo fetchAndObserveFalconUser: fetch once and create user friendship node
    fileprivate func fetchAndObserveFalconUser(for preparedNumber: String, asynchronously: Bool) {
        
        //create reference to database + reference + child("users"); just a url
        reference = Database.database().reference()
        //create query that grabs a user's phone number
        reference.child("users").queryOrdered(byChild: "phoneNumber").queryEqual(toValue: preparedNumber).observeSingleEvent(of: .childAdded, with: { (snapshot) in
            
            //if phone number(s) exists in collection of user phone numbers
            //need to create friendship collection
            if snapshot.exists() {
                guard var dictionary = snapshot.value as? [String: AnyObject] else { return }
                if snapshot.key == self.userID! { return }
                
                self.reference.child("relationships").child(self.userID!).child(snapshot.key).setValue("true")
                
                
                dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                if let thumbnailURLString = User(dictionary: dictionary).thumbnailPhotoURL, let thumbnailURL = URL(string: thumbnailURLString) {
                    SDWebImagePrefetcher.shared.prefetchURLs([thumbnailURL])
                }
                
                //add user to self.users unless user already was added, then update user's dictionary - will continuously add current user since current user is removed below
                if let index = self.users.firstIndex(where: { (user) -> Bool in
                    return user.id == User(dictionary: dictionary).id
                }) {
                    self.users[index] = User(dictionary: dictionary)
                } else {
                    self.users.append(User(dictionary: dictionary))
                }
                
                self.users = self.sortUsers(users: self.users)
                //self.users = self.rearrangeUsers(users: self.users)
                
                //remove current user from users array
                if let index = self.users.firstIndex(where: { (user) -> Bool in
                    return user.id == self.userID!
                }) {
                    self.users.remove(at: index)
                }
                
                if asynchronously {
                    self.delegate?.falconUsers(shouldBeUpdatedTo: self.users)
                    //                                print("Updated delegate")
                }
                
            }
        }, withCancel: { (error) in
            print("error")
            //search error
        })
    }
    
    func rearrangeUsers(users: [User]) -> [User] { /* Moves Online users to the top  */
        var users = users
        guard users.count - 1 > 0 else { return users }
        for index in 0...users.count - 1 {
            if users[index].onlineStatus as? String == statusOnline {
                users = rearrange(array: users, fromIndex: index, toIndex: 0)
            }
        }
        
        return users
    }
    
    func sortUsers(users: [User]) -> [User] { /* Sort users by name  */
        return users.sorted { ($0.name! < $1.name!) }
    }
    
    
    //  func sortUsers(users: [User]) -> [User] { /* Sort users by last online date  */
    //    return users.sorted(by: { (user1, user2) -> Bool in
    //      if let firstUserOnlineStatus = user1.onlineStatus as? TimeInterval , let secondUserOnlineStatus = user2.onlineStatus as? TimeInterval {
    //        return (firstUserOnlineStatus, user1.phoneNumber ?? "") > ( secondUserOnlineStatus, user2.phoneNumber ?? "")
    //      } else {
    //        return ( user1.phoneNumber ?? "") > (user2.phoneNumber ?? "") // sort
    //      }
    //    })
    //  }
}
