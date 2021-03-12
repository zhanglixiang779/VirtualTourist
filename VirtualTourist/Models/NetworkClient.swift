//
//  NetworkClient.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import Foundation
import MapKit

struct NetworkClient {
    
    let apiKey = "f16421683a9de3e6a9583e73c761c15f"
    var url: String = ""
    
    mutating func getPhotos(latitude: CLLocationDegrees, longitude: CLLocationDegrees, page: Int = 1, completion: @escaping (Response?, Error?) -> Void) {
        url = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&page=\(page)&format=json&nojsoncallback=1"
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
              
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data)
                    DispatchQueue.main.async {
                        completion(response, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
            task.resume()
        }
    }
    
    func downloadImage(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
 }
