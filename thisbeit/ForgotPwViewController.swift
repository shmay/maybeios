//
//  ForgotPwViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 9/7/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class ForgotPwViewController: UIViewController {
  var ref = Firebase(url:fbaseURL)
  var spinning = false
  
  @IBOutlet weak var emailField: UITextField!
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBAction func tapGo(sender: AnyObject) {
    gogo()
  }
  
  @IBAction func tapCancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func gogo() {
    spin()
    ref.resetPasswordForUser(emailField.text, withCompletionBlock: { error in
      self.stopSpin()
      if error != nil {
        showSimpleAlertWithTitle("Error!", message: "An error occurred while trying to reset your password", viewController: self, onok: nil)
        // There was an error processing the request
      } else {
        showSimpleAlertWithTitle("Email sent!", message: "Check your inbox", viewController: self, onok: { _ in
          self.dismissViewControllerAnimated(true, completion: nil)
        })
      
        // Password reset sent successfully
      }
    })
  }
  
  
  func spin() {
    spinning = true
    spinner.hidden = false
    spinner.startAnimating()
  }
  
  func stopSpin() {
    spinning = false
    spinner.hidden = true
    spinner.stopAnimating()
  }
  
  override func viewWillAppear(animated: Bool) {
    emailField.text = ""
    self.stopSpin()
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    gogo()
    return true
  }
}