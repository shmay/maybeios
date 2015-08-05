//
//  SignUpController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class SignUpController: UIViewController, UITextFieldDelegate {
  var ref = Firebase(url:fbaseURL)

  var emailHold: String = ""
  var pwHold: String = ""
  
  @IBOutlet weak var email: UITextField!
  @IBOutlet weak var password: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var invalidPw: UILabel!
  @IBOutlet weak var invalidEmail: UILabel!
  @IBOutlet weak var invalidUser: UILabel!
  
  @IBAction func signup() {
    spinner.hidden = false
    spinner.startAnimating()
    
    ref.createUser(email.text, password: password.text,
      withValueCompletionBlock: { error, result in
        if error != nil {
          // There was an error creating the account
          if let errorCode = FAuthenticationError(rawValue: error.code) {
            switch (errorCode) {
            case .UserDoesNotExist:
              self.spinner.hidden = true
              self.invalidUser.hidden = false
            case .InvalidEmail:
              self.spinner.hidden = true
              self.invalidEmail.hidden = false
            case .InvalidPassword:
              self.spinner.hidden = true
              self.invalidPw.hidden = false
            default:
              self.spinner.hidden = true
              println("Handle default situation")
            }
          }
        } else {
          let uid = result["uid"] as! String
          currentUser = User(name: "", id: uid, state: .Unknown)
          println("Successfully created user account with uid: \(uid)")
        }
    })
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    if let touch = touches.first as? UITouch {
      self.view.endEditing(true)
    }
    super.touchesBegan(touches , withEvent:event)
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    let oldText: NSString = textField.text
    let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: string)
    invalidEmail.hidden = true
    invalidPw.hidden = true
    invalidUser.hidden = true
    return true
  }
  
  override func viewDidLoad() {
    println("viewDidLoad")
    super.viewDidLoad()
    email.text = emailHold
    password.text = pwHold
    
    // Do any additional setup after loading the view, typically from a nib.
  }
}