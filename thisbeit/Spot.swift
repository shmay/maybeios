//
//  Spot.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import MapKit

class Spot: NSObject {
  var name = ""
  let id: String
  var coordinate: CLLocationCoordinate2D?
  var radius: CLLocationDistance?
  var tracking: Bool = false
  var state: CLRegionState = .Unknown
  
  var yes = [User]()
  var no = [User]()
  var maybe = [User]()
  
  var admin = false
    
  init(name: String, id: String) {
    self.name = name
    self.id = id
    super.init()
  }

}