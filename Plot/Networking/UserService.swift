//
//  UsersService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Contacts

class UserService {
    let falconUsersFetcher = FalconUsersFetcher()
    let contactsFetcher = ContactsFetcher()
    
    var contacts = [CNContact]()
    var users = [User]()
    
    init() {
        contactsFetcher.delegate = self
        falconUsersFetcher.delegate = self
    }
    
    func grabContacts() {
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.contactsFetcher.fetchContacts()
        }
    }
    
    func grabUsers() {
        DispatchQueue.global(qos: .default).async { [unowned self] in
            self.falconUsersFetcher.fetchFalconUsers(asynchronously: true)
        }
    }
}

extension UserService: ContactsUpdatesDelegate {
    func contacts(updateDatasource contacts: [CNContact]) {
        self.contacts = contacts
        grabUsers()
    }
    func contacts(handleAccessStatus: Bool) {
        
    }
}

extension UserService: FalconUsersUpdatesDelegate {
    func falconUsers(shouldBeUpdatedTo users: [User]) {
        self.users = users
    }
}
