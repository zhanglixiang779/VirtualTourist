//
//  Photo.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import Foundation

struct Photo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
