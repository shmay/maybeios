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
  var ref = Firebase(url:fbaseURL)
  var spotsRef = Firebase(url:"\(fbaseURL)/spots")
  var spots = [Spot]()
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var spotCnt: UInt = 0
  var cnt: UInt = 0
  
  func shouldUpdate() {
    println("shouldUPdate: cnt: \(cnt) spotCnt: \(spotCnt)")
    if cnt >= spotCnt {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.tableView.reloadData()
      })
    }
  }
  
  func loadChild(key:String, admin:Int) {
    spotsRef.childByAppendingPath(key).observeEventType(.Value,  withBlock: {child in
      println("child val: \(child.value)")
      println("child val type: \(child.value.dynamicType)")
      
      // check for existence of spot... not the greatest way
      if let name = child.childSnapshotForPath("name").value as? String {
        self.cnt += 1
        var yes = 0
        var no = 0
        var maybe = 0

        let lat = (child.childSnapshotForPath("lat").value).doubleValue
        let lng = (child.childSnapshotForPath("lat").value).doubleValue
        let radius = (child.childSnapshotForPath("lat").value).doubleValue
        
        var spot = self.spots.filter{ $0.id == child.key! }.first
        
        let coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        if spot == nil {
          spot = Spot(name:name, id:child.key!)
          self.spots.append(spot!)
        } else {
          spot!.name = name
        }
        
        if admin == 1 {
          spot!.admin = true
        } else if admin == 0 {
          spot!.admin = false
        }
        
        spot!.coordinate = coords
        spot!.radius = radius
        
        if let region = self.appDelegate.getRegionByID(spot!.id) {
          spot!.tracking = true
        } else {
          spot!.tracking = false
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
        
        self.shouldUpdate()
      }

    })
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let uid = currentUser?.id {
      ref.childByAppendingPath("users/\(uid)/spots").observeEventType(.Value, withBlock: {snapshot in
        let children = snapshot.children
        self.spotCnt = snapshot.childrenCount
        self.spots = [Spot]()
        println("reset cnt")
        self.cnt = 0
        while let child = children.nextObject() as? FDataSnapshot {
          if child.value as! Int == -1 {
            self.appDelegate.removeGeofence(child.key)
            self.tableView.reloadData()
          } else {
            self.loadChild(child.key,admin: child.value as! Int)
          }
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
    
    let profileAction = UIAlertAction(title: "Your Profile", style: .Default, handler: {action in
      self.performSegueWithIdentifier("Profile", sender: self)
    })
    alertController.addAction(profileAction)
    
    let aboutAction = UIAlertAction(title: "About", style: .Default, handler: {action in
      self.performSegueWithIdentifier("AboutUs", sender: self)
    })
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
    performSegueWithIdentifier("ShowSpot", sender:spot)
  }
  
  func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(CGRectMake(0, 0, 100, 100))
    var image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
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
    
    let img = cell.viewWithTag(1004) as! UIImageView
    
    img.image = img.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
    img.tintColor = UIColor(red: 0.0, green: 128/255.0, blue: 1, alpha: 1.0)
    if spot.tracking {
      img.hidden = false
    } else {
      img.hidden = true
    }
    
    return cell
  }
  
  func addSpotController(controller: AddSpotController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, name: String) {
    if let uid = currentUser?.id, username = currentUser?.name {
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        let values = ["name": name, "lat": "\(coordinate.latitude)", "lng": "\(coordinate.longitude)", "radius": "\(radius)",
          "token": "\(token)", "uid": "\(uid)", "username": username]
        postRequest("new_spot", values, {json in self.handleResp(json,controller:controller)}, {self.handleErr(controller)})
      }
    }
  }
  
  func handleResp(json: NSDictionary?, controller: AddSpotController) {
    controller.dismissViewControllerAnimated(true,completion:nil)

    if let parseJSON = json {
      var success = parseJSON["success"] as? Int
      println("json: \(parseJSON)")
      if success == 1 {
        println("parseJson: \(parseJSON)")
        if let lat = parseJSON["lat"] as? Double, lng = parseJSON["lng"] as? Double, radius = parseJSON["radius"] as? Double, name = parseJSON["name"] as? String, id = parseJSON["id"] as? String  {
          
          let spot = Spot(name: name, id: id)
          spot.radius = radius
          let coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
          spot.coordinate = coords

          appDelegate.startMonitoringGeotification(spot,ctrl:self)
        }

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
      ctrl.locationsController = self
      ctrl.spot = sender as! Spot
    }
  }
}