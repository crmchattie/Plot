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
        searchBar.text = nil
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.resignFirstResponder()
            return
        }
        
        handleReloadTableAftersearchBarCancelButtonClicked()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
//        filteredLists = searchText.isEmpty ? activities :
//            lists.filter({ (list) -> Bool in
//                if let name = list.name {
//                    return name.lowercased().contains(searchText.lowercased())
//                }
//                return ("").lowercased().contains(searchText.lowercased())
//            })
        
        handleReloadTableAfterSearch()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        guard #available(iOS 11.0, *) else {
            searchBar.setShowsCancelButton(true, animated: true)
            return true
        }
        return true
    }
}

extension ListsViewController { /* hiding keyboard */
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchController?.searchBar.endEditing(true)
        } else {
            self.searchBar?.endEditing(true)
        }
    }
}
