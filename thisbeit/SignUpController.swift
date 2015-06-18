//
//  SignUpController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class SignUpController: UIViewController {
  var ref = Firebase(url:"https://androidkye.firebaseio.com")

  var emailHold: String = ""
  var pwHold: String = ""
  
  @IBOutlet weak var email: UITextField!
  @IBOutlet weak var password: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
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
              println("Handle invalid user")
            case .InvalidEmail:
              self.spinner.hidden = true
              println("Handle invalid email")
            case .InvalidPassword:
              self.spinner.hidden = true
              println("Handle invalid password")
            default:
              self.spinner.hidden = true
              println("Handle default situation")
            }
          }
        } else {
          let uid = result["uid"] as? String
          println("Successfully created user account with uid: \(uid)")
        }
    })
  }
  
  override func viewDidLoad() {
    println("viewDidLoad")
    super.viewDidLoad()
    email.text = emailHold
    password.text = pwHold
    
    // Do any additional setup after loading the view, typically from a nib.
  }
}