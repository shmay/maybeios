//
//  OAuthController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 7/17/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class OAuthController: UIViewController, GPPSignInDelegate {
  let ref = Firebase(url: "https://androidkye.firebaseio.com")

  @IBOutlet weak var spinner: UIActivityIndicatorView!
  override func viewDidLoad() {
    super.viewDidLoad()
    let signIn = GPPSignIn.sharedInstance()
    signIn.shouldFetchGooglePlusUser = true
    signIn.clientID = "32887541704-4eoj50cbpgvg7rgkhvh5084usp5pq1ur.apps.googleusercontent.com"
    signIn.scopes = []
    signIn.delegate = self
//    
//    let button = GPPSignInButton()
//    button.center = self.view.center
//    self.view.addSubview(button)
    
//    let loginButton = FBSDKLoginButton()
//    loginButton.center = self.view.center
//    self.view.addSubview(loginButton)
  }
  func spin() {
    spinner.hidden = false
    spinner.startAnimating()
  }
  
  func stopSpin() {
    spinner.hidden = true
    spinner.stopAnimating()
  }
  
  @IBAction func authWithFacebook(sender: AnyObject) {
    if !spinner.hidden {
      return
    }
    
    spin()
    let facebookLogin = FBSDKLoginManager()
    
    facebookLogin.logInWithReadPermissions(["email"], handler: {
      (facebookResult, facebookError) -> Void in
      
      if facebookError != nil {
        println("Facebook login failed. Error \(facebookError)")
        self.stopSpin()
        
        if facebookError.code == -1 {
          let msg = "Please go to your iOS Settings -> Facebook and fill in your login information so you can authenticate via Twitter.  Also make sure MaybeSo is allowed to use your Facebook account if that option exists"
          let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
          let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
          alertController.addAction(okAction)
          self.presentViewController(alertController, animated: true, completion: nil)
        }
      } else if facebookResult.isCancelled {
        self.stopSpin()
        println("Facebook login was cancelled.")
      } else {
        let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
        
        self.ref.authWithOAuthProvider("facebook", token: accessToken,
          withCompletionBlock: { error, authData in
            
            if error != nil {
              println("Login failed. \(error)")
            } else {
              println("Logged in! \(authData)")
              self.handleAuthData(authData)
            }
            
            self.stopSpin()
        })
      }
    })
  }
  
  @IBAction func authWithPW(sender: AnyObject) {
    performSegueWithIdentifier("showSignin", sender: self)
  }
  
  @IBAction func authWitGoog(sender: AnyObject) {
    spin()
//    authenticateWithGoogle()
  }
  
  func authenticateWithGoogle() {
    println("autwitgoog")
    // use the Google+ SDK to get an OAuth token
//    let signIn = GPPSignIn.sharedInstance()
//    signIn.authenticate()
  }
  
  func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
    println("guath: \(auth)")
    println("gerror: \(error)")
    
    self.stopSpin()
    
    if error != nil {
      // There was an error obtaining the Google+ OAuth Token
    } else {
      // We successfully obtained an OAuth token, authenticate on Firebase with it
      let ref = Firebase(url: "https://androidkye.firebaseio.com")
      ref.authWithOAuthProvider("google", token: auth.accessToken,
        withCompletionBlock: { error, authData in
          if error != nil {
            println("errderr: \(error)")
            // Error authenticating with Firebase with OAuth token
          } else {
            // User is now logged in!
            println("Successfully logged in! \(authData)")
            self.handleAuthData(authData)
          }
      })
    }
  }
  
  @IBAction func unwindToMainMenu(sender: UIStoryboardSegue) {}
  
  @IBAction func authWithTwitter(sender: AnyObject) {
    if !spinner.hidden {
      return
    }
    spin()
    let twitterAuthHelper = TwitterAuthHelper(firebaseRef: ref, apiKey:"EPOngDM26zvGi5sHuDpYXsAiM")
    twitterAuthHelper.selectTwitterAccountWithCallback { error, accounts in
      println("a f resp")
      println("error: \(error)")
      println("accounts: \(accounts)")
      
      if error != nil {
        println("err")
        
        println("code:\(error.code)")
        println("domain:\(error.domain)")
        println("desc:\(error.description)")
        self.stopSpin()

        if error.code == -1 {
          let msg = "Please go to your iOS Settings -> Twitter and fill in your login information so you can authenticate via Twitter.  Also make sure MaybeSo is allowed to use your Twitter account if that option exists"
          let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
          let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
          alertController.addAction(okAction)
          self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        // Error retrieving Twitter accounts
      } else if accounts.count > 1 {
        // Select an account. Here we pick the first one for simplicity
        let account = accounts[0] as? ACAccount
        twitterAuthHelper.authenticateAccount(account, withCallback: { error, authData in
          println("authDate: \(authData)")
          self.stopSpin()

          if error == nil {
            println("error:")
            // Error authenticating account
          } else {
            println("authData: \(authData)")
            // User logged in!
          }
        })
      } else {
        println("acts: \(accounts)")
        let account = accounts[0] as? ACAccount
        println("desc: \(account?.accountDescription)")
        println("cred: \(account?.credential)")
        println("id: \(account?.identifier)")
        println("type: \(account?.accountType)")
        twitterAuthHelper.authenticateAccount(account, withCallback: { error, authData in
          println("authDater: \(authData)")
          self.stopSpin()
          if error != nil {
            println("error:")
            // Error authenticating account
          } else {
            self.handleAuthData(authData)
            println("uid: \(authData.uid)")
            // User logged in!
          }
        })
      }
    }
  }
  
  func handleAuthData(authData: FAuthData) {
    let uid: String = authData.uid!
    NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
    NSUserDefaults.standardUserDefaults().setValue(authData.token, forKey: "token")
    NSUserDefaults.standardUserDefaults().setValue(authData.provider, forKey: "provider")
    NSUserDefaults.standardUserDefaults().setValue(authData.providerData["email"], forKey: "provider")
    
    createUser(uid)
    currentUser!.token = authData.token
  }
  
  func createUser(uid:String) {
    currentUser = User(name: "", id: uid, isThere: .No)
    if let name = NSUserDefaults.standardUserDefaults().valueForKey("name") as? String {
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
    self.ref.childByAppendingPath("users/\(uid)/name").observeEventType(.Value, withBlock: { snapshot in
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
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    println("viewdidappear")
    
    if let uid = NSUserDefaults.standardUserDefaults().stringForKey("uid") {
      createUser(uid)
    }
  
  }
  
}
