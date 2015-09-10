//
//  User.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import CoreLocation

class User: NSObject {
  var name = ""
  var id: String
  var state: CLRegionState
  var token: String?
  var provider: String?
  var email: String?
  var admin = false

  init(name: String, id: String, state: CLRegionState) {
    self.name = name
    self.id = id
    self.state = state
    
    super.init()
  }
  
}