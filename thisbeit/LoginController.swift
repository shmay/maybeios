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
    if (!validate()) {
      return
    }
    
    self.spin()
    
    ref.authUser(email.text, password:password.text) {
      error, authData in
      if error != nil {
        self.stopSpin()
        // an error occured while attempting login
        if let errorCode = FAuthenticationError(rawValue: error.code) {
          switch (errorCode) {
          case .UserDoesNotExist:
            self.invalidUser.hidden = false
          case .InvalidEmail:
            self.invalidEmail.hidden = false
          case .InvalidPassword:
            self.invalidPw.text = "Invalid Password"
            self.invalidPw.hidden = false
          default:
            print("Handle default situation")
          }
        }
      } else {
        self.handleAuthData(authData)
        // user is logged in, check authData for data
      }
    }
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    if textField == password {
      textField.resignFirstResponder()
      signin()
    } else if textField == email {
      password.becomeFirstResponder()
    }
    
    return true
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let _ = touches.first {
      self.view.endEditing(true)
    }
    super.touchesBegan(touches , withEvent:event)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "SignUp" {
      let controller = segue.destinationViewController as! SignUpController
      controller.emailHold = email.text!
      controller.pwHold = password.text!
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
    } else if let _ = sender.sourceViewController as? LocationsViewController {
      email.text = ""
      password.text = ""
      spinner.stopAnimating()
      spinner.hidden = true
    }
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
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
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    print("viewdidappear")
    spin()
    
    if let token = NSUserDefaults.standardUserDefaults().stringForKey("token") {
      authUser(token)
    } else {
      stopSpin()
    }

  }
  
  func handleAuthData(authData: FAuthData) {
    let uid: String = authData.uid!
    NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
    NSUserDefaults.standardUserDefaults().setValue(authData.token, forKey: "token")
    //    NSUserDefaults.standardUserDefaults().setValue(authData.provider, forKey: "provider")
    //    NSUserDefaults.standardUserDefaults().setValue(authData.providerData["email"], forKey: "email")
    
    createUser(uid)
    currentUser!.provider = authData.provider
    currentUser!.token = authData.token
    if let e = authData.providerData["email"] as? String {
      print("set email")
      NSUserDefaults.standardUserDefaults().setValue(e, forKey: "email")
      currentUser!.email = e
    } else if let e = NSUserDefaults.standardUserDefaults().valueForKey("email") as? String {
      currentUser!.email = e
    }
  }
  
  func createUser(uid: String) {
    currentUser = User(name: "", id: uid, state: .Unknown)
    if let name = NSUserDefaults.standardUserDefaults().valueForKey("name") as? String {
      print("name: \(name)")
      if name.characters.count > 0 {
        currentUser!.name = name
        print("defaults has name: \(name)")
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
        print("fbname found: \(name)")
        currentUser!.name = name
        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
        self.performSegueWithIdentifier("gogo", sender:self)
      } else {
        self.performSegueWithIdentifier("username", sender:self)
      }
    })
  }
  
  func validate() -> Bool {
    if password.text!.characters.count < 6 {
      invalidPw.text = "Password must be at least 6 characters"
      invalidPw.hidden = false
      return false
    }
    
    return true
  }
  
  @IBAction func tapForgotPw(sender: AnyObject) {
    self.performSegueWithIdentifier("forgot", sender: self)
  }
  
  func authUser(token:String) {
    ref.authWithCustomToken(token, withCompletionBlock: {error, authData in
      self.stopSpin()
      
      if let err = error {
        print("authError: \(err)")
        if err.code == 9999 {
          NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "token")
        }
      } else {
        self.handleAuthData(authData)
      }
    })
  }
//  
  override func viewWillAppear(animated: Bool) {
    print("viewWillAppear signin")

    self.stopSpin()

    if appDelegate.justLoggedOut {
      delay(0.2) {
        self.resetForm()
        self.signupCtrl?.resetForm()
      }
      
      appDelegate.justLoggedOut = false
    }
    print("viewWillAppear")
  }
  
  override func viewDidLoad() {
    (UIApplication.sharedApplication().delegate as! AppDelegate).justLoggedOut = false

    print("viewDidLoad")
    super.viewDidLoad()
    
    spinner.hidden = true
    
    // Do any additional setup after loading the view, typically from a nib.
  }

}
