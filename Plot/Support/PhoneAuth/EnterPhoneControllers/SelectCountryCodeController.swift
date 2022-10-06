//
//  SelectCountryCodeController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 8/3/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit


protocol CountryPickerDelegate: AnyObject {
    func countryPicker(_ picker: SelectCountryCodeController, didSelectCountryWithName name: String, code: String, dialCode: String)
}

public var countryCode = NSLocale.current.regionCode
fileprivate var savedCountryCode = String()

class SelectCountryCodeController: UITableViewController {
    
    let countries = Country().countries
    var filteredCountries = [[String:String]]()
    
    var searchBar = UISearchBar()
    var searchController = UISearchController()
    
    weak var delegate: CountryPickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureSearchBar()
        configureTableView()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    fileprivate func configureView() {
        title = "Select your country"
        view.backgroundColor = .systemGroupedBackground
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.top
    }
    
    fileprivate func configureSearchBar() {
        if #available(iOS 11.0, *) {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.delegate = self
            searchController.definesPresentationContext = true
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            searchBar = UISearchBar()
            searchBar.delegate = self
            searchBar.placeholder = "Search"
            searchBar.searchBarStyle = .minimal
            searchBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
            tableView.tableHeaderView = searchBar
        }
    }
    
    fileprivate func configureTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.indicatorStyle = .default
        tableView.separatorStyle = .none
        filteredCountries = countries
    }
}

extension SelectCountryCodeController {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.tintColor = .systemGroupedBackground
        return view
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCountries.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "cell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
        cell.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
        cell.backgroundColor = .secondarySystemGroupedBackground
        //    cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        let countryName = filteredCountries[indexPath.row]["name"]!
        let countryDial = " " + filteredCountries[indexPath.row]["dial_code"]!
        
        let countryNameAttribute = [NSAttributedString.Key.foregroundColor: UIColor.label]
        let countryDialAttribute = [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        let countryNameAString = NSAttributedString(string: countryName, attributes: countryNameAttribute)
        let countryDialAString = NSAttributedString(string: countryDial, attributes: countryDialAttribute)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(countryNameAString)
        mutableAttributedString.append(countryDialAString)
        
        cell.textLabel?.attributedText = mutableAttributedString
        
        if countryCode == filteredCountries[indexPath.row]["code"]! {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    fileprivate func resetCheckmark() {
        for index in 0...filteredCountries.count {
            let indexPath = IndexPath(row: index , section: 0)
            let cell = tableView.cellForRow(at: indexPath)
            
            cell?.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        resetCheckmark()
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        countryCode = filteredCountries[indexPath.row]["code"]!
        delegate?.countryPicker(self, didSelectCountryWithName: filteredCountries[indexPath.row]["name"]!,
                                code: filteredCountries[indexPath.row]["code"]!,
                                dialCode: filteredCountries[indexPath.row]["dial_code"]!)
    }
}

extension SelectCountryCodeController: UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {}
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredCountries = searchText.isEmpty ? countries : countries.filter({ (data: [String : String]) -> Bool in
            return data["name"]!.lowercased().contains(searchText.lowercased()) || data["dial_code"]!.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredCountries = countries
        tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.keyboardAppearance = .default
        return true
    }
}

extension SelectCountryCodeController {
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if #available(iOS 11.0, *) {
            searchController.searchBar.endEditing(true)
        } else {
            self.searchBar.endEditing(true)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 11.0, *) {
            searchController.searchBar.endEditing(true)
        } else {
            self.searchBar.endEditing(true)
        }
    }
}
