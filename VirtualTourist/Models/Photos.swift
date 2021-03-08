//
//  Photos.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import Foundation

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}
