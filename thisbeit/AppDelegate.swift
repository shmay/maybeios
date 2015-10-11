//
//  AppDelegate.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
import CoreLocation
//
let fbaseURL = "https://maybeso.firebaseio.com"
let twitterAPIKey = "LHOdkJjlt1SyDBxsrUpEirAGl"
let serverURL = "https://maybeserver.xyz"
//let fbaseURL = "https://androidkye.firebaseio.com"
//let twitterAPIKey = "EPOngDM26zvGi5sHuDpYXsAiM"
//let serverURL = "http://localhost:3000"
//let serverURL = "http://192.168.1.108:3000"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
  var justLoggedOut = false
  var fbAuthing = false
  
  let ref = Firebase(url: fbaseURL)
  var pin: String?
  
  var holdViewController: UIViewController?
  var alert: UIAlertController?
  let locationManager = CLLocationManager()

  var window: UIWindow?
  
  func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    print("options: \(launchOptions)")
    
    let fs = NSUserDefaults.standardUserDefaults().valueForKey("firstSpotsLoad") as? Bool
    
    if fs == nil {
      NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstSpotsLoad")
    }
    
    return true
  }

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    if let onrr = NSUserDefaults.standardUserDefaults().valueForKey("onrr") as? Bool {
      print("onrr: \(onrr)")
    }
    print("options: \(launchOptions)")
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()

    locationManager.startMonitoringSignificantLocationChanges()
    
    if let URL = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL {
      let matches = regexMatches("pin\\=(X\\w{9})", text: URL.absoluteString)
      
      if matches.count > 0 {
        let pin = matches[0]
        
        if let _ = currentUser {
          self.joinWithPin(pin, controller: nil)
        } else {
          print("stash pin: \(pin)")
          NSUserDefaults.standardUserDefaults().setValue(pin, forKey: "pin")
        }
      }
      
      // If we get here, we know launchOptions is not nil, we know
      // UIApplicationLaunchOptionsURLKey was in the launchOptions
      // dictionary, and we know that the type of the launchOptions
      // was correctly identified as NSURL.  At this point, URL has
      // the type NSURL and is ready to use.
    }
    
    allSpots()
    return true
  }
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    if status != .AuthorizedAlways {
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        postRequest("reset", params: ["token": token], success: {json in }, errorCb: {err in })
      }
    }
  }
  
  func joinWithPin(pin: String, controller: UIViewController?) {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      let dict = ["token": token, "pin":pin]
      postRequest("join_w_pin", params: dict, success: {json in self.handleResp(json, controller:controller)}, errorCb: {self.handleErr()})
    }
  }
  
  func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
    print("url: \(url.absoluteString)")
    print("sa: \(sourceApplication)")
    
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "onrr")
    
    let matches = regexMatches("pin\\=(X\\w{9})", text: url.absoluteString)

    if matches.count > 0 {
      let pin = matches[0]
      
      if let u = currentUser {
        print("u.name: \(u.name)")
        if u.name.characters.count > 0 {
          joinWithPin(pin, controller: nil)
        } else {
          NSUserDefaults.standardUserDefaults().setValue(pin, forKey: "pin")
        }
      } else {
        NSUserDefaults.standardUserDefaults().setValue(pin, forKey: "pin")
      }
    }
    
    return true
  }
  
  func withinRegion(id: String) {
    delay(0.5) {
      if let reg = self.getRegionByID(id) {
        print("withinRegion: \(id)")
        self.locationManager.requestStateForRegion(reg)
      }
    }
  }
  
  func removeGeofence(spotid: String) {
    self.stopMonitoringForID(spotid)
  }
  
  func handleResp(json: NSDictionary?, controller: UIViewController?) {
    if let parseJSON = json {
      print("json: \(json)")
      let success = parseJSON["success"] as? Int
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
          
          if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
              topController = presentedViewController
            }
            
            delay(0.3) {
              topController.presentViewController(vc, animated: true, completion: nil)
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
  
  func startMonitoringGeotification(spot: Spot, ctrl: UIViewController) -> CLCircularRegion? {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: ctrl, onok: nil)
      return nil
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Please authorize Always location access to save this Geo-fence.", viewController: ctrl, onok: nil)
      return nil
    }
    
    let reg = getRegionByID(spot.id)
    
    if reg == nil {
      if let region = regionWithSpot(spot) {
        print("star moni: \(region.center.latitude),\(region.center.longitude); \(region.radius)")
        locationManager.startMonitoringForRegion(region)
        return region
      } else {
        showSimpleAlertWithTitle("Error", message: "Geofence already exists", viewController: ctrl, onok: nil)
      }
    }
    
    return nil
  }
  
  func startMonitoringSpots(spots: [Spot], ctrl: UIViewController) {
    for spot in spots {
      if spot.state != .Unknown {
        let reg = getRegionByID(spot.id)
        
        if reg == nil {
          if let _ = startMonitoringGeotification(spot, ctrl: ctrl) {
            spot.tracking = true
          }
        }
      }
    }
  }
  
  func allSpots() {
    for region in locationManager.monitoredRegions {
      if let cr = region as? CLCircularRegion {
        print("region: \(cr.center.latitude),\(cr.center.longitude); \(cr.radius)")
      }
    }
  }
  
  func stopMonitoringSpots() {
    for region in locationManager.monitoredRegions {
      if let circularRegion = region as? CLCircularRegion {
        locationManager.stopMonitoringForRegion(circularRegion)
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "\(circularRegion.identifier)-server")
      }
    }
  }
  
  func stopMonitoringForID(id: String) {
    if let reg = getRegionByID(id) {
      locationManager.stopMonitoringForRegion(reg)
    }
    
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("remove_fence_for_user", params: ["token":token,"spotid":id], success: {json in
        if let parseJSON = json {
          print("remove_Fence: \(json)")
          let success = parseJSON["success"] as? Int
          if success == 1 {
            print("successery")
          }
        }
        }, errorCb: {_ in})
    }
  }
  
  func stopMonitoringSpot(spot: Spot, ctrl: UIViewController) -> Bool {
    print("stopMonitor")
    if let reg = getRegionByID(spot.id) {
      print("is good")
      locationManager.stopMonitoringForRegion(reg)
      spot.tracking = false
      return true
    } else {
//      showSimpleAlertWithTitle("Error", message: "Geofence not destroyed due to an error", viewController: ctrl)
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
  
  func locStatusChanged(spotid: String, status: Int) {
    print("locStatusChanged: \(status)")
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("spot_status_changed", params: ["token": token, "spotid": spotid, "status": "\(status)"], success: {json in
        if let p = json {
          if let s = p["success"] as? Int {
            if s == 1 {
              if let j = p["status"] as? Int {
                print("setServer")
                NSUserDefaults.standardUserDefaults().setInteger(j, forKey: "\(spotid)-server")
              }
            } else if s < 0 {
              if let reg = self.getRegionByID(spotid) {
                self.locationManager.stopMonitoringForRegion(reg)
              }
            }
          }
        }
      }, errorCb: {_ in })
    }
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("didUpdateLocations")
    if let fs = NSUserDefaults.standardUserDefaults().valueForKey("firstSpotsLoad") as? Bool {
      if fs != true {
        checkSpots()
      }
    }
  }
  
  func checkSpots() {
    for region in locationManager.monitoredRegions {
      if let reg = region as? CLCircularRegion {
        self.locationManager.requestStateForRegion(reg)
      }
    }
  }
  
  func checkSpotsExceptFor(r: CLRegion) {
    for region in locationManager.monitoredRegions {
      if let reg = region as? CLCircularRegion {
        if r.identifier != reg.identifier {
          self.locationManager.requestStateForRegion(reg)
        }
      }
    }
  }
  
  func checkStatusForSpot(spot: Spot) {
    print("spotid: \(spot.id)")
    if let reg = getRegionByID(spot.id) {
      print("check status for: \(spot.name)")
      delay(0.5) {
        self.locationManager.requestStateForRegion(reg)
      }
    }
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    print("didEnter: \(CLRegionState.Inside.rawValue)")
    locStatusChanged(region.identifier, status: CLRegionState.Inside.rawValue)
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    print("didExit: \(CLRegionState.Outside.rawValue)")
    locStatusChanged(region.identifier, status: CLRegionState.Outside.rawValue)
  }
  
  func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
    print("didDetermnine: \(state.rawValue)")
    if let serverVal = NSUserDefaults.standardUserDefaults().valueForKey("\(region.identifier)-server") as? Int {
      if state.rawValue != serverVal {
        print("state: \(state.rawValue)")
        print("serverVal: \(serverVal)")
        locStatusChanged(region.identifier, status: state.rawValue)
      }
    } else {
      // if no server value, then default state is maybe
      locStatusChanged(region.identifier, status: state.rawValue)
    }

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
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

