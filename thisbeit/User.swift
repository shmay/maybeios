//
//  User.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation

enum IsThere: Int {
  case No = 0
  case Yes
  case Maybe
  
  var desc : String {
    get {
      switch(self) {
      case No:
        return "No"
      case Yes:
        return "Yes"
      case Maybe:
        return "Maybe"
      }
    }
  }
}

class User: NSObject {
  var name = ""
  var id: String
  var isThere: IsThere
  var token: String?

  init(name: String, id: String, isThere: IsThere) {
    self.name = name
    self.id = id
    self.isThere = isThere
    
    super.init()
  }
  
}