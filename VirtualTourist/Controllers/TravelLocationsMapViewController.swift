//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/20/21.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let userDefaults = UserDefaults.standard
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var latitudeDelta: CLLocationDegrees = 0
    var longitudeDelta: CLLocationDegrees = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        mapView.delegate = self
        latitude = userDefaults.double(forKey: Constants.latitudeKey)
        longitude = userDefaults.double(forKey: Constants.longitudeKey)
        latitudeDelta = userDefaults.double(forKey: Constants.latitudeDeltaKey)
        longitudeDelta = userDefaults.double(forKey: Constants.longitudeDeltaKey)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        mapView.region = MKCoordinateRegion(center: center, span: span)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PhotoAlbumViewController {
            if let pin = sender as? Pin {
                destination.pin = pin
            }
        }
        
        let backItem = UIBarButtonItem()
        backItem.title = "OK"
        navigationItem.backBarButtonItem = backItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        deselectAnnotations()
    }
    
    @objc func longPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            addAnnotation(gestureRecognizer: gestureRecognizer)
        }
    }
    
    private func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
        mapView.setCenter(newCoordinates, animated: true)
    }
    
    private func deselectAnnotations() {
        mapView.selectedAnnotations.forEach { (annotation) in
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // MARK: MapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = Constants.annotationViewReuseId
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            annotationView?.canShowCallout = false
            annotationView?.pinTintColor = .green
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        let pin = Pin(annotation: annotation!, center: center, span: span)
        performSegue(withIdentifier: Constants.segueIdentifier, sender: pin)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        latitude = mapView.centerCoordinate.latitude
        longitude = mapView.centerCoordinate.longitude
        latitudeDelta = mapView.region.span.latitudeDelta
        longitudeDelta = mapView.region.span.longitudeDelta
        userDefaults.set(latitude, forKey: Constants.latitudeKey)
        userDefaults.set(longitude, forKey: Constants.longitudeKey)
        userDefaults.set(latitudeDelta, forKey: Constants.latitudeDeltaKey)
        userDefaults.set(longitudeDelta, forKey: Constants.longitudeDeltaKey)
    }
}

