//
//  UserController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 7/21/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation

import UIKit

protocol UserControllerDelegate {
  func userController(controller: UserController, removedUser user:User)
}
class UserController: UITableViewController {
  var user: User!
  
  @IBOutlet weak var removeBtn: UIButton!
  var delegate: UserControllerDelegate!

  @IBAction func tapCancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func tapRemove(sender: AnyObject) {
    let msg = "User will not be able to rejoin this spot without receiving an invitation"
    
    var alert = UIAlertController(title: "Are you sure?", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
    
    alert.addAction(UIAlertAction(title: "I'm sure", style: .Destructive, handler: { action in
      self.delegate.userController(self, removedUser: self.user)
    }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = user.name
  }
  
}