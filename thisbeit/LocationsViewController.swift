//
//  LocationsViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/13/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class LocationsViewController: UITableViewController, AddSpotControllerDelegate {
  var ref = Firebase(url:"https://androidkye.firebaseio.com/")
  var spotsRef = Firebase(url:"https://androidkye.firebaseio.com/spots")
  var spots = [Spot]()

  let locationManager = CLLocationManager()
  
  func loadChild(key:String) {
    spotsRef.childByAppendingPath(key).observeEventType(.Value,  withBlock: {child in
      var yes = 0
      var no = 0
      var maybe = 0

      let name = child.childSnapshotForPath("name").value as! String
      
      var spot = self.spots.filter{ $0.id == child.key! }.first
      
      if spot == nil {
        spot = Spot(name:name as! String, id:child.key!)
        self.spots.append(spot!)
      } else {
        spot!.name = name
      }

      let users = child.childSnapshotForPath("users").children

      while let userSnap = users.nextObject() as? FDataSnapshot {
        let user = userSnap.value
        let isThere = IsThere(rawValue: user["isthere"] as! Int)

        if isThere == .Yes {
          yes += 1
        } else if isThere == .No {
          no += 1
        } else if isThere == .Maybe {
          maybe += 1
        }
      }
      
      spot!.yes = yes
      spot!.no = no
      spot!.maybe = maybe
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.tableView.reloadData()
      })
    })
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    println("uid: \(currentUser?.id)")
    let arr = ["-JsDTIykg3FjwvSEel8o","-JsTaOolmh3mhgbBuLir"]
    
    for a in arr {
      spotsRef.childByAppendingPath(a).observeEventType(.Value, withBlock: {snapshot in
        println("nawsnap: \(snapshot.key)")
      })
    }
    
    if let uid = currentUser?.id {
      ref.childByAppendingPath("users/\(uid)/spots").observeEventType(.Value, withBlock: {snapshot in
        let children = snapshot.children
        self.spots = [Spot]()
        while let child = children.nextObject() as? FDataSnapshot {
          self.loadChild(child.key)
        }
      })
    }
  }
  
  func unwindToMainMenu() {}
  
  @IBAction func tapAction(sender: AnyObject) {
    showSheet()
  }
  
  func showSheet() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    let aboutAction = UIAlertAction(title: "About", style: .Default, handler: nil)
    alertController.addAction(aboutAction)
    
    let logoutAction = UIAlertAction(title: "Logout", style: .Destructive, handler: { action in
      NSUserDefaults.standardUserDefaults().removeObjectForKey("uid")
      (UIApplication.sharedApplication().delegate as! AppDelegate).justLoggedOut = true

      self.spotsRef.unauth()

      self.performSegueWithIdentifier("GoHome", sender: self)
    })
    
    alertController.addAction(logoutAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return spots.count
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let spot = spots[indexPath.row]
    performSegueWithIdentifier("ShowSpot", sender: spot)
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("SpotCell") as! UITableViewCell
    
    let spot = spots[indexPath.row]
    
    let label = cell.viewWithTag(1000) as! UILabel
    label.text = spot.name
    
    let yes = cell.viewWithTag(1001) as! UILabel
    yes.text = "\(spot.yes)"
    
    let no = cell.viewWithTag(1002) as! UILabel
    no.text = "\(spot.no)"
    
    let maybe = cell.viewWithTag(1003) as! UILabel
    maybe.text = "\(spot.maybe)"
    
    return cell
  }
  
  func stopMonitoringSpots() {
    for region in locationManager.monitoredRegions {
      if let circularRegion = region as? CLCircularRegion {
        locationManager.stopMonitoringForRegion(circularRegion)
      }
    }
  }
  
  func regionWithSpot(spot: Spot) -> CLCircularRegion? {
    // 1
    if let coordinate = spot.coordinate, radius = spot.radius {
      let region = CLCircularRegion(center: coordinate, radius: radius, identifier: spot.id)
      // 2
      region.notifyOnEntry = true
      region.notifyOnExit = true
      return region
    }
    
    return nil
  }
  
  func startMonitoringGeotification(spot: Spot) {
    if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
      showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
      return
    }
    if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
      showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
    }
    
    if let region = regionWithSpot(spot) {
      locationManager.startMonitoringForRegion(region)
    } else {
      showSimpleAlertWithTitle("Error", message: "Geofence not created due to an error", viewController: self)
    }
  }
  
  func addSpotController(controller: AddSpotController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, name: String) {
    
    if let uid = currentUser?.id, username = currentUser?.name {
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        let values = ["name": name, "lat": "\(coordinate.latitude)", "lng": "\(coordinate.longitude)", "radius": "\(radius)",
          "token": "\(token)", "uid": "\(uid)", "username": username]
        postRequest("new_spot", values, {json in self.handleResp(json,controller:controller)}, {self.handleErr(controller)})
      }
    }
    
//    let ref = spotsRef.childByAutoId()
//    ref.setValue(values)
  }
  
  func handleResp(json: NSDictionary?, controller: AddSpotController) {
    controller.dismissViewControllerAnimated(true,completion:nil)

    if let parseJSON = json {
      var success = parseJSON["success"] as? Int
      println("json: \(parseJSON)")
      if success > 0 {
        println("trans")
        // transition
      }
    }
  }
  
  func handleErr(controller: AddSpotController) {
    controller.dismissViewControllerAnimated(true,completion:nil)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "AddSpot" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddSpotController
      vc.delegate = self
    } else if segue.identifier == "ShowSpot" {
      let ctrl = segue.destinationViewController as! SpotViewController
      ctrl.spot = sender as! Spot
    }
  }
}