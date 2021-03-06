////
////  OAuthController.swift
////  thisbeit
////
////  Created by Kyle Murphy on 7/17/15.
////  Copyright (c) 2015 Kyle Murphy. All rights reserved.
////
//
//import Foundation
//import UIKit
//import CoreLocation
//import FBSDKCoreKit
//import FBSDKLoginKit
//
//class OAuthController: UIViewController, GPPSignInDelegate {
//  @IBOutlet weak var goog: GPPSignInButton!
//  
//  var spinning = true
//  var inReview = false
//  let ref = Firebase(url: fbaseURL)
//  
//  @IBOutlet weak var reviewButton: UIButton!
//  
//  @IBAction func tapReview(sender: AnyObject) {
//    print("inReview: \(inReview)")
//    if inReview {
//      spin()
//      ref.authUser("s@g.com", password: "11",
//        withCompletionBlock: { error, authData in
//          if error != nil {
//            showSimpleAlertWithTitle("error", message: "err when authenticating demo acct", viewController: self, onok:nil)
//            // There was an error logging in to this account
//          } else {
//            self.handleAuthData(authData)
//            
//            // We are now logged in
//          }
//          
//          self.stopSpin()
//      })
//    }
//  }
//  
//  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//
//  @IBOutlet weak var spinner: UIActivityIndicatorView!
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    ref.childByAppendingPath("stuff").observeSingleEventOfType(.Value, withBlock: { snapshot in
//      
//      if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? NSString {
//        print("build: \(build)")
//        if let review = snapshot.value["inreview"] as? Double {
//          if review == build.doubleValue {
//            self.reviewButton.hidden = false
//            self.inReview = true
//          }
//        }
//      }
//
//    })
//    
//    spin()
//
//    let signIn = GPPSignIn.sharedInstance()
//    signIn.shouldFetchGooglePlusUser = true
//    signIn.clientID = "32887541704-4eoj50cbpgvg7rgkhvh5084usp5pq1ur.apps.googleusercontent.com"
//    signIn.scopes = []
//    signIn.delegate = self
//
//  }
//  
//  func spin() {
//    spinning = true
//    spinner.hidden = false
//    spinner.startAnimating()
//  }
//  
//  func stopSpin() {
//    spinning = false
//    spinner.hidden = true
//    spinner.stopAnimating()
//  }
//  
//  @IBAction func authWithFacebook(sender: AnyObject) {
//    print("authWithFB")
//    
//    resetData()
//
//    spin()
//    let facebookLogin = FBSDKLoginManager()
//
//    facebookLogin.logInWithReadPermissions(["email"], handler: {
//      (facebookResult, facebookError) -> Void in
//      
//      if facebookError != nil {
//        print("Facebook login failed. Error \(facebookError)")
//        self.stopSpin()
//        
//        if facebookError.code == -1 {
//          let msg = "Please go to your iOS Settings -> Facebook and fill in your login information so you can authenticate with Twitter.  Also make sure MaybeSo is allowed to use your Facebook account if that option exists"
//          let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
//          let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
//          alertController.addAction(okAction)
//          self.presentViewController(alertController, animated: true, completion: nil)
//        }
//      } else if facebookResult.isCancelled {
//        self.stopSpin()
//        print("Facebook login was cancelled.")
//      } else {
//        let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
//        print("accessToken: \(accessToken)")
//        
//        self.ref.authWithOAuthProvider("facebook", token: accessToken,
//          withCompletionBlock: { error, authData in
//            if error != nil {
//              print("Login failed. \(error)")
//            } else {
//              print("Logged in! \(authData)")
//              self.handleAuthData(authData)
//            }
//            
//            self.stopSpin()
//        })
//      }
//    })
//  }
//  
//  @IBAction func authWithPW(sender: AnyObject) {
////    performSegueWithIdentifier("showSignin", sender: self)
//  }
//  
//  @IBAction func authWitGoog(sender: AnyObject) {
//    resetData()
//    spin()
//  }
//  
//  func authenticateWithGoogle() {
//    print("autwitgoog")
//    // use the Google+ SDK to get an OAuth token
////    let signIn = GPPSignIn.sharedInstance()
////    signIn.authenticate()
//  }
//  
//  func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
//    print("guath: \(auth)")
//    print("gerror: \(error)")
//    
//    self.stopSpin()
//    
//    if error != nil {
//      // There was an error obtaining the Google+ OAuth Token
//    } else {
//      // We successfully obtained an OAuth token, authenticate on Firebase with it
//      let ref = Firebase(url: fbaseURL)
//      ref.authWithOAuthProvider("google", token: auth.accessToken,
//        withCompletionBlock: { error, authData in
//          if error != nil {
//            print("errderr: \(error)")
//            // Error authenticating with Firebase with OAuth token
//          } else {
//            // User is now logged in!
//            print("Successfully logged in! \(authData)")
//            self.handleAuthData(authData)
//          }
//      })
//    }
//  }
//  
//  @IBAction func unwindToMainMenu(sender: UIStoryboardSegue) {}
//  
//  @IBAction func authWithTwitter(sender: AnyObject) {
//    resetData()
//    spin()
//    let twitterAuthHelper = TwitterAuthHelper(firebaseRef: ref, apiKey:twitterAPIKey)
//    twitterAuthHelper.selectTwitterAccountWithCallback { error, accounts in
//      print("a f resp")
//      print("error: \(error)")
//      print("accounts: \(accounts)")
//      
//      if error != nil {
//        print("err")
//        
//        print("code:\(error.code)")
//        print("domain:\(error.domain)")
//        print("desc:\(error.description)")
//        self.stopSpin()
//
//        if error.code == -1 {
//          let msg = "Please go to your iOS Settings -> Twitter and fill in your login information so you can authenticate via Twitter.  Also make sure MaybeSo is allowed to use your Twitter account if that option exists"
//          let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
//          let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
//          alertController.addAction(okAction)
//          self.presentViewController(alertController, animated: true, completion: nil)
//        }
//        
//        // Error retrieving Twitter accounts
//      } else if accounts.count > 1 {
//        // Select an account. Here we pick the first one for simplicity
//        let account = accounts[0] as? ACAccount
//        twitterAuthHelper.authenticateAccount(account, withCallback: { error, authData in
//          print("authDate: \(authData)")
//          self.stopSpin()
//
//          if error == nil {
//            print("error:")
//            // Error authenticating account
//          } else {
//            print("authData: \(authData)")
//            // User logged in!
//          }
//        })
//      } else {
//        print("acts: \(accounts)")
//        let account = accounts[0] as? ACAccount
//        print("desc: \(account?.accountDescription)")
//        print("cred: \(account?.credential)")
//        print("id: \(account?.identifier)")
//        print("type: \(account?.accountType)")
//        twitterAuthHelper.authenticateAccount(account, withCallback: { error, authData in
//          print("authDater: \(authData)")
//          self.stopSpin()
//          if error != nil {
//            print("error: \(error)")
//            // Error authenticating account
//          } else {
//            self.handleAuthData(authData)
//            print("uid: \(authData.uid)")
//            // User logged in!
//          }
//        })
//      }
//    }
//  }
//  
//  func handleAuthData(authData: FAuthData) {
//    let uid: String = authData.uid!
//    NSUserDefaults.standardUserDefaults().setValue(uid, forKey: "uid")
//    NSUserDefaults.standardUserDefaults().setValue(authData.token, forKey: "token")
////    NSUserDefaults.standardUserDefaults().setValue(authData.provider, forKey: "provider")
////    NSUserDefaults.standardUserDefaults().setValue(authData.providerData["email"], forKey: "email")
//    
//    createUser(uid)
//    currentUser!.provider = authData.provider
//    currentUser!.token = authData.token
//  }
//  
//  func resetData() {
//    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstSpotsLoad")
//    NSUserDefaults.standardUserDefaults().removeObjectForKey("name")
//    NSUserDefaults.standardUserDefaults().removeObjectForKey("token")
//  }
//  
//  func createUser(uid: String) {
//    print("createUser")
//    currentUser = User(name: "", id: uid, state: .Unknown)
//    if let name = NSUserDefaults.standardUserDefaults().valueForKey("name") as? String {
//      print("name: \(name)")
//      if name.characters.count > 0 {
//        currentUser!.name = name
//        print("defaults has name: \(name)")
//        self.performSegueWithIdentifier("gogo", sender:self)
//      } else {
//        self.checkForUsername(uid)
//      }
//    } else {
//      self.checkForUsername(uid)
//    }
//  }
//  
//  func checkForUsername(uid: String) {
//    self.ref.childByAppendingPath("users/\(uid)/name").observeEventType(.Value, withBlock: { snapshot in
//      if let name = snapshot.value as? String {
//        print("fbname found: \(name)")
//        currentUser!.name = name
//        NSUserDefaults.standardUserDefaults().setValue(name, forKey: "name")
//        self.performSegueWithIdentifier("gogo", sender:self)
//      } else {
//        self.performSegueWithIdentifier("username", sender:self)
//      }
//    })
//  }
//  
//  func authUser(token:String) {
//    ref.authWithCustomToken(token, withCompletionBlock: {error, authData in
//      self.stopSpin()
//      
//      if let err = error {
//        print("authError: \(err)")
//        if err.code == 9999 {
//          NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "token")
//        }
//      } else {
//        self.handleAuthData(authData)
//      }
//    })
//  }
//  
//  override func didReceiveMemoryWarning() {
//    super.didReceiveMemoryWarning()
//    // Dispose of any resources that can be recreated.
//  }
//  
//  override func viewDidAppear(animated: Bool) {
//    super.viewDidAppear(animated)
//    
//    if let token = NSUserDefaults.standardUserDefaults().stringForKey("token") {
//      authUser(token)
//    } else {
//      stopSpin()
//    }
//    
////    if let vers = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? NSString {
////      let v = vers.doubleValue
////      let minVer = 1.0
////      
////      if v < minVer {
////        let alertController = UIAlertController(title: nil, message: "Hey, you're behind.  Upgrade the app at the app store to continue using it.", preferredStyle: .Alert)
////        self.presentViewController(alertController, animated: true, completion: nil)
////        
////        let okAction = UIAlertAction(title: "Take me to the App Store", style: .Default,handler: { action in
////          var url  = NSURL(string: "itms-apps://itunes.apple.com/app/calorie-counter-diet-tracker/id341232718")
////          if UIApplication.sharedApplication().canOpenURL(url!) == true  {
////            UIApplication.sharedApplication().openURL(url!)
////          }
////          
////        })
////        alertController.addAction(okAction)
////      }
////      println("version:\(v)")
////    }
//    
////    dispatch_async(dispatch_get_main_queue(), {
////      self.stopSpin()
////    })
//    
//  }
//  
//}
//
