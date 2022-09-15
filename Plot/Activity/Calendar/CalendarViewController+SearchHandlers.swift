//
//  ActivityViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/27/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit


extension CalendarViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        activityView.tableView.tableHeaderView = nil
        handleReloadTableAftersearchBarCancelButtonClicked()
        return
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredPinnedActivities = searchText.isEmpty ? pinnedActivities :
            pinnedActivities.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        filteredActivities = searchText.isEmpty ? activities :
            activities.filter({ (activity) -> Bool in
                if let name = activity.name {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return ("").lowercased().contains(searchText.lowercased())
            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
}

extension CalendarViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar?.endEditing(true)
        if let cancelButton : UIButton = searchBar?.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        self.searchBar?.endEditing(true)
        if let cancelButton : UIButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
}
