//
//  ChatsTableViewController+SearchHandlers.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/13/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit


extension ChatsTableViewController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {}
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    filteredConversations = conversations
    filteredPinnedConversations = pinnedConversations
    handleReloadTable()
    searchBar.setShowsCancelButton(false, animated: true)
    searchBar.resignFirstResponder()
    tableView.tableHeaderView = nil
    return
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    
    filteredConversations = searchText.isEmpty ? conversations :
      conversations.filter({ (conversation) -> Bool in
        if let chatName = conversation.chatName {
          return chatName.lowercased().contains(searchText.lowercased())
        }
        return ("").lowercased().contains(searchText.lowercased())
      })
    
    filteredPinnedConversations = searchText.isEmpty ? pinnedConversations :
      pinnedConversations.filter({ (conversation) -> Bool in
        if let chatName = conversation.chatName {
          return chatName.lowercased().contains(searchText.lowercased())
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

extension ChatsTableViewController { /* hiding keyboard */
  
  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
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
