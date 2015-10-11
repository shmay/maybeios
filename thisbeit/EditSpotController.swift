//
//  EditSpotController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/22/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit

protocol EditSpotControllerDelegate {
  func editSpotController(controller: EditSpotController, updatedName name:String)
  func editSpotControllerRemoveSpot(controller: EditSpotController)
}

class EditSpotController: UIViewController {
  var name: String?
  var delegate: EditSpotControllerDelegate!
  
  @IBOutlet weak var deleteBtn: UIButton!
  @IBOutlet weak var textField: UITextField!
  
  @IBAction func cancelTapped(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  @IBAction func destroyTapped(sender: AnyObject) {
    showSheet()
  }
  
  @IBAction func updateTapped(sender: AnyObject) {
    name = textField.text
    delegate!.editSpotController(self, updatedName: textField.text!)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textField.text = name
  }
  
  func showSheet() {
    let alertController = UIAlertController(title: "Are you sure?", message: "All users will be removed, and the spot destroyed", preferredStyle: .ActionSheet)
    
    let destroyAction = UIAlertAction(title: "Destroy Spot", style: .Destructive, handler: { action in
      self.delegate!.editSpotControllerRemoveSpot(self)
    })
    alertController.addAction(destroyAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    presentViewController(alertController, animated:true, completion: nil)
  }
  
}