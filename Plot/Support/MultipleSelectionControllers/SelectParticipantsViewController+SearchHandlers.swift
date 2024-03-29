//
//  SelectParticipantsViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/11/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension SelectParticipantsViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        filteredUsers = users
        //    guard users.count > 0 else { return }
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        configureSections()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredUsers = searchText.isEmpty ? users : users.filter({ (User) -> Bool in
            return User.name!.lowercased().contains(searchText.lowercased())
        })
        configureSections()
    }
}

extension SelectParticipantsViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar?.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar?.endEditing(true)
    }
}


