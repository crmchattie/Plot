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


class MapActivitiesViewController: UIViewController, UISearchBarDelegate, FloatingPanelControllerDelegate {
    
    weak var activityViewController: ActivityViewController?
    var activities: [Activity] {
        return activityViewController?.activities ?? []
    }
    
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
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.addSubview(mapView)
        view.addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        mapView.delegate = self
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = ThemeManager.currentTheme().userInterfaceStyle
        }
        
        fpc.delegate = self
        searchVC.activityViewController = activityViewController
        searchVC.activityCellDelegate = self
        
        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.shadowHidden = false
        fpc.isRemovalInteractionEnabled = true

        // Set a content view controller
        fpc.set(contentViewController: searchVC)
        fpc.track(scrollView: searchVC.tableView)
        
        populateLocations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //  Add FloatingPanel to a view with animation.
        fpc.addPanel(toParent: self, animated: true)

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
        let closeButtonFrame = CGRect(x: view.frame.width - 45, y: 40, width: 30, height: 30)
        closeButton.frame = closeButtonFrame
    }
    
    func setupMapView() {
//        let center = CLLocationCoordinate2D(latitude: 37.623198015869235,
//                                            longitude: -122.43066818432008)
//        let span = MKCoordinateSpan(latitudeDelta: 0.4425100023575723,
//                                    longitudeDelta: 0.28543697435880233)
//        let region = MKCoordinateRegion(center: center, span: span)
//        mapView.region = region
        mapView.showsCompass = true
        mapView.showsUserLocation = true
        mapView.delegate = self
    }
    
    func populateLocations() {
        var locationActivities: [Activity] = []
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
    
    @objc func closeButtonTapped() {
        self.dismiss(animated: true, completion: nil)
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
        self.activityViewController?.openChat(forConversation: conversationID, activityID: activityID)
    }
}

class SearchPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var activityViewController: ActivityViewController?
    weak var activityCellDelegate: ActivityCellDelegate?
    
    var activities: [Activity] = []
    
    var invitations: [String: Invitation] {
        return activityViewController?.invitations ?? [:]
    }
    
    var users: [User] {
        return activityViewController?.users ?? []
    }
    
    var filteredUsers: [User] {
        return activityViewController?.filteredUsers ?? []
    }
    
    var conversations: [Conversation] {
        return activityViewController?.conversations ?? []
    }
    
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        
//        if let navController = self.navigationController {
//            self.showSpinner(onView: navController.view)
//        } else {
//            self.showSpinner(onView: self.view)
//        }
        
        let activity = activities[indexPath.row]
        let destination = CreateActivityViewController()
        destination.hidesBottomBarWhenPushed = true
        destination.activity = activity
        destination.invitation = invitations[activity.activityID!]
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.conversations = conversations
        
        activityViewController?.getParticipants(forActivity: activity) { [weak self] (participants) in
//            self?.removeSpinner()
            destination.selectedFalconUsers = participants
            self?.navigationController?.pushViewController(destination, animated: true)
        }
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
