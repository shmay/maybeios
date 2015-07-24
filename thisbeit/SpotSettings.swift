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
  
  @IBOutlet weak var trackingLabel: UILabel!
  @IBOutlet weak var flag: UISwitch!
  
  @IBAction func flagTurned(sender: AnyObject) {
    if flag.on {
      trackingLabel.text = "tracking"
      spot.tracking = true
      let result = appDelegate.startMonitoringGeotification(spot, ctrl: self)
      if !result {
        flag.on = false
        trackingLabel.text = "not tracking"
      }
    } else {
      spot.tracking = false
      trackingLabel.text = "not tracking"
      let result = appDelegate.stopMonitoringSpot(spot, ctrl: self)
      if !result {
        flag.on = true
        trackingLabel.text = "tracking"
      }
    }
    
    spotView.trackingChanged()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    println("tracking: \(spot.tracking)")
    flag.on = spot.tracking
    let text = spot.tracking ? "tracking" : "not tracking"
    trackingLabel.text = text
  }
  

}