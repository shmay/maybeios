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
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var spinning = true

  var emailHold: String = ""
  var pwHold: String = ""
  
  @IBOutlet weak var email: UITextField!
  @IBOutlet weak var password: UITextField!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  @IBOutlet weak var invalidPw: UILabel!
  @IBOutlet weak var invalidEmail: UILabel!
  @IBOutlet weak var invalidUser: UILabel!
  
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
  
  func resetForm() {
    stopSpin()
    self.email.text = ""
    self.password.text = ""
    
    self.invalidPw.hidden = true
    self.invalidEmail.hidden = true
    self.invalidUser.hidden = true
    
    appDelegate.justLoggedOut = false
  }
  
  @IBAction func signup() {
    if (!validate()) {
      return
    }
    
    spinner.hidden = false
    spinner.startAnimating()
    
    ref.createUser(email.text, password: password.text,
      withValueCompletionBlock: { error, result in
        if error != nil {
          // There was an error creating the account
          if let errorCode = FAuthenticationError(rawValue: error.code) {
            self.stopSpin()
            switch (errorCode) {
            case .UserDoesNotExist:
              self.invalidUser.hidden = false
            case .InvalidEmail:
              self.invalidEmail.text = "Invalid Email"
              self.invalidEmail.hidden = false
            case .InvalidPassword:
              self.invalidPw.text = "Invalid Password"
              self.invalidPw.hidden = false
            case .EmailTaken:
              self.invalidEmail.text = "Email Taken"
              self.invalidEmail.hidden = false
              
            default:
              self.spinner.hidden = true
              println("Handle default situation")
            }
          }
        } else {
          self.ref.authUser(self.email.text, password:self.password.text) {
            error, authData in
            if error != nil {
              showSimpleAlertWithTitle("erorrr!", message: "something went rong!", viewController: self, onok: nil)
            } else {
              self.handleAuthData(authData)
            }
            
          }
  
        }
    })
  }
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {    
    if textField == password {
      textField.resignFirstResponder()
      signup()
    } else if textField == email {
      password.becomeFirstResponder()
    }
    return true
  }
  
  func validate() -> Bool {
    if count(password.text) < 6 {
      invalidPw.text = "Password must be at least 6 characters"
      invalidPw.hidden = false
      return false
    }
    
    return true
  }
  
  
  func authUser(token:String) {
    ref.authWithCustomToken(token, withCompletionBlock: {error, authData in
      self.stopSpin()
      
      if let err = error {
        if err.code == 9999 {
          NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "token")
        }
      } else {
        self.handleAuthData(authData)
      }
    })
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
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    if let touch = touches.first as? UITouch {
      self.view.endEditing(true)
    }
    super.touchesBegan(touches , withEvent:event)
  }
  
  override func viewWillAppear(animated: Bool) {
    println("viewWillAppear signup")

    self.stopSpin()
    if appDelegate.justLoggedOut {
      self.email.text = ""
      self.password.text = ""
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
  
  override func viewDidLoad() {
    println("viewDidLoad")
    super.viewDidLoad()
    email.text = emailHold
    password.text = pwHold
    
    // Do any additional setup after loading the view, typically from a nib.
  }
}