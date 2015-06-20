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
  var spotsRef = Firebase(url:"https://androidkye.firebaseio.com/spots")
  
  var spots = [Spot]()
  let locationManager = CLLocationManager()
  
  @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {
    println("yoyoyo")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    spotsRef.queryOrderedByChild("simplelogin:1")
      .observeEventType(.Value, withBlock: { snapshot in
        self.spots = [Spot]()
        
        var children = snapshot.children
        while let child = children.nextObject() as? FDataSnapshot {
          var yes = 0
          var no = 0
          var maybe = 0

          let name = child.childSnapshotForPath("name").value
          
          let spot = Spot(name:name as! String, id:child.key!)
          
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
          
          spot.yes = yes
          spot.no = no
          spot.maybe = maybe
          
          self.spots.append(spot)
        }

//        var children = snapshot.children
//        let name = snapshot.childSnapshotForPath("name").value
//        let spot = Spot(name:name as! String, id:snapshot.key!)
//        self.spots.append(spot)
//        
//        for child in snapshot.children {
//          if let key = child.key {
//            if let match = key!.rangeOfString("^simplelogin", options: .RegularExpressionSearch){
//              let value = (child as! FDataSnapshot).value
//              
//              if let isthere = IsThere(rawValue:value["isthere"] as! Int) {
//                let user = User(name:value["name"] as! String, id:key!, isThere: isthere)
//                spot.users.append(user)
//                println("has: \(user)")
//              }
//
//            } else if key == "name" {
//              println("is name")
//            }
//          }
//        }
//        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.tableView.reloadData()
        })

      })
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
    controller.dismissViewControllerAnimated(true, completion: nil)
    let values = ["isthere": 2, "name": name, "lat": coordinate.latitude, "lng": coordinate.longitude, "radius": radius]
    
    let ref = spotsRef.childByAutoId()
    ref.setValue(values)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "AddSpot" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddSpotController
      vc.delegate = self
    }
  }
}