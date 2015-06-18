//
//  AppDelegate.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
  
  let ref = Firebase(url: "https://androidkye.firebaseio.com")
  
  let locationManager = CLLocationManager() // Add this statement

  var window: UIWindow?

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    locationManager.delegate = self                // Add this line
    locationManager.requestAlwaysAuthorization()   // And this one
    // Override point for customization after application launch.
    
//    ref.observeAuthEventWithBlock({ authData in
//      if authData != nil {
//        // user authenticated with Firebase
//        
//        println("appdel: \(authData)")
//        
//        let newUser = [
//          "provider": authData.provider,
//          "email": authData.providerData["email"] as? NSString as? String,
//          "provider_id": (split(authData.uid) { $0 == ":"})[1]
//        ]
//        
//        self.ref.childByAppendingPath("users").childByAppendingPath(authData.uid).setValue(newUser)
//      } else {
//        // No user is logged in
//      }
//    })
    
    return true
    

  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

