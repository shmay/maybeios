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
  var justLoggedOut = false
  
  let ref = Firebase(url: "https://androidkye.firebaseio.com")
  var pin: String?
  
  var holdViewController: UIViewController?
  var alert: UIAlertController?
  let locationManager = CLLocationManager()

  var window: UIWindow?
  
  func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    println("options: \(launchOptions)")
    
    NSUserDefaults.standardUserDefaults().removeObjectForKey("name")
    
    return FBSDKApplicationDelegate.sharedInstance()
      .application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    println("options: \(launchOptions)")
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    
    let url = NSURL(string: "http://localhost:3000/heyo")
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
      println(NSString(data: data, encoding: NSUTF8StringEncoding))
    }
    
    task.resume()
    return true
  }
  
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
    let matches = regexMatches("pin\\=([\\w\\d]+)", url.absoluteString!)
    
    if count(matches) > 0 {
      let pin = matches[0]
      
      let url = NSURL(string: "\(serverURL)/join_w_pin")
      
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        if let uid = NSUserDefaults.standardUserDefaults().valueForKey("uid") as? String {
          let dict = ["uid" : uid, "token": token, "pin":pin]
          postRequest("join_w_pin", dict, {json in self.handleResp(json)}, {self.handleErr()})
        }
      }
    }
    
    FBSDKApplicationDelegate.sharedInstance()
      .application(application, openURL: url,
        sourceApplication: sourceApplication, annotation: annotation)
    
    GPPURLHandler.handleURL(url,
      sourceApplication:sourceApplication,
      annotation:annotation)
    
    return true
  }
  
  func dismissJoin(controller: JoinController) {
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func handleResp(json: NSDictionary?) {
    if let parseJSON = json {
      println("json: \(json)")
      var success = parseJSON["success"] as? Int
      if success == 1 {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let pin = parseJSON["pin"] as? String, lat = parseJSON["lat"] as? Double, lng = parseJSON["lng"] as? Double, radius = parseJSON["radius"] as? Double {
          let vc = storyboard.instantiateViewControllerWithIdentifier("JoinController") as! JoinController
          vc.radius = radius
          vc.latitude = lat
          vc.pin = pin
          vc.longitude = lng
          println("WHAAAAt")

          if let rootViewController = self.window!.rootViewController {
            if let presentedViewController = rootViewController.presentedViewController {
              self.holdViewController = presentedViewController
              dispatch_async(dispatch_get_main_queue(), {
                presentedViewController.presentViewController(vc, animated: true, completion: nil)
              })
            }
          }
        }
        // transition
      } else if success == -1 {
        showAlert("Sorry, but that pin is invalid.  Please contact the spot adminstrator and ask for a new invite.")
      } else {
        showAlert("Sorry, an error occurred while trying add you to the spot.")
      }
    }
  }
  
  func handleErr() {}

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
    
    FBSDKAppEvents.activateApp()
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

