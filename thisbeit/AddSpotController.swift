//
//  ViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
import MapKit

protocol AddSpotControllerDelegate {
  func addSpotController(controller: AddSpotController, didAddCoordinate coordinate:CLLocationCoordinate2D, radius: Double, name: String)
}

class AddSpotController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
  var radius: Double = Double(100)
  var circle: MKCircle?
  
  private var mapChangedFromUserInteraction = false
  
  var delegate: AddSpotControllerDelegate!
  
  @IBOutlet weak var mapView: MKMapView!
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var radiusLabel: UILabel!
  @IBOutlet weak var slider: UISlider!
  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
  @IBOutlet weak var nameTextField: UITextField!
  
  let locationManager = CLLocationManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItems = [addButton, zoomButton]
    addButton.enabled = false
    
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    mapView.delegate = self
    
    nameTextField.delegate = self
  }
//  35.268788, -120.647849
  
  @IBAction func textFieldEditingChanged(sender: UITextField) {
    addButton.enabled = !nameTextField.text.isEmpty
  }
  
  @IBAction func onCancel(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    nameTextField.resignFirstResponder()
  }
  
  func textFieldShouldReturn(textField: UITextField!) -> Bool // called when 'return' key pressed. return NO to ignore.
  {
    textField.resignFirstResponder()
    return true;
  }
  
  private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
    let view = self.mapView.subviews[0] as! UIView
    //  Look through gesture recognizers to determine whether this region change is from user interaction
    if let gestureRecognizers = view.gestureRecognizers {
      for recognizer in gestureRecognizers {
        if( recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended ) {
          return true
        }
      }
    }
    return false
  }
  
  func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
    if (mapChangedFromUserInteraction) {
      // user changed map region
    }
  }
  
  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    if (mapChangedFromUserInteraction) {
      println("did change region2")
      
      mapView.removeOverlay(circle)
      circle = MKCircle(centerCoordinate: mapView.centerCoordinate, radius: radius as CLLocationDistance)
      mapView.addOverlay(circle)
      // user changed map region
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
  
  // This method is called when the player moves the slider.
  @IBAction func sliderMoved(slider: UISlider) {
    // The position of the slider is a value between 1 and 100, and may contain
    // digits after the decimal point. You round the value to a whole number and
    // store it in the currentValue variable.
    radius = Double(lroundf(slider.value))
    
    radiusLabel.text = "\(radius)m"
    
    mapView.removeOverlay(circle)
   
    circle = MKCircle(centerCoordinate: mapView.centerCoordinate, radius: radius as CLLocationDistance)
    mapView.addOverlay(circle)
    
    // If you want to see the current value as you're moving the slider, then
    // uncomment the println() line below (remove the //) and keep an eye on the
    // output console when you run the app.
    
    //println("currentValue = \(currentValue)")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
  
  @IBAction private func onAdd(sender: AnyObject) {
    var coordinate = mapView.centerCoordinate
    var name = nameTextField.text
    
    delegate!.addSpotController(self, didAddCoordinate: coordinate, radius: radius, name: name)
  }
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .AuthorizedAlways)
  }
  
  func zoomToUserLocationInMapView(mapView: MKMapView) {
    if let coordinate = mapView.userLocation.location?.coordinate {
      let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
      mapView.setRegion(region, animated: true)
    }
  }
}