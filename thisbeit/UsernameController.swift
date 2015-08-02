//
//  UsernameController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/24/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class UsernameController: UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var errorMsg: UILabel!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  let ref = Firebase(url: "\(fbaseURL)/users")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textField.delegate = self
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    textField.resignFirstResponder()
  }
  
  func textFieldShouldReturn(userText: UITextField) -> Bool {
    userText.resignFirstResponder()
    submit()
    
    return true;
  }
  
  @IBAction func tapSubmit(sender: AnyObject) {
    submit()
  }
  
  func submit() {
    let name = textField.text
    
    if count(name) < 4 {
      errorMsg.text = "Username must be longer than 3 characters!"
      errorMsg.hidden = false
    } else if count(name) > 30 {
      errorMsg.text = "Username must be less than 30 characters!"
      errorMsg.hidden = false
    } else {
      spinner.startAnimating()
      
      if let uid = NSUserDefaults.standardUserDefaults().valueForKey("uid") as? String {
        ref.childByAppendingPath("\(uid)/name").setValue(name)
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
        performSegueWithIdentifier("usergo", sender: self)
      }
    }
  }
}