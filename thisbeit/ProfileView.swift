//
//  ProfileView.swift
//  thisbeit
//
//  Created by Kyle Murphy on 7/23/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class ProfileView: UIViewController, UITextFieldDelegate {
  var working = false
  
  @IBOutlet weak var textField: UITextField!
  @IBAction func tapButton(sender: AnyObject) {
    if !working {
      working = true
      let name = textField.text!
      currentUser!.name = name
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        postRequest("update_name", params: ["token": token, "newname": name], success: {json in
          NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
          self.working = false
          self.dismiss()
        }, errorCb: { _ in
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
    
    textField.delegate = self
  }

  @IBAction func changePw(sender: AnyObject) {
    self.performSegueWithIdentifier("changepw", sender: self)
  }

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    textField.resignFirstResponder()
  }

  func textFieldShouldReturn(userText: UITextField) -> Bool {
    userText.resignFirstResponder()
    
    return true;
  }
}