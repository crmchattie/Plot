//
//  MapViewController.swift
//  MapsDirectionsGooglePlaces_LBTA
//
//  Created by Brian Voong on 11/3/19.
//  Copyright © 2019 Brian Voong. All rights reserved.
//

import UIKit
import MapKit
import LBTATools

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is CustomMapItemAnnotation) { return nil }
        
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "id")
        
        if (annotation is CustomMapItemAnnotation) {
            annotationView.canShowCallout = true
            if let placeAnnotation = annotation as? CustomMapItemAnnotation {
                if let type = placeAnnotation.type {
                    annotationView.image = UIImage(named: "\(type)-color")
                }
            }
        }
        return annotationView
    }
    
}

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    var sections = [SectionType]()
    var locations = [SectionType: AnyHashable]()
    
    fileprivate func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Received authorization of user location")
            // request for where the user actually is
            locationManager.startUpdatingLocation()
        default:
            print("Failed to authorize")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.isHidden = true
        navigationItem.largeTitleDisplayMode = .never
        
        requestUserLocation()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        mapView.fillSuperview()
                
        addAnnotations()
        setupViews()
        locationsController.mapViewController = self
        
    }

    let locationsController = LocationsCarouselController(scrollDirection: .horizontal)
    
    fileprivate func setupViews() {
        let locationsView = locationsController.view!
        view.addSubview(locationsView)
        view.addSubview(closeButton)
        locationsView.anchor(top: nil, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 20, right: 0), size: .init(width: 0, height: 100))
        closeButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 25), size: .init(width: 50, height: 50))
    }
    
    var listener: Any!
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
                
        guard let index = self.locationsController.items.firstIndex(where: {$0.name == annotation.title}) else { return }
                
        self.locationsController.collectionView.scrollToItem(at: [0, index], at: .centeredHorizontally, animated: true)
    }
    
    func addAnnotations() {
        for section in sections {
            var name = String()
            var address = String()
            var type = String()
            var category = String()
            var subcategory = String()
            var latitude = Double()
            var longitude = Double()
            
            if let events = locations[section] as? [Event] {
                for event in events {
                    if let add = event.embedded?.venues?[0].address?.line1, let lat = event.embedded?.venues?[0].location?.latitude, let lon = event.embedded?.venues?[0].location?.longitude {
                        name = event.name
                        type = section.image
                        address = add
                        if let startDateTime = event.dates?.start?.dateTime, let date = startDateTime.toDate() {
                            let newDate = date.startDateTimeString()
                            category = "\(newDate)"
                        }
                        latitude = Double(lat) ?? 0.0
                        longitude = Double(lon) ?? 0.0
                                                
                        let annotation = CustomMapItemAnnotation()
                        let placemark = MKPlacemark(coordinate: .init(latitude: latitude, longitude: longitude))
                        let mapItem = MKMapItem(placemark: placemark)
                        annotation.mapItem = mapItem
                        annotation.title = name
                        annotation.subtitle = address
                        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        annotation.type = type
                                    
                        self.mapView.addAnnotation(annotation)
                        
                        // tell my locationsCarouselController
                        let locationStruct = LocationStruct(name: name, address: address, type: type, category: category, subcategory: subcategory, lat: latitude, lon: longitude)
                        self.locationsController.items.append(locationStruct)
                    }
                }
            } else if let places = locations[section] as? [FSVenue] {
                for place in places {
                    if let location = place.location, let add = location.formattedAddress?[0], let lat = location.lat, let lon = location.lng {
                        name = place.name
                        type = section.image
                        address = add
                        category = location.crossStreet ?? "No cross street"
                        if let categories = place.categories, !categories.isEmpty, let sub = categories[0].shortName {
                            subcategory = sub
                        } else {
                            subcategory = "No category"
                        }
                        latitude = lat
                        longitude = lon
                        
                        let annotation = CustomMapItemAnnotation()
                        let placemark = MKPlacemark(coordinate: .init(latitude: latitude, longitude: longitude))
                        let mapItem = MKMapItem(placemark: placemark)
                        annotation.mapItem = mapItem
                        annotation.title = name
                        annotation.subtitle = address
                        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        annotation.type = type
                                    
                        self.mapView.addAnnotation(annotation)
                        
                        // tell my locationsCarouselController
                        let locationStruct = LocationStruct(name: name, address: address, type: type, category: category, subcategory: subcategory, lat: lat, lon: lon)
                        self.locationsController.items.append(locationStruct)
                    }
                }
            } else if let items = locations[section] as? [GroupItem] {
                for item in items {
                    if let place = item.venue {
                        if let location = place.location, let add = location.formattedAddress?[0], let lat = location.lat, let lon = location.lng {
                            name = place.name
                            type = section.image
                            address = add
                            category = location.crossStreet ?? "No cross street"
                            if let categories = place.categories, !categories.isEmpty, let sub = categories[0].shortName {
                                subcategory = sub
                            } else {
                                subcategory = "No category"
                            }
                            latitude = lat
                            longitude = lon
                            
                            let annotation = CustomMapItemAnnotation()
                            let placemark = MKPlacemark(coordinate: .init(latitude: latitude, longitude: longitude))
                            let mapItem = MKMapItem(placemark: placemark)
                            annotation.mapItem = mapItem
                            annotation.title = name
                            annotation.subtitle = address
                            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            annotation.type = type
                                        
                            self.mapView.addAnnotation(annotation)
                            
                            // tell my locationsCarouselController
                            let locationStruct = LocationStruct(name: name, address: address, type: type, category: category, subcategory: subcategory, lat: lat, lon: lon)
                            self.locationsController.items.append(locationStruct)
                        }
                    }
                }
            } else if let activities = locations[section] as? [Activity] {
                for activity in activities {
                    if let na = activity.name, let add = activity.locationName, let locationAddress = activity.locationAddress, let array = locationAddress[add], let startDate = activity.startDateTime as? TimeInterval, let endDate = activity.endDateTime as? TimeInterval, let allDay = activity.allDay {
                        
                        category = ""
                        subcategory = ""
                        let startDate = Date(timeIntervalSince1970: startDate)
                        let endDate = Date(timeIntervalSince1970: endDate)
                        let startDateFormatter = DateFormatter()
                        let endDateFormatter = DateFormatter()
                        startDateFormatter.dateFormat = "d"
                        endDateFormatter.dateFormat = "d"
                        if let startTimeZone = activity.startTimeZone {
                            startDateFormatter.timeZone = TimeZone(identifier: startTimeZone)
                        } else {
                            startDateFormatter.timeZone = TimeZone(identifier: "UTC")
                        }
                        if let endTimeZone = activity.endTimeZone {
                            endDateFormatter.timeZone = TimeZone(identifier: endTimeZone)
                        } else {
                            endDateFormatter.timeZone = TimeZone(identifier: "UTC")
                        }
                    
                        let numberFormatter = NumberFormatter()
                        numberFormatter.numberStyle = .ordinal
                        
                        var startDay = ""
                        var day = startDateFormatter.string(from: startDate)
                        if let integer = Int(day) {
                            let number = NSNumber(value: integer)
                            startDay = numberFormatter.string(from: number) ?? ""
                        }
                        
                        var endDay = ""
                        day = endDateFormatter.string(from: endDate)
                        if let integer = Int(day) {
                            let number = NSNumber(value: integer)
                            endDay = numberFormatter.string(from: number) ?? ""
                        }
                        
                        startDateFormatter.dateFormat = "EEEE, MMM"
                        category += "\(startDateFormatter.string(from: startDate)) \(startDay)"
                        
                        if allDay {
                            category += " All Day"
                        } else {
                            startDateFormatter.dateFormat = "h:mm a"
                            category += " \(startDateFormatter.string(from: startDate))"
                        }
                        
                        if startDate.stripTime().compare(endDate.stripTime()) != .orderedSame {
                            
                            endDateFormatter.dateFormat = "EEEE, MMM"
                            subcategory += "\(endDateFormatter.string(from: endDate)) \(endDay) "
                            
                            if allDay {
                                subcategory += "All Day"
                            }
                        }

                        if !allDay {
                            endDateFormatter.dateFormat = "h:mm a"
                            subcategory += "\(endDateFormatter.string(from: endDate))"
                        }
                    
                        name = na
                        address = add
                        latitude = array[0]
                        longitude = array[1]
                        
                        switch activity.category?.lowercased() {
                        case "sleep":
                            type = "sleep"
                        case "meal":
                            type = "food"
                        case "work":
                            type = "work"
                        case "social":
                            type = "nightlife"
                        case "leisure":
                            type = "leisure"
                        case "exercise":
                            type = "workout"
                        case "workout":
                            type = "workout"
                        case "school":
                            type = "school"
                        case "to-do":
                            type = "todo"
                        case "family":
                            type = "family"
                        case "personal":
                            type = "personal"
                        default:
                            type = "activity"
                        }
                        
                        let annotation = CustomMapItemAnnotation()
                        let placemark = MKPlacemark(coordinate: .init(latitude: latitude, longitude: longitude))
                        let mapItem = MKMapItem(placemark: placemark)
                        annotation.mapItem = mapItem
                        annotation.title = name
                        annotation.subtitle = address
                        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        annotation.type = type
                                    
                        self.mapView.addAnnotation(annotation)
                        
                        // tell my locationsCarouselController
                        let locationStruct = LocationStruct(name: name, address: address, type: type, category: category, subcategory: subcategory, lat: latitude, lon: longitude)
                        self.locationsController.items.append(locationStruct)

                    }
                }
            }
        }
            
        if locations.count != 0 {
            self.locationsController.collectionView.scrollToItem(at: [0, 0], at: .centeredHorizontally, animated: true)
        }
        
        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
            
    }
    
    class CustomMapItemAnnotation: MKPointAnnotation {
        var mapItem: MKMapItem?
        var type: String?
    }
}

// SwiftUI Preview
import SwiftUI

struct MapPreview: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<MapPreview.ContainerView>) -> MapViewController {
            return MapViewController()
        }
        
        func updateUIViewController(_ uiViewController: MapViewController, context: UIViewControllerRepresentableContext<MapPreview.ContainerView>) {
            
        }
        
        typealias UIViewControllerType = MapViewController
    }
}

public func lookupLocation(for address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = address
    let search = MKLocalSearch(request: searchRequest)
    search.start { (response, error) in
        if let res = response {
            completion(res.mapItems[0].placemark.coordinate)
        }
    }
}
