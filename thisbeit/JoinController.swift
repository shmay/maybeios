//
//  JoinController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/27/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class JoinController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
  var spot: Spot!
  var pin: String?
  
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
  @IBOutlet weak var mapView: MKMapView!
  @IBAction func tapCancel(sender: AnyObject) {
    dismissJoin()
  }
  
  func dismissJoin() {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func tapJoin(sender: AnyObject) {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String, p = pin {
      postRequest("join", ["token": token,"pin": p], { json in self.handleResp(json)}, { _ in self.handleErr()})
    }
  }
  
  func handleResp(json: NSDictionary?) {
    if let pson = json {
      if let success = pson["success"] as? Int {
        if success == 1 {
          if let region = appDelegate.startMonitoringGeotification(spot, ctrl: self) {
            appDelegate.withinRegion(spot.id)
          } else {

          }
//          let region = appDelegate.getRegionByID(spot.id)
//          NSUserDefaults.standardUserDefaults().setValue(<#value: AnyObject?#>, forKey: <#String#>)
          dismissJoin()
        } else {
          showAlert("Sorry, but you could not be added to this spot", forController:self)
        }
      }
    }
  }
  
  func handleErr() {}

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self

    if let coord = spot.coordinate {
      var span = MKCoordinateSpanMake(0.075, 0.075)
      var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude), span: span)
      mapView.setRegion(region, animated: false)
      
      let circle = MKCircle(centerCoordinate: mapView.centerCoordinate, radius: spot.radius!)
      mapView.addOverlay(circle)
    }
  }
  
  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
    if overlay is MKCircle {
      var circle = MKCircleRenderer(overlay: overlay)
      circle.strokeColor = UIColor.redColor()
      circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
      circle.lineWidth = 1
      return circle
    } else {
      return nil
    }
  }
  
}