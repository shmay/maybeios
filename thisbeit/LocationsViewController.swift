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
  var addingSpot = false
  var firstSpotsLoad = false

  weak var spotCtrl: SpotViewController?
  
  func shouldUpdate() {
    println("shouldUPdate: cnt: \(cnt) spotCnt: \(spotCnt)")
    if cnt >= spotCnt {
      println("firstSpotsLoad: \(firstSpotsLoad)")
      if firstSpotsLoad {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "firstSpotsLoad")
        firstSpotsLoad = false
        appDelegate.startMonitoringSpots(spots, ctrl:self)
        appDelegate.checkSpots()
      }
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.tableView.reloadData()
      })

    }
  }
  
  func loadChild(key:String, admin:Int) {
    println("load child")
    spotsRef.childByAppendingPath(key).observeEventType(.Value,  withBlock: {child in
//      println("child val: \(child.value)")
//      println("child val type: \(child.value.dynamicType)")
      
      // check for existence of spot... not the greatest way
      if let name = child.childSnapshotForPath("name").value as? String {
        println("change spot: \(name)")
        self.cnt += 1

        let lat = (child.childSnapshotForPath("lat").value).doubleValue
        let lng = (child.childSnapshotForPath("lng").value).doubleValue
        let radius = (child.childSnapshotForPath("radius").value).doubleValue
        
        var spot = self.spots.filter{ $0.id == child.key! }.first
        
        let coords = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        if spot == nil {
          spot = Spot(name:name, id:child.key!)
          self.spots.append(spot!)
        } else {
          spot!.name = name
        }
        
        spot!.yes = [User]()
        spot!.no = [User]()
        spot!.maybe = [User]()
        
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
          let key = userSnap.key
          
          let user = userSnap.value
          
          let name = user["name"] as! String
          let isAdmin = user["admin"] as! Bool
          
          let state = CLRegionState(rawValue: user["state"] as! Int)
          
          let u = User(name: name, id: userSnap.key!, state: state!)
          u.admin = isAdmin
          
          if let cu = currentUser {
            if cu.id == u.id {
              spot!.state = u.state
              NSUserDefaults.standardUserDefaults().setInteger(u.state.rawValue, forKey: "\(spot!.id)-server")
            }
          }

          if state == .Inside {
            spot!.yes.append(u)
          } else if state == .Outside {
            spot!.no.append(u)
          } else if state == .Unknown {
            spot!.maybe.append(u)
          }
        }
        
        if let sptc = self.spotCtrl {
          if sptc.spot.id == spot!.id {
            sptc.spot = spot
            sptc.tableView.reloadData()
          }
        }
        
        self.shouldUpdate()
      }

    })
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    println("viewdidload")
    
    if let fs = NSUserDefaults.standardUserDefaults().valueForKey("firstSpotsLoad") as? Bool {
      firstSpotsLoad = fs
    }
    
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
    
    var str:String? = UIPasteboard.generalPasteboard().string
    println("STRT: \(str)")
    if let s = str {
      if count(s) == 10 {
        let matches = regexMatches("(^X\\w+)", s)
        
        if count(matches) > 0 {
          delay(0.2) {
            self.appDelegate.joinWithPin(matches[0], controller: self)
            UIPasteboard.generalPasteboard().string = ""
          }
        }
      }
    }
    
    println("check for pin")
    if let pin = NSUserDefaults.standardUserDefaults().stringForKey("pin") {
      println("pin: \(pin)")
      appDelegate.joinWithPin(pin, controller: self)
      NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "pin")
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
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        let values = ["token": "\(token)"]
        postRequest("logout", values, {json in
          NSUserDefaults.standardUserDefaults().removeObjectForKey("uid")
          NSUserDefaults.standardUserDefaults().removeObjectForKey("token")
          NSUserDefaults.standardUserDefaults().removeObjectForKey("name")
          self.appDelegate.stopMonitoringSpots()
          
          NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstSpotsLoad")
          
          if currentUser!.provider == "facebook" {
            let facebookLogin = FBSDKLoginManager()
            facebookLogin.logOut()
          }
          
          self.ref.unauth()
          currentUser = nil
          
          self.performSegueWithIdentifier("GoHome", sender: self)
        }, {error in })
      }
      
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
    yes.text = "\(count(spot.yes))"
    
    let no = cell.viewWithTag(1002) as! UILabel
    no.text = "\(count(spot.no))"
    
    let maybe = cell.viewWithTag(1003) as! UILabel
    maybe.text = "\(count(spot.maybe))"
    
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
    if !addingSpot {
      if let uid = currentUser?.id, username = currentUser?.name {
        if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
          let values = ["name": name, "lat": "\(coordinate.latitude)", "lng": "\(coordinate.longitude)", "radius": "\(radius)",
            "token": "\(token)", "uid": "\(uid)", "username": username]
          postRequest("new_spot", values, {json in self.handleResp(json,controller:controller)}, {self.handleErr(controller)})
        }
      }
    }
  }
  
  func handleResp(json: NSDictionary?, controller: AddSpotController) {
    addingSpot = false
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

          if let reg = appDelegate.startMonitoringGeotification(spot,ctrl:self) {
            appDelegate.withinRegion(spot.id)
          }

        }

      }
    }
  }
  
  func handleErr(controller: AddSpotController) {
    addingSpot = false
    controller.dismissViewControllerAnimated(true,completion:nil)
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    spotCtrl = nil
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "AddSpot" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddSpotController
      vc.delegate = self
    } else if segue.identifier == "ShowSpot" {
      let ctrl = segue.destinationViewController as! SpotViewController
      spotCtrl = ctrl
      ctrl.locationsController = self
      ctrl.spot = sender as! Spot
    }
  }
}