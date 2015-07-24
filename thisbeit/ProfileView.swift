//
//  ProfileView.swift
//  thisbeit
//
//  Created by Kyle Murphy on 7/23/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class ProfileView: UIViewController {
  var working = false
  
  @IBOutlet weak var textField: UITextField!
  @IBAction func tapButton(sender: AnyObject) {
    if !working {
      working = true
      let name = textField.text
      currentUser!.name = name
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        postRequest("update_name", ["token": token, "uid": currentUser!.id, "newname": name], {json in
          self.working = false
          self.dismiss()
        }, { _ in
          self.working = false
          self.dismiss()
        })
      }
    }
  }
  
  @IBAction func tapCancel(sender: AnyObject) {
    dismiss()
  }
  
  func dismiss() {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textField.text = currentUser?.name
  }
}