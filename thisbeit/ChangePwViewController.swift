//
//  ChangePwViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 9/8/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class ChangePwViewController: UIViewController {
  var ref = Firebase(url:fbaseURL)
  var spinning = false
  
  @IBAction func tapCancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  @IBOutlet weak var oldPw: UITextField!
  @IBOutlet weak var newPw: UITextField!
  
  @IBAction func tapChange(sender: AnyObject) {
    if let e = currentUser!.email {
      ref.changePasswordForUser(e, fromOld: oldPw.text,
        toNew: newPw.text, withCompletionBlock: { error in
          if error != nil {
            showSimpleAlertWithTitle("Error!", message: "An error occurred while trying to change your password", viewController: self, onok: nil)
            // There was an error processing the request
          } else {
            showSimpleAlertWithTitle("Success!", message: "Successfully changed your password", viewController: self, onok: nil)
            self.dismissViewControllerAnimated(true, completion: nil)
            // Password changed successfully
          }
      })
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    println("viewWillAppear signin")
    
    oldPw.text = ""
    newPw.text = ""
    println("viewWillAppear")
  }
}