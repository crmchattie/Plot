//
//  TimezoneFinderController.swift
//  Plot
//
//  Created by Cory McHattie on 1/8/21.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import MapKit

protocol UpdateTimeZoneDelegate: class {
    func updateTimeZone(startOrEndTimeZone: String, timeZone: TimeZone)
}

class TimeZoneViewController: UIViewController {
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var searchBar: UISearchBar?
    let searchResultsTableView = UITableView()
    weak var delegate : UpdateTimeZoneDelegate?
    
    var startOrEndTimeZone: String?
    
    var viewPlaceholder = ViewPlaceholder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSearchController()
        setupMainView()
        setupTableView()
        searchCompleter.delegate = self
        
        if #available(iOS 11.0, *) {
            let cancelBarButton =  UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            
            navigationItem.rightBarButtonItem = cancelBarButton
        } else {
            let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
            navigationItem.rightBarButtonItem = cancelBarButton
        }
    }
    
    fileprivate func setupSearchController() {
        searchBar = UISearchBar()
        searchBar?.delegate = self
        searchBar?.searchBarStyle = .minimal
        searchBar?.changeBackgroundColor(to: ThemeManager.currentTheme().searchBarColor)
        searchBar?.placeholder = "Search"
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        searchResultsTableView.tableHeaderView = searchBar
        searchBar?.becomeFirstResponder()
    }
    
    fileprivate func setupMainView() {
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        navigationItem.title = "Location"
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
    }
    
    fileprivate func setupTableView() {
        
        
        view.addSubview(searchResultsTableView)
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        } else {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        searchResultsTableView.sectionIndexBackgroundColor = view.backgroundColor
        searchResultsTableView.backgroundColor = view.backgroundColor
        searchResultsTableView.separatorStyle = .none
        
    }
    
    @objc func cancel() {
        //            self.dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    
    
    deinit {
        print("select location deinit")
    }
    
    func checkIfThereAreAnyLocations(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: searchResultsTableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: searchResultsTableView, title: .emptyLocationSearch, subtitle: .empty, priority: .medium, position: .top)
    }
    
}


extension TimeZoneViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchCompleter.queryFragment = searchText
    }
}

extension TimeZoneViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
}

extension TimeZoneViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchResults.count == 0 {
            checkIfThereAreAnyLocations(isEmpty: true)
        } else {
            checkIfThereAreAnyLocations(isEmpty: false)
        }
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        cell.textLabel?.textColor = ThemeManager.currentTheme().generalTitleColor
        cell.detailTextLabel?.textColor = ThemeManager.currentTheme().generalSubtitleColor
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    
}

extension TimeZoneViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if let coordinates = response?.mapItems[0].placemark.coordinate {
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                let geoCoder = CLGeocoder()
                geoCoder.reverseGeocodeLocation(location) { (placemarks, err) in
                    if let placemark = placemarks?[0], let timeZone = placemark.timeZone, let startOrEndTimeZone = self.startOrEndTimeZone {
                        self.delegate?.updateTimeZone(startOrEndTimeZone: startOrEndTimeZone, timeZone: timeZone)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

extension TimeZoneViewController {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == nil {
            cancel()
        }
        searchBar.text = nil
        //    guard users.count > 0 else { return }
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        searchResultsTableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = ThemeManager.currentTheme().keyboardAppearance
        searchBar.setShowsCancelButton(true, animated: true)
        
        return true
    }
    
}
