//
//  SpotSettings.swift
//  thisbeit
//
//  Created by Kyle Murphy on 7/21/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

class SpotSettingsController: UITableViewController {
  var spot: Spot!
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  var spotView: SpotViewController!
  var spinning = false
  
  @IBAction func checkStatus(sender: AnyObject) {
    appDelegate.checkStatusForSpot(spot)
  }
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var trackingLabel: UILabel!
  @IBOutlet weak var flag: UISwitch!
  
  @IBAction func tapCancel(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  @IBAction func flagTurned(sender: AnyObject) {
    if flag.on {
      trackingLabel.text = "tracking"
      spot.tracking = true
      let result = appDelegate.startMonitoringGeotification(spot, ctrl: self)
      
      if result != nil {
        appDelegate.checkStatusForSpot(spot)
      } else {
        flag.on = false
        trackingLabel.text = "not tracking"
      }
    } else {
      spot.tracking = false
      trackingLabel.text = "not tracking"
      let result = appDelegate.stopMonitoringSpot(spot, ctrl: self)
      if result {
        if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
          let d = ["token": token, "spotid": spot.id, "status": "0"]
          postRequest("spot_status_changed", params: d, success: {json in
            if let j = json {
              let s = j["success"] as? Int
              if s == 1 {
                self.spot.state = .Unknown
              } else if self.spot.state != .Unknown {
                
              }
            }
          }, errorCb: {err in
            })
        }
      } else {
        flag.on = true
        trackingLabel.text = "tracking"
      }
    }
    
    spotView.trackingChanged()
  }
  
  @IBAction func leaveSpot(sender: AnyObject) {
    if !spinning {
      leaveSheet()
    }
  }
  
  func leaveSheet() {
    let alert = UIAlertController(title: "Are you sure?", message: "You will not be able to rejoin the spot without receiving a new invitation", preferredStyle: UIAlertControllerStyle.Alert)
    
    alert.addAction(UIAlertAction(title: "I'm sure", style: .Destructive, handler: { action in self.leaveSpot() }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
    
  }
  func spin() {
    spinning = true
    spinner.startAnimating()
    spinner.hidden = false
  }
  func stopSpin() {
    spinning = false
    spinner.stopAnimating()
    spinner.hidden = true
  }
  func leaveSpot() {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      self.spin()

      postRequest("leave_spot", params: ["token":token, "spotid":spot.id], success: {json in
        self.stopSpin()
        if let success = json!["success"] as? Int {
          if success < 0 {
            self.leaveErr()
          } else {
            self.spotView.locationsController.spotCtrl = nil
            self.spotView.locationsController.shouldUpdate()
            self.spotView.dismissViewControllerAnimated(true, completion: {_ in
              self.spotView.dismissViewControllerAnimated(true, completion: nil)
            })
          }
        } else {
          self.leaveErr()
        }
      }, errorCb: {_ in
        self.stopSpin()
        self.leaveErr()
      })
    }
  }
  
  func leaveErr() {
    showSimpleAlertWithTitle("Error!", message: "an error occurred while trying to leave this spot", viewController: self, onok:nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    spinner.hidden = true
    
    print("tracking: \(spot.tracking)")
    flag.on = spot.tracking
    let text = spot.tracking ? "tracking" : "not tracking"
    trackingLabel.text = text
  }
  

}