//
//  SearchViewController.swift
//  AutocompleteExample
//
//  Created by George McDonnell on 26/04/2017.
//  Copyright © 2017 George McDonnell. All rights reserved.
//

import UIKit
import MapKit

protocol UpdateLocationDelegate: AnyObject {
    func updateLocation(locationName: String, locationAddress: [String : [Double]], zipcode: String, city: String, state: String, country: String)
}

class LocationFinderTableViewController: UIViewController {

    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    var searchBar: UISearchBar?
    let searchResultsTableView = UITableView(frame: .zero, style: .insetGrouped)
    
    weak var delegate : UpdateLocationDelegate?
    
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
        searchBar?.placeholder = "Search"
        searchBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        searchResultsTableView.tableHeaderView = searchBar
        searchBar?.becomeFirstResponder()
    }
    
    fileprivate func setupMainView() {
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.title = "Location"
        view.backgroundColor = .systemGroupedBackground
    }
    
    fileprivate func setupTableView() {
        view.addSubview(searchResultsTableView)
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        if #available(iOS 11.0, *) {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        } else {
            searchResultsTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
            searchResultsTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        }
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.indicatorStyle = .default
        searchResultsTableView.sectionIndexBackgroundColor = view.backgroundColor
        searchResultsTableView.backgroundColor = view.backgroundColor
        searchResultsTableView.separatorStyle = .none
        searchResultsTableView.keyboardDismissMode = .onDrag

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
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        10
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .systemGroupedBackground
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = .label
        }
    }

}

extension LocationFinderTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if let res = response {
                
                let placemark = res.mapItems[0].placemark
                let coordinates = placemark.coordinate
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                let zipcode = placemark.postalCode ?? ""
                let city = placemark.locality ?? ""
                let state = placemark.administrativeArea ?? ""
                let countryCode = placemark.countryCode ?? ""
                let locationName = String(completion.title).removeCharacters()
                let locationAddress = [locationName: [latitude, longitude]]
                
                self.delegate?.updateLocation(locationName: locationName, locationAddress: locationAddress, zipcode: zipcode, city: city, state: state, country: countryCode)
                self.navigationController?.popViewController(animated: true)
            }
        }

    }
}

extension LocationFinderTableViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
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
        searchBar.keyboardAppearance = .default
        searchBar.setShowsCancelButton(true, animated: true)
        
        return true
    }
    
}
