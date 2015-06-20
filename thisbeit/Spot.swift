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
  
  var yes = 0
  var no = 0
  var maybe = 0
  
  var users = [User]()
  
  init(name: String, id: String) {
    self.name = name
    self.id = id
    super.init()
  }

}