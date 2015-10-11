//
//  ChangePwViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 9/8/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class ChangePwViewController: UIViewController, UITextFieldDelegate {
  var ref = Firebase(url:fbaseURL)
  var spinning = false
  
  @IBAction func tapCancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBOutlet weak var oldPw: UITextField!
  @IBOutlet weak var newPw: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  @IBOutlet weak var switcher: UISwitch!
  func spin() {
    spinning = true
    spinner.hidden = false
    spinner.startAnimating()
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    oldPw.resignFirstResponder()
    newPw.resignFirstResponder()
  }
  
  func stopSpin() {
    spinning = false
    spinner.hidden = true
    spinner.stopAnimating()
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    print("textf should ret")
    if textField == newPw {
      print("new pw")
      changePw()
    } else if textField == oldPw {
      newPw.becomeFirstResponder()
    }
    textField.resignFirstResponder()
    return true
  }
  
  @IBAction func tapSwitch(sender: AnyObject) {
    if switcher.on {
      oldPw.secureTextEntry = false
      newPw.secureTextEntry = false
    } else {
      oldPw.secureTextEntry = true
      newPw.secureTextEntry = true
    }
  }
  
  func changePw() {
    spin()
    if let e = currentUser!.email {
      ref.changePasswordForUser(e, fromOld: oldPw.text,
        toNew: newPw.text, withCompletionBlock: { error in
          if error != nil {
            print("error: \(error)")
            
            var msg = "An error occurred while trying to change your password"
            
            if let errorCode = FAuthenticationError(rawValue: error.code) {
              switch (errorCode) {
              case .UserDoesNotExist:
                msg = "User does exist"
              case .InvalidPassword:
                msg = "Invalid Password"
              default:
                print("Handle default situation")
              }
            }
            
            showSimpleAlertWithTitle("Error!", message: msg, viewController: self, onok: nil)
            self.stopSpin()
            // There was an error processing the request
          } else {
            self.stopSpin()
            showSimpleAlertWithTitle("Success!", message: "Successfully changed your password", viewController: self, onok: {_ in
              self.dismissViewControllerAnimated(true, completion: nil)
            })
            // Password changed successfully
          }
      })
    }
  }
  
  @IBAction func tapChange(sender: AnyObject) {
    changePw()
  }
  
  override func viewWillAppear(animated: Bool) {
    print("viewWillAppear signin")
    
    stopSpin()
    oldPw.text = ""
    newPw.text = ""
    print("viewWillAppear")
  }
}