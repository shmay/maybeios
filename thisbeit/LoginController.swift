//
//  LoginController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
  var ref = Firebase(url:"https://androidkye.firebaseio.com")
  
  @IBOutlet weak var email: UITextField!
  @IBOutlet weak var password: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  @IBAction func toggle() {
    performSegueWithIdentifier("SignUp", sender:self)
  }
  
  @IBAction func signin() {
    spinner.hidden = false
    spinner.startAnimating()
    
//    var users = ["simplelogin:1": false]
//    
//    ref.childByAppendingPath("spots/2").updateChildValues(users)

    ref.authUser("kmurph73@gmail.com", password:"pass1212") {
      error, authData in
      if error != nil {
        // an error occured while attempting login
        if let errorCode = FAuthenticationError(rawValue: error.code) {
          switch (errorCode) {
          case .UserDoesNotExist:
            println("Handle invalid user")
          case .InvalidEmail:
            println("Handle invalid email")
          case .InvalidPassword:
            println("Handle invalid password")
          default:
            println("Handle default situation")
          }
        }
      } else {
        NSUserDefaults.standardUserDefaults().setValue(authData.uid!, forKey: "uid")
//        NSUserDefaults.standardUserDefaults().setValue(authData.token!, forKey: "token")

        self.performSegueWithIdentifier("gogo", sender:self)
        println("token \(authData.token)")

        // user is logged in, check authData for data
      }
    }

  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "SignUp" {
      let controller = segue.destinationViewController as! SignUpController
      controller.emailHold = email.text
      controller.pwHold = password.text
    }
  }
  
  @IBAction func unwindToMainMenu(sender: UIStoryboardSegue)
  {
    let sourceViewController = sender.sourceViewController as! SignUpController
    email.text = sourceViewController.email!.text
    password.text = sourceViewController.password!.text
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    let uid = NSUserDefaults.standardUserDefaults().stringForKey("uid")

    if uid != nil {
      performSegueWithIdentifier("gogo", sender:self)
    }

  }
  
  override func viewDidLoad() {
    println("viewDidLoad")
    super.viewDidLoad()
    
    spinner.hidden = true
    
    // Do any additional setup after loading the view, typically from a nib.
  }

}
