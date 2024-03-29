//
//  SelectChatTableViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/8/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

extension SelectChatTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredUsers = users
//    guard users.count > 0 else { return }
    actions.append(newGroupAction)
    setUpCollation()
    self.tableView.reloadData()
    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    actions.removeAll()
    tableView.reloadData()
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
    setUpCollation()
    self.tableView.reloadData()
  }
}

extension SelectChatTableViewController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    searchBar?.resignFirstResponder()
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.searchBar?.endEditing(true)
  }
}
