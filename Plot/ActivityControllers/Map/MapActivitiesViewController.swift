//
//  MapActivitiesViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 11/15/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import FloatingPanel
import Contacts
import Firebase
import CodableFirebase


class MapActivitiesViewController: UIViewController, UISearchBarDelegate, FloatingPanelControllerDelegate {
    
    weak var activityViewController: ActivityViewController?
    var activities: [Activity] = [] {
        didSet {
            populateLocations()
        }
    }
    var locationActivities: [Activity] = []
    var conversations = [Conversation]()
    
    let fpc: FloatingPanelController = {
        let fpc = FloatingPanelController()
        return fpc
    }()
    
    let searchVC: SearchPanelViewController = {
        let searchVC = SearchPanelViewController()
        return searchVC
    }()
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        return mapView
    }()
    
    var chatLogController: ChatLogController? = nil
    var messagesFetcher: MessagesFetcher? = nil
            
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad map")
        view.backgroundColor = .clear
        view.addSubview(mapView)
        
        mapView.delegate = self
        
        fpc.delegate = self
        searchVC.activityCellDelegate = self
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false
        fpc.isRemovalInteractionEnabled = true

        // Set a content view controller
        fpc.set(contentViewController: searchVC)
        fpc.track(scrollView: searchVC.tableView)
        
        //  Add FloatingPanel to a view with animation.
        fpc.addPanel(toParent: self, animated: true)
        
        addObservers()
                
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        view.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        }
        searchVC.tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        searchVC.tableView.sectionIndexBackgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        searchVC.tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        searchVC.tableView.reloadData()
    }
    
    func myViewDidLoad() {
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        }
        searchVC.activityViewController = activityViewController
        searchVC.conversations = conversations
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Must be here
        //searchVC.searchBar.delegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        teardownMapView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.frame
    }
    
    func setupMapView() {
        mapView.showsCompass = true
        mapView.showsUserLocation = true
        mapView.delegate = self
    }
    
    func populateLocations() {
        locationActivities = []
        for activity in activities {
            if let locationAddress = activity.locationAddress {
                for (key, value) in locationAddress {
                    let locName = key
                    let latitude = value[0]
                    let longitude = value[1]

                    let annotation = ActivityAnnotation(activity: activity)
                    
                    annotation.title = activity.name
                    annotation.subtitle = locName
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.mapView.addAnnotation(annotation)
                }
                
                locationActivities.append(activity)
            }
        }
        
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        searchVC.activities = locationActivities
        searchVC.tableView.reloadData()

    }

    func teardownMapView() {
        // Prevent a crash
        mapView.delegate = nil
    }

    // MARK: UISearchBarDelegate

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton  = false
        searchVC.hideHeader()
        fpc.move(to: .half, animated: true)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        searchVC.showHeader()
        searchVC.tableView.alpha = 1.0
        fpc.move(to: .full, animated: true)
    }

    // MARK: FloatingPanelControllerDelegate
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        switch newCollection.verticalSizeClass {
        case .compact:
            fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
            fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)
            return SearchPanelLandscapeLayout()
        default:
            fpc.surfaceView.borderWidth = 0.0
            fpc.surfaceView.borderColor = nil
            return nil
        }
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)
        if y > tipY - 44.0 {
            let progress = max(0.0, min((tipY  - y) / 44.0, 1.0))
            self.searchVC.tableView.alpha = progress
        }
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            //searchVC.searchBar.showsCancelButton = false
            //searchVC.searchBar.resignFirstResponder()
        }
    }

    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition != .full {
            searchVC.hideHeader()
        }

        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: .allowUserInteraction,
                       animations: {
                            self.searchVC.tableView.alpha = 1.0
        }, completion: nil)
    }
    
}

extension MapActivitiesViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? ActivityAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                let rightButton = UIButton(type: .detailDisclosure)
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.rightCalloutAccessoryView = rightButton
            }
            
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.animatesDrop = true
            
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let location = view.annotation as? ActivityAnnotation else {
            return
        }
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        let addressDictionary = [CNPostalAddressStreetKey: location.subtitle ?? ""]
        let placemark = MKPlacemark(coordinate: location.coordinate, addressDictionary: addressDictionary)
        
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.subtitle
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        if let location = view.annotation as? ActivityAnnotation, let index = activities.firstIndex(where: {$0.activityID == location.activity.activityID}) {
//            print("activities count \(activities.count)")
//            print("selected annotation")
//            print("index \(index)")
//            let numberOfRows = searchVC.tableView.numberOfRows(inSection: 0)
//            if index < numberOfRows {
//                let indexPath = IndexPath(row: index, section: 0)
//                print("indexPath \(indexPath)")
//                searchVC.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
//            }
//        }
//    }
}

extension MapActivitiesViewController: ActivityCellDelegate {
    func openMap(forActivity activity: Activity) {
        if let annotations = self.mapView.annotations as? [ActivityAnnotation] {
            if let first = annotations.first(where: { (activityAnnotation) -> Bool in
                activityAnnotation.activity.activityID == activity.activityID
            }) {
                fpc.move(to: .tip, animated: true) {
                    self.mapView.showAnnotations([first], animated: true)
                    self.mapView.selectAnnotation(first, animated: true)
                }
            }
        }
    }
    
    func openChat(forConversation conversationID: String?, activityID: String?) {
        
        activityViewController!.openChat(forConversation: conversationID, activityID: activityID)
        
    }
    
}

class SearchPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var activityViewController: ActivityViewController?
    weak var activityCellDelegate: ActivityCellDelegate?
    
    var activities: [Activity] = []
    var invitations = [String: Invitation]()
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    let viewPlaceholder = ViewPlaceholder()
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    //@IBOutlet weak var searchBar: UISearchBar!
    
    let visualEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .extraLight)
        let visualEffectView = UIVisualEffectView(effect: effect)
        return visualEffectView
    }()

    // For iOS 10 only
    private lazy var shadowLayer: CAShapeLayer = CAShapeLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ActivityCell.self, forCellReuseIdentifier: activityCellID)
        tableView.isUserInteractionEnabled = true
        tableView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        tableView.separatorStyle = .none
        view.addSubview(visualEffectView)
        visualEffectView.contentView.addSubview(tableView)
        visualEffectView.isUserInteractionEnabled = true
        //searchBar.placeholder = "Search for a place or address"
        //searchBar.setSearchText(fontSize: 15.0)

        visualEffectView.frame = view.frame
        tableView.frame = visualEffectView.frame
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
        
        
        
        //hideHeader()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11, *) {
        } else {
            // Exmaple: Add rounding corners on iOS 10
            visualEffectView.layer.cornerRadius = 9.0
            visualEffectView.clipsToBounds = true

            // Exmaple: Add shadow manually on iOS 10
            view.layer.insertSublayer(shadowLayer, at: 0)
            let rect = visualEffectView.frame
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 9.0, height: 9.0))
            shadowLayer.frame = visualEffectView.frame
            shadowLayer.shadowPath = path.cgPath
            shadowLayer.shadowColor = UIColor.black.cgColor
            shadowLayer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            shadowLayer.shadowOpacity = 0.2
            shadowLayer.shadowRadius = 3.0
        }
    }
    
    func checkIfThereAnyActivities(isEmpty: Bool) {
        guard isEmpty else {
            viewPlaceholder.remove(from: tableView, priority: .medium)
            return
        }
        viewPlaceholder.add(for: tableView, title: .emptyActivities, subtitle: .emptyMap, priority: .medium, position: .top)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if activities.isEmpty {
            checkIfThereAnyActivities(isEmpty: true)
        } else {
            checkIfThereAnyActivities(isEmpty: false)
        }
        return activities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: activityCellID, for: indexPath)
         if let activityCell = cell as? ActivityCell {
               activityCell.delegate = activityCellDelegate
               activityCell.updateInvitationDelegate = activityViewController
               activityCell.activityViewControllerDataStore = activityViewController
               
               let activity = activities[indexPath.row]
               var invitation: Invitation?
               if let activityID = activity.activityID, let value = invitations[activityID] {
                   invitation = value
               }
               activityCell.configureCell(for: indexPath, activity: activity, withInvitation: invitation)
           }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let activity = activities[indexPath.row]
                
        activityViewController!.loadActivity(activity: activity)
    }

    func showHeader() {
        changeHeader(height: 116.0)
    }

    func hideHeader() {
        changeHeader(height: 0.0)
    }

    func changeHeader(height: CGFloat) {
        tableView.beginUpdates()
        if let headerView = tableView.tableHeaderView  {
            UIView.animate(withDuration: 0.25) {
                var frame = headerView.frame
                frame.size.height = height
                self.tableView.tableHeaderView?.frame = frame
            }
        }
        tableView.endUpdates()
    }
}

public class SearchPanelLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 44.0
        default: return nil
        }
    }

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        if #available(iOS 11.0, *) {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0),
                surfaceView.widthAnchor.constraint(equalToConstant: 291),
            ]
        } else {
            return [
                surfaceView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8.0),
                surfaceView.widthAnchor.constraint(equalToConstant: 291),
            ]
        }
    }

    public func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
}

class SearchCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
}

class SearchHeaderView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.clipsToBounds = true
    }
}

extension UISearchBar {
    func setSearchText(fontSize: CGFloat) {
        #if swift(>=5.1) // Xcode 11 or later
            let font = searchTextField.font
            searchTextField.font = font?.withSize(fontSize)
        #else
            let textField = value(forKey: "_searchField") as! UITextField
            textField.font = textField.font?.withSize(fontSize)
        #endif
    }
}
