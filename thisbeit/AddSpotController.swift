//
//  ViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/12/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
import MapKit

class AddSpotController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
  var radius: Double!
  var circle: MKCircle?
  let pin = MKPointAnnotation()
  
  @IBOutlet weak var mapView: MKMapView!
  
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

    var location = CLLocationCoordinate2DMake(35.268788 as CLLocationDegrees,-120.647849 as CLLocationDegrees)
    var region = MKCoordinateRegionMakeWithDistance(location, 5000, 5000)
    mapView.setRegion(region, animated: true)
    
//    pin.coordinate = location
//    pin.title = "drag me"
//    mapView.addAnnotation(pin)
    
    circle = MKCircle(centerCoordinate: location, radius: 100 as CLLocationDistance)
    self.mapView.addOverlay(circle)
    
    // Do any additional setup after loading the view, typically from a nib.
  }
//  35.268788, -120.647849
  
  @IBAction func textFieldEditingChanged(sender: UITextField) {
    addButton.enabled = !nameTextField.text.isEmpty
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    
    if newState == MKAnnotationViewDragState.Ending || newState == MKAnnotationViewDragState.Canceling {
      let location = CLLocationCoordinate2DMake(self.pin.coordinate.latitude as CLLocationDegrees,self.pin.coordinate.longitude as CLLocationDegrees)

      mapView.removeOverlay(circle)
      circle = MKCircle(centerCoordinate: location, radius: 100 as CLLocationDistance)
      mapView.addOverlay(circle)
      
    }
    println("annotationView")

  }
  
//  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
//    println("callerina")
//    if annotation is MKPointAnnotation {
//      println("okkkk")
//      let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
//      
//      pinAnnotationView.pinColor = .Purple
//      pinAnnotationView.draggable = true
//      pinAnnotationView.canShowCallout = true
//      pinAnnotationView.animatesDrop = true
//      
//      return pinAnnotationView
//    }
//    
//    return nil
//  }
//  
//  func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
//    if overlay is MKCircle {
//      var circle = MKCircleRenderer(overlay: overlay)
//      circle.strokeColor = UIColor.redColor()
//      circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
//      circle.lineWidth = 1
//      return circle
//    } else {
//      return nil
//    }
//  }
  
  // This method is called when the player moves the slider.
  @IBAction func sliderMoved(slider: UISlider) {
    // The position of the slider is a value between 1 and 100, and may contain
    // digits after the decimal point. You round the value to a whole number and
    // store it in the currentValue variable.
    radius = Double(lroundf(slider.value))
    
    radiusLabel.text = "\(radius)m"
    
    let location = CLLocationCoordinate2DMake(self.pin.coordinate.latitude as CLLocationDegrees,self.pin.coordinate.longitude as CLLocationDegrees)
    
    mapView.removeOverlay(circle)
   
    circle = MKCircle(centerCoordinate: location, radius: radius as CLLocationDistance)
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
    println("zoom")
    zoomToUserLocationInMapView(mapView)
  }
  
  @IBAction private func onAdd(sender: AnyObject) {
  }
  
  func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    //mapView.showsUserLocation = (status == .AuthorizedAlways)
  }
  
  func zoomToUserLocationInMapView(mapView: MKMapView) {
    if let coordinate = mapView.userLocation.location?.coordinate {
      let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
      mapView.setRegion(region, animated: true)
    }
  }
}