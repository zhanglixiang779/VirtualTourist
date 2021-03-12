//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var isReload = false
    var photos: [Photo] = []
    var photoIds: [String] = []
    var client = NetworkClient()
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Image>!
    
    var fetchedObjects: [Image]? {
        return fetchedResultsController.fetchedObjects
    }
    
    var isImagesPersisted: Bool {
        return fetchedObjects?.count ?? 0 > 0
    }
    
    var shouldFetchLocally: Bool {
        isImagesPersisted && !isReload
    }
    
    var count: Int {
        if shouldFetchLocally {
            return fetchedObjects!.count
        } else {
            return photos.count
        }
    }
    
    deinit {
        fetchedResultsController = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: pin.latitudeDelta, longitudeDelta: pin.longitudeDelta)
        mapView.region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        collectionView.dataSource = self
        collectionView.delegate = self
        errorLabel.isHidden = true
        setupFetchedResultsController()
        if !isImagesPersisted {
            fetchPhotos()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let backgroundContext: NSManagedObjectContext = dataController.backgroundContext
        backgroundContext.perform {
            try? backgroundContext.save()
        }
    }
    
    @IBAction func refetch(_ sender: Any) {
        isReload = true
        let ramdomInt = Int.random(in: 1..<100)
        fetchPhotos(page: ramdomInt)
    }
    
    // MARK: private functions
    
    private func getUrlString(serverId: String, photoId: String, secret: String) -> String {
        return "https://live.staticflickr.com/\(serverId)/\(photoId)_\(secret)_q.jpg"
    }
    
    private func fetchPhotos(page: Int = 1) {
        indicator.startAnimating()
        newCollectionButton.isEnabled = false
        client.getPhotos(latitude: pin.latitude, longitude: pin.longitude, page: page) { (response, error) in
            guard let response = response else {
                self.indicator.stopAnimating()
                return
            }
    
            self.indicator.stopAnimating()
            self.newCollectionButton.isEnabled = true
            self.photos = response.photos.photo
            self.collectionView.reloadData()
            
            if self.photos.count == 0 {
                self.errorLabel.isHidden = false
            }
        }
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: true)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.backgroundContext, sectionNameKeyPath: nil, cacheName: "images")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    private func persistImage(data: Data, id: String, position: Int) {
        if !photoIds.contains(id) {
            let image = Image(context: self.dataController.backgroundContext)
            dataController.backgroundContext.insert(image)
            image.data = data
            image.pin = self.pin
            image.position = Int64(position)
            photoIds.append(id)
        }
    }
    
    private func updateCellFromLocal(indexPath: IndexPath, cell: PhotoCell) {
        if let data = fetchedResultsController.object(at: indexPath).data {
            cell.imageView.image = UIImage(data: data)
        }
    }
    
    private func updateCellFromRemote(indexPath: IndexPath, cell: PhotoCell) {
        let photo = photos[indexPath.row]
        let urlString = getUrlString(serverId: photo.server, photoId: photo.id, secret: photo.secret)
        cell.imageView.image = UIImage(named: "VirtualTourist")
        if let url = URL(string: urlString) {
            client.downloadImage(url: url) { (data, error) in
                guard let data = data else {
                    return
                }
            
                cell.imageView.image = UIImage(data: data)
                cell.setNeedsLayout()
                self.persistImage(data: data, id: photo.id, position: indexPath.row)
            }
        }
    }

}

// MARK: CollectionViewDataSource and CollectionViewDelegateFlowLayout

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.collectionViewCellId, for: indexPath) as! PhotoCell
        
        if shouldFetchLocally {
            updateCellFromLocal(indexPath: indexPath, cell: cell)
        } else {
            updateCellFromRemote(indexPath: indexPath, cell: cell)
        }
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let space: CGFloat = flowLayout?.minimumInteritemSpacing ?? 0.0
        let size: CGFloat = (collectionView.frame.size.width - 4 * space) / 3.0
            return CGSize(width: size, height: size)
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageToDelete = fetchedResultsController.object(at: indexPath)
        dataController.backgroundContext.delete(imageToDelete)
        try? dataController.backgroundContext.save()
    }
}

// MARK: FetchedResultsControllerDelegate

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if case .delete = type {
            collectionView.deleteItems(at: [indexPath!])
        }
    }
}
