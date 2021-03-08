//
//  Pin.swift
//  VirtualTourist
//
//  Created by Lixiang Zhang on 2/21/21.
//

import Foundation
import MapKit

struct Pin {
    var annotation: MKAnnotation
    var center: CLLocationCoordinate2D
    var span: MKCoordinateSpan
}
