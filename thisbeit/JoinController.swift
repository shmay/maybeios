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
  var radius: Double?
  var latitude: CLLocationDegrees?
  var longitude: CLLocationDegrees?
  var pin: String?
  
  var delegate: UIViewController!
  
  @IBOutlet weak var mapView: MKMapView!
  @IBAction func tapCancel(sender: AnyObject) {
    dismissJoin()
  }
  
  func dismissJoin() {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    appDelegate.dismissJoin(self)
  }
  
  @IBAction func tapJoin(sender: AnyObject) {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String, p = pin {
      postRequest("join", ["token": token,"pin": p], { json in self.handleResp(json)}, { _ in self.handleErr()})
    }
  }
  
  func handleResp(json: NSDictionary?) {
    if let pson = json {
      if let success = pson["success"] as? Int {
        println("success: \(success)")
        if success == 1 {
          dismissJoin()
        } else {
          println("err")
          showAlert("Sorry, but you could not be added to this spot", forController:self)
        }
      }
    }
  }
  
  func handleErr() {}

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self

    if let lat = latitude, lng = longitude, rad = radius {
      var span = MKCoordinateSpanMake(0.075, 0.075)
      var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), span: span)
      mapView.setRegion(region, animated: false)
      
      let circle = MKCircle(centerCoordinate: mapView.centerCoordinate, radius: rad)
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