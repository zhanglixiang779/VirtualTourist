//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    let margin: CGFloat = 10
    let cellsPerRow = 3
    var photos: [Photo] = []
    var client = NetworkClient()
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: pin.latitude, longitudeDelta: pin.longitude)
        mapView.region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        errorLabel.isHidden = true
        fetchPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func refetch(_ sender: Any) {
        fetchPhotos()
    }
    private func getUrlString(serverId: String, photoId: String, secret: String) -> String {
        return "https://live.staticflickr.com/\(serverId)/\(photoId)_\(secret)_q.jpg"
    }
    
    private func fetchPhotos() {
        indicator.startAnimating()
        newCollectionButton.isEnabled = false
        client.getPhotos(latitude: pin.latitude, longitude: pin.longitude) { (response, error) in
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

}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.collectionViewCellId, for: indexPath) as! PhotoCell
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
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0)
        let size: CGFloat = (collectionView.frame.size.width - 4 * space) / 3.0
            return CGSize(width: size, height: size)
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photos.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
    }
}
