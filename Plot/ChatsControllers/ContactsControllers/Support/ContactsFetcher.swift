//
//  ContactsFetcher.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/20/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import Contacts

protocol ContactsUpdatesDelegate: class {
  func contacts(updateDatasource contacts: [CNContact])
  func contacts(handleAccessStatus: Bool)
}

class ContactsFetcher: NSObject {
  
  weak var delegate: ContactsUpdatesDelegate?
  
  func fetchContacts () {
    let status = CNContactStore.authorizationStatus(for: .contacts)
    let store = CNContactStore()
    if status == .denied || status == .restricted {
      delegate?.contacts(handleAccessStatus: false)
      return
    }
    
    store.requestAccess(for: .contacts) { granted, error in
      guard granted, error == nil else {
        self.delegate?.contacts(handleAccessStatus: false)
        return
      }
      
      self.delegate?.contacts(handleAccessStatus: true)
      
      let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey]
      let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
      var contacts = [CNContact]()
      do {
        try store.enumerateContacts(with: request) { contact, stop in
          contacts.append(contact)
        }
      } catch {}
      
      let phoneNumbers = contacts.flatMap({$0.phoneNumbers.map({$0.value.stringValue.digits})})
      //remove duplicate numbers so FalconUsersFetcher is quicker
      localPhones = Array(Set(phoneNumbers))
      contacts = self.sortContacts(contacts: contacts)
      self.delegate?.contacts(updateDatasource: contacts)
    }
  }
    
    func sortContacts(contacts: [CNContact]) -> [CNContact] { /* Sort users by name  */
        return contacts.sorted { ($0.givenName < $1.givenName) }
//        let sortedContacts = contacts.sort {
//            if $0.lastName != $1.lastName { // first, compare by last names
//                return $0.lastName < $1.lastName
//            }
//                /*  last names are the same, break ties by foo
//                 else if $0.foo != $1.foo {
//                 return $0.foo < $1.foo
//                 }
//                 ... repeat for all other fields in the sorting
//                 */
//            else { // All other fields are tied, break ties by last name
//                return $0.firstName < $1.firstName
//            }
//        }
    }
}
