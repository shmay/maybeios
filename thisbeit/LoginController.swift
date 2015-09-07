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
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var signupCtrl: SignUpController?

  var spinning = true
  
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
    
    self.spin()
    
    ref.authUser(email.text, password:password.text) {
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
        self.handleAuthData(authData)

        // user is logged in, check authData for data
      }
    }
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
  
  func resetForm() {
    stopSpin()
    self.email.text = ""
    self.password.text = ""
    
    self.invalidPw.hidden = true
    self.invalidEmail.hidden = true
    self.invalidUser.hidden = true
    
    appDelegate.justLoggedOut = false
  }
  
  @IBAction func unwindToMainMenu(sender: UIStoryboardSegue)
  {
    if let sourceViewController = sender.sourceViewController as? SignUpController {
      self.signupCtrl = sourceViewController
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
  
//  override func viewDidAppear(animated: Bool) {
//    super.viewDidAppear(animated)
//    
//    println("viewdidappear")
//    
//    let uid = NSUserDefaults.standardUserDefaults().stringForKey("uid")
//    
//    if let token = NSUserDefaults.standardUserDefaults().stringForKey("token") {
//      authUser(token)
//    } else {
//      stopSpin()
//    }
//
//  }
  
  func handleAuthData(authData: FAuthData) {
    let uid: String = authData.uid!
    NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
    NSUserDefaults.standardUserDefaults().setValue(authData.token, forKey: "token")
    //    NSUserDefaults.standardUserDefaults().setValue(authData.provider, forKey: "provider")
    //    NSUserDefaults.standardUserDefaults().setValue(authData.providerData["email"], forKey: "email")
    
    createUser(uid)
    currentUser!.provider = authData.provider
    currentUser!.token = authData.token
  }
  
  func createUser(uid: String) {
    currentUser = User(name: "", id: uid, state: .Unknown)
    if let name = NSUserDefaults.standardUserDefaults().valueForKey("name") as? String {
      println("name: \(name)")
      if count(name) > 0 {
        currentUser!.name = name
        println("defaults has name: \(name)")
        self.performSegueWithIdentifier("gogo", sender:self)
      } else {
        self.checkForUsername(uid)
      }
    } else {
      self.checkForUsername(uid)
    }
  }
  
  func checkForUsername(uid: String) {
    self.ref.childByAppendingPath("users/\(uid)/name").observeSingleEventOfType(.Value, withBlock: { snapshot in
      if let name = snapshot.value as? String {
        println("fbname found: \(name)")
        currentUser!.name = name
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
        self.performSegueWithIdentifier("gogo", sender:self)
      } else {
        self.performSegueWithIdentifier("username", sender:self)
      }
    })
  }
  
  func authUser(token:String) {
    ref.authWithCustomToken(token, withCompletionBlock: {error, authData in
      self.stopSpin()
      
      if let err = error {
        println("authError: \(err)")
        if err.code == 9999 {
          NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "token")
        }
      } else {
        self.handleAuthData(authData)
      }
    })
  }
//  
//  override func viewWillAppear(animated: Bool) {
//    println("viewWillAppear signin")
//
//    self.stopSpin()
//
//    if appDelegate.justLoggedOut {
////      delay(0.2) {
////        self.resetForm()
////        self.signupCtrl?.resetForm()
////      }
//      
//      appDelegate.justLoggedOut = false
//    }
//    println("viewWillAppear")
//  }
//  
//  override func viewDidLoad() {
//    (UIApplication.sharedApplication().delegate as! AppDelegate).justLoggedOut = false
//
//    println("viewDidLoad")
//    super.viewDidLoad()
//    
//    spinner.hidden = true
//    
//    // Do any additional setup after loading the view, typically from a nib.
//  }

}
