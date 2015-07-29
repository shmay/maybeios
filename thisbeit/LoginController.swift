//
//  LoginController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class LoginController: UIViewController, UITextFieldDelegate {
  var ref = Firebase(url:fbaseURL)
  
  @IBOutlet weak var email: UITextField!
  @IBOutlet weak var password: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var invalidPw: UILabel!
  @IBOutlet weak var invalidEmail: UILabel!
  @IBOutlet weak var invalidUser: UILabel!
  
  @IBAction func toggle() {
    performSegueWithIdentifier("SignUp", sender:self)
  }
  
  @IBAction func signin() {
    if !spinner.hidden {
      return
    }
    
    spinner.hidden = false
    spinner.startAnimating()
    
    ref.authUser("kmurph73@gmail.com", password:"pass1212") {
      error, authData in
      if error != nil {
        // an error occured while attempting login
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
            println("Handle default situation")
          }
        }
      } else {
        let uid: String = authData.uid!
        currentUser = User(name: "", id: uid, isThere: .No)
        NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
        NSUserDefaults.standardUserDefaults().setValue(authData.token, forKey: "token")
        NSUserDefaults.standardUserDefaults().setValue(authData.provider, forKey: "provider")
        NSUserDefaults.standardUserDefaults().setValue(authData.providerData["email"], forKey: "provider")
        
        if let name = NSUserDefaults.standardUserDefaults().valueForKey("name") as? String {
          if count(name) > 0 {
            println("defaults has name: \(name)")
            self.performSegueWithIdentifier("gogo", sender:self)
          } else {
            self.checkForUsername(uid)
          }
        } else {
          self.checkForUsername(uid)
        }

        // user is logged in, check authData for data
      }
    }
  }
  
  func checkForUsername(uid: String) {
    println("checkForUsername: \(uid)")
    self.ref.childByAppendingPath("users/\(uid)/name").observeEventType(.Value, withBlock: { snapshot in
      if let name = snapshot.value as? String {
        println("fbname found: \(name)")
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
        self.performSegueWithIdentifier("gogo", sender:self)
      } else {
        self.performSegueWithIdentifier("username", sender:self)
      }
    })
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    if let touch = touches.first as? UITouch {
      self.view.endEditing(true)
    }
    super.touchesBegan(touches , withEvent:event)
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
    if let sourceViewController = sender.sourceViewController as? SignUpController {
      email.text = sourceViewController.email!.text
      password.text = sourceViewController.password!.text
    } else if let sourceViewController = sender.sourceViewController as? LocationsViewController {
      email.text = ""
      password.text = ""
      spinner.stopAnimating()
      spinner.hidden = true
    }
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    let oldText: NSString = textField.text
    let newText: NSString = oldText.stringByReplacingCharactersInRange(range, withString: string)
    invalidEmail.hidden = true
    invalidPw.hidden = true
    invalidUser.hidden = true
    return true
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    println("viewdidappear")
    
    let uid = NSUserDefaults.standardUserDefaults().stringForKey("uid")

    if uid != nil {
      performSegueWithIdentifier("gogo", sender:self)
    }

  }
  
  override func viewWillAppear(animated: Bool) {
    println("viewWillAppear")
  }
  
  override func viewDidLoad() {
    (UIApplication.sharedApplication().delegate as! AppDelegate).justLoggedOut = false

    println("viewDidLoad")
    super.viewDidLoad()
    
    spinner.hidden = true
    
    // Do any additional setup after loading the view, typically from a nib.
  }

}
