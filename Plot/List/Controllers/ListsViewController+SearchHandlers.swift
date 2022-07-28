//
//  ListViewController+SearchHandlers.swift
//  Plot
//
//  Created by Cory McHattie on 5/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

extension ListsViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.tableHeaderView = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        sortandreload()
        return
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredlistList = searchText.isEmpty ? listList :
            listList.filter({ (list) -> Bool in
                return list.name.lowercased().contains(searchText.lowercased())
            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
}

extension ListsViewController { /* hiding keyboard */
    
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
