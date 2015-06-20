//
//  SpotViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class SpotViewController: UITableViewController {
  
  var spot: Spot?
  
  var yes = [User]()
  var no = [User]()
  var maybe = [User]()
  
  func setupDict(spt: Spot) {
    yes = [User]()
    no = [User]()
    maybe = [User]()
    
    for user in spt.users {
      if user.isThere == .Yes {
        yes.append(user)
      } else if user.isThere == .No {
        no.append(user)
      } else if user.isThere == .Maybe {
        maybe.append(user)
      }
    }
    
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    var cnt = 0
    
    if maybe.count > 1 { cnt = cnt + 1 }
    if yes.count > 1 { cnt = cnt + 1 }
    if no.count > 1 { cnt = cnt + 1 }
    
    return cnt
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "hey"
  }

}