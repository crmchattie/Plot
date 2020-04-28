//
//  SearchViewController.swift
//  AutocompleteExample
//
//  Created by George McDonnell on 26/04/2017.
//  Copyright © 2017 George McDonnell. All rights reserved.
//

import UIKit
import MapKit

protocol UpdateLocationDelegate: class {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String)
}

class LocationFinderTableViewController: UIViewController {

    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var searchBar: UISearchBar?
    let searchResultsTableView = UITableView()
    weak var delegate : UpdateLocationDelegate?
    
    var locationName = "Location"
    var locationAddress = ["locationAddress": [0.0]]
    
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


extension LocationFinderTableViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchCompleter.queryFragment = searchText
    }
}

extension LocationFinderTableViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
}

extension LocationFinderTableViewController: UITableViewDataSource {
    
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

extension LocationFinderTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let completion = searchResults[indexPath.row]
        var latitude = Double()
        var longitude = Double()
        
        locationName = String(completion.title)
        
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            let coordinates = response?.mapItems[0].placemark.coordinate
            latitude = coordinates!.latitude
            longitude = coordinates!.longitude
            
            print("response \(response!.mapItems[0].placemark)")
            let zipcode = response?.mapItems[0].placemark.postalCode ?? ""
            let city = response?.mapItems[0].placemark.locality ?? ""
            let state = response?.mapItems[0].placemark.administrativeArea ?? ""
            let countryCode = response?.mapItems[0].placemark.countryCode ?? ""
            
            self.locationAddress = [self.locationName: [latitude, longitude]]
            self.delegate?.updateLocation(locationName: self.locationName, locationAddress: self.locationAddress, zipcode: zipcode, city: city, state: state, country: countryCode)
//            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }

    }
}

extension LocationFinderTableViewController {
    
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
