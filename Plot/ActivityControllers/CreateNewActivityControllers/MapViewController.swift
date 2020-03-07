//
//  MapViewController.swift
//  Plot
//
//  Created by Cory McHattie on 6/30/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit
import MapKit
import GLKit

class MapViewController: UIViewController {
    
    var window: UIWindow?
    var mapView: MKMapView?
    
    // How much to show outside of the center
    fileprivate var regionRadius: CLLocationDistance = 1000
    var locationPoints = [CLLocationCoordinate2D]()
    
    // location manager to authorize user location for Maps app
    var locationManager = CLLocationManager()
    let mapAlertPresenter = MapAlertPresenter()
    var locationAddress = [String : [Double]]()
    let places = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        self.view.backgroundColor = UIColor.white
        
        self.mapView = MKMapView(frame: UIScreen.main.bounds)
        self.view.addSubview(self.mapView!)
        
        mapView!.delegate = self
        
        // always check to make sure we have permission before proceeding.
        checkLocationAuthorizationStatus()
        

    }
    
    fileprivate func queryPlaces() {
        var locName: String         // location name
        var latitude: Double
        var longitude: Double
        
        for (key, value) in locationAddress {
            locName = key
            latitude = value[0]
            longitude = value[1]
            
//            #if DEBUG
//            print("place is:", locName, "with latitude", latitude, "and longitude", longitude)
//            #endif
            let placeAnnotation = PlacesAnnotation(title: locName,
                                                     coordinate: CLLocationCoordinate2D(latitude: latitude,
                                                                                        longitude: longitude))
            self.mapView!.addAnnotation(placeAnnotation)
            
//            locationPoints.append(CLLocationCoordinate2D(latitude: latitude,
//                                                         longitude: longitude))
        }
        
        if let userLocation = locationManager.location {
            let placeAnnotation = PlacesAnnotation(title: "Current Location",
                                                   coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude,
                                                                                      longitude: userLocation.coordinate.longitude))
            self.mapView!.addAnnotation(placeAnnotation)
        }
        
        self.mapView!.showAnnotations(self.mapView!.annotations, animated: true)

    }
    
    /**
     Sets the location of the user on the map
     */
    fileprivate func centerMapOnLocation() {
//        guard let userLocation = locationManager.location else {
//            let centerPoint = getCenterCoord(locationPoints: locationPoints)
//            let coordinateRegion = MKCoordinateRegion(center: centerPoint.0,
//                                                      latitudinalMeters: centerPoint.1, longitudinalMeters: centerPoint.1)
//            mapView!.setRegion(coordinateRegion, animated: true)
//            return
//        }
//        locationPoints.append(CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude,
//                                                 longitude: userLocation.coordinate.longitude))
//        let centerPoint = getCenterCoord(locationPoints: locationPoints)
//        let coordinateRegion = MKCoordinateRegion(center: centerPoint.0,
//                                              latitudinalMeters: centerPoint.1, longitudinalMeters: centerPoint.1)
//        mapView!.setRegion(coordinateRegion, animated: true)

    }
    
    
    /**
     Checks to see if the user has authorized use of location services
     */
    fileprivate func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            mapView!.showsUserLocation = true
            queryPlaces()
//            centerMapOnLocation()
        } else {
            mapView!.showsUserLocation = false
            queryPlaces()
//            centerMapOnLocation()
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // center func
//    func getCenterCoord(locationPoints: [CLLocationCoordinate2D]) -> (CLLocationCoordinate2D, CLLocationDistance) {
//
//        var x:Float = 0.0
//        var y:Float = 0.0
//        var z:Float = 0.0
//
//        var secondLat: Double = locationPoints[0].latitude
//        var secondLong: Double = locationPoints[0].longitude
//        var maxDistance: CLLocationDistance = 0.0
//
//        for points in locationPoints {
//
//            let coordinateOne = CLLocation(latitude: points.latitude, longitude: points.longitude)
//
//            let lat = GLKMathDegreesToRadians(Float(points.latitude))
//            let long = GLKMathDegreesToRadians(Float(points.longitude))
//
//            let coordinateTwo = CLLocation(latitude: secondLat, longitude: secondLong)
//
//            let distanceInMeters = coordinateOne.distance(from: coordinateTwo)
//
//            if distanceInMeters > maxDistance {
//                maxDistance = distanceInMeters * 1.1
//            }
//
//            secondLat = points.latitude
//            secondLong = points.longitude
//
//            x += cos(lat) * cos(long)
//            y += cos(lat) * sin(long)
//            z += sin(lat)
//        }
//
//        x = x / Float(locationPoints.count)
//        y = y / Float(locationPoints.count)
//        z = z / Float(locationPoints.count)
//
//        let resultLong = atan2(y, x)
//        let resultHyp = sqrt(x * x + y * y)
//        let resultLat = atan2(z, resultHyp)
//
//
//        let result = CLLocationCoordinate2D(latitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(resultLat))), longitude: CLLocationDegrees(GLKMathRadiansToDegrees(Float(resultLong))))
//
//        print(result, maxDistance)
//
//        return (result, maxDistance)
//
//    }
}

// MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PlacesAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                let button = UIButton(type: .detailDisclosure)
//                button.setImage(UIImage(named: "Car"), for: UIControl.State())
                
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = button
                view.animatesDrop = true
                return view
            }
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView,
                 annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! PlacesAnnotation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        location.mapItem().openInMaps(launchOptions: launchOptions)
    }
}

// MARK: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // update if we can display the user location and use GPS
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView!.showsUserLocation = true
            queryPlaces()
            centerMapOnLocation()
        case .denied, .restricted, .notDetermined:
            mapView!.showsUserLocation = false
//            mapView!.removeAnnotations(mapView!.annotations)
            queryPlaces()
            centerMapOnLocation()
            // Show notification stating location services need enabling
            let alertController = mapAlertPresenter.presentAlertWarning(status)
            present(alertController, animated: true, completion: nil)
        @unknown default:
            return
        }
    }
}

extension CLAuthorizationStatus: AlertEnum {
    
}

struct MapAlertPresenter: UIAlertPresenter {
    
    func presentAlertWarning(_ type: AlertEnum) -> UIAlertController {
        switch type {
        case CLAuthorizationStatus.denied, CLAuthorizationStatus.restricted, CLAuthorizationStatus.notDetermined:
            let message = "To see your location relative to places, location services needs to be enabled. Please enable it for this app."
            let alertController = UIAlertController.init(title: "Please enable location services",
                                                         message: message,
                                                         preferredStyle: .alert)
            let settings = UIAlertAction(title: "Settings",
                                         style: .default) { (_) -> Void in
                                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                                return
                                            }
                                            if UIApplication.shared.canOpenURL(settingsUrl)  {
                                                if #available(iOS 10.0, *) {
                                                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                                    })
                                                }
                                                else  {
                                                    UIApplication.shared.openURL(settingsUrl)
                                                }
                                            }
            }
            alertController.addAction(settings)
            return alertController
        default:
            return UIAlertController(title: "", message: "", preferredStyle: .alert)
        }
    }
}

protocol AlertEnum {
    
}

protocol UIAlertPresenter {
    func presentAlertWarning(_ type: AlertEnum) -> UIAlertController
}
