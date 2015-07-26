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
    
    var str:String? = UIPasteboard.generalPasteboard().string
    if let s = str {
      if count(s) == 10 {
        let matches = regexMatches("(^X\\w+)", s)
      
        if count(matches) > 0 {
          joinWithPin(matches[0])
        }
        
      }
    }
    
    return true
  }
  
  func joinWithPin(pin: String) {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      let dict = ["token": token, "pin":pin]
      postRequest("join_w_pin", dict, {json in self.handleResp(json)}, {self.handleErr()})
    }
  }
  
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
    let matches = regexMatches("pin\\=(^X[\\w]{9})", url.absoluteString!)
    
    if count(matches) > 0 {
      let pin = matches[0]
      
      joinWithPin(pin)
    }
    
    FBSDKApplicationDelegate.sharedInstance()
      .application(application, openURL: url,
        sourceApplication: sourceApplication, annotation: annotation)
    
    GPPURLHandler.handleURL(url,
      sourceApplication:sourceApplication,
      annotation:annotation)
    
    return true
  }
  
  func removeGeofence(spotid: String) {
    self.stopMonitoringForID(spotid)
  }
  
  func handleResp(json: NSDictionary?) {
    if let parseJSON = json {
      println("json: \(json)")
      var success = parseJSON["success"] as? Int
      if success == 1 {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let pin = parseJSON["pin"] as? String, lat = parseJSON["lat"] as? Double, lng = parseJSON["lng"] as? Double, radius = parseJSON["radius"] as? Double, name = parseJSON["name"] as? String, id = parseJSON["id"] as? String  {
          let vc = storyboard.instantiateViewControllerWithIdentifier("JoinController") as! JoinController
          let spot = Spot(name: name, id: id)
          spot.radius = radius
          let coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
          spot.coordinate = coords
          vc.pin = pin
          vc.spot = spot

          if let rootViewController = self.window!.rootViewController {
            if let presentedViewController = rootViewController.presentedViewController {
//              self.holdViewController = presentedViewController
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
  
  func startMonitoringGeotification(spot: Spot, ctrl: UIViewController) -> Bool {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: ctrl)
      return false
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: ctrl)
      return false
    }
    
    let reg = getRegionByID(spot.id)
    
    if reg == nil {
      if let region = regionWithSpot(spot) {
        locationManager.startMonitoringForRegion(region)
        return true
      } else {
        showSimpleAlertWithTitle("Error", message: "Geofence not created due to an error", viewController: ctrl)
      }
    }
    
    return false
  }
  
  func stopMonitoringSpots() {
    for region in locationManager.monitoredRegions {
      if let circularRegion = region as? CLCircularRegion {
        locationManager.stopMonitoringForRegion(circularRegion)
      }
    }
  }
  func stopMonitoringForID(id: String) {
    if let reg = getRegionByID(id) {
      locationManager.stopMonitoringForRegion(reg)
    }
    
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("remove_fence_for_user", ["token":token,"spotid":id], {json in
        if let parseJSON = json {
          println("remove_Fence: \(json)")
          var success = parseJSON["success"] as? Int
          if success == 1 {
            println("successery")
          }
        }
        }, {_ in})
    }

  }
  func stopMonitoringSpot(spot: Spot, ctrl: UIViewController) -> Bool {
    println("stopMonitor")
    if let reg = getRegionByID(spot.id) {
      println("is good")
      locationManager.stopMonitoringForRegion(reg)
      spot.tracking = false
      return true
    } else {
      showSimpleAlertWithTitle("Error", message: "Geofence not created due to an error", viewController: ctrl)
      return false
    }
  }
  
  func getRegionByID(id: String) -> CLCircularRegion? {
    for region in locationManager.monitoredRegions {
      if let circularRegion = region as? CLCircularRegion {
        if circularRegion.identifier == id {
          return circularRegion
        }
      }
    }
    
    return nil
  }
  
  func locStatusChanged(region: CLRegion, status: Int) {
    println("locStatusChanged: \(status)")
    if region is CLCircularRegion {
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        postRequest("spot_status_changed", ["token": token, "spotid": region.identifier, "status": "\(status)"], {json in
          if let p = json {
            if let s = p["success"] as? Int {
              if s < 0 {
                self.locationManager.stopMonitoringForRegion(region)
              }
            }
          }
        }, {_ in })
      }
    }
    
  }
  
  func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {

    locStatusChanged(region, status: IsThere.Yes.rawValue)
  }
  
  func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
    locStatusChanged(region, status: IsThere.No.rawValue)
  }
  
  func regionWithSpot(spot: Spot) -> CLCircularRegion? {
    if let coordinate = spot.coordinate, radius = spot.radius {
      let region = CLCircularRegion(center: coordinate, radius: radius, identifier: spot.id)
      region.notifyOnEntry = true
      region.notifyOnExit = true
      return region
    }
    
    return nil
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

