//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/20/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins: [Pin] = []
    
    var dataController: DataController!
    
    // Persist pin instance
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    // Persist map center and zoom level
    let userDefaults = UserDefaults.standard
    
    var isFirstTimeOpenApp: Bool {
        !userDefaults.bool(forKey: Constants.isFirstTimeOpenApp)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        mapView.delegate = self
        retrieveLastCenterAndZoomLevel()
        setupFetchedResultsController()
        initPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        deselectAnnotations()
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PhotoAlbumViewController {
            if let pin = sender as? Pin {
                destination.pin = pin
                destination.dataController = dataController
            }
        }
        
        let backItem = UIBarButtonItem()
        backItem.title = "OK"
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func longPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            addPin(gestureRecognizer: gestureRecognizer)
        }
    }
    
    // MARK: private functions
    
    private func retrieveLastCenterAndZoomLevel() {
        if !isFirstTimeOpenApp {
            restoreCenterAndZoomLevel()
        } else {
            userDefaults.set(true, forKey: Constants.isFirstTimeOpenApp)
        }
    }
    
    private func initPins() {
        fetchedResultsController.fetchedObjects?.forEach{ pin in
            addPinOnMap(latitude: pin.latitude, longitude: pin.longitude)
            pins.append(pin)
        }
    }
    
    private func addPinOnMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    private func addPin(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addPinOnMap(latitude: coordinate.latitude, longitude: coordinate.longitude)
        persistPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
        mapView.setCenter(coordinate, animated: true)
    }
    
    private func deselectAnnotations() {
        mapView.selectedAnnotations.forEach { (annotation) in
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.backgroundContext, sectionNameKeyPath: nil, cacheName: "pins")
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
}

// MARK: MapViewDelegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
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
        pins.forEach { pin in
            if pin.latitude == annotation?.coordinate.latitude {
                performSegue(withIdentifier: Constants.segueIdentifier, sender: pin)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistCenterAndZoomLevel()
    }
}

// MARK: Local persistence

extension TravelLocationsMapViewController {
    
    private func persistPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let span = mapView.region.span
        let pin = Pin(context: dataController.backgroundContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.longitudeDelta = span.latitudeDelta
        pin.longitudeDelta = span.longitudeDelta
        pins.append(pin)
        try? dataController.backgroundContext.save()
    }
    
    private func persistCenterAndZoomLevel() {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        let latitudeDelta = mapView.region.span.latitudeDelta
        let longitudeDelta = mapView.region.span.longitudeDelta
        userDefaults.set(latitude, forKey: Constants.latitudeKey)
        userDefaults.set(longitude, forKey: Constants.longitudeKey)
        userDefaults.set(latitudeDelta, forKey: Constants.latitudeDeltaKey)
        userDefaults.set(longitudeDelta, forKey: Constants.longitudeDeltaKey)
    }
    
    private func restoreCenterAndZoomLevel() {
        let latitude = userDefaults.double(forKey: Constants.latitudeKey)
        let longitude = userDefaults.double(forKey: Constants.longitudeKey)
        let latitudeDelta = userDefaults.double(forKey: Constants.latitudeDeltaKey)
        let longitudeDelta = userDefaults.double(forKey: Constants.longitudeDeltaKey)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        mapView.region = MKCoordinateRegion(center: center, span: span)
    }
}

