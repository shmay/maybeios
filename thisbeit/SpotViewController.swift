//
//  SpotViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class SpotViewController: UITableViewController, EditSpotControllerDelegate,UserControllerDelegate {
  let messageComposer = MessageComposer()
  
  var locationsController: LocationsViewController!
  let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
  
  var spot: Spot!
    
  let ref = Firebase(url: "\(fbaseURL)/spots/")
  
  @IBOutlet var actionItem: UIBarButtonItem!
  @IBOutlet var editBtn: UIBarButtonItem!
  @IBOutlet weak var inviteBtn: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = spot.name
    
    let id = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
 
    if spot.admin {
      self.navigationItem.rightBarButtonItems = [self.inviteBtn, self.editBtn, self.actionItem]
    } else {
      self.navigationItem.rightBarButtonItems = [self.actionItem]
    }
    
  }
  
  func spotSettingsController(controller: SpotSettingsController, hitSwitch flag: Bool) {
    if flag == true {
      appDelegate.startMonitoringGeotification(spot, ctrl: self)
    } else {
      appDelegate.stopMonitoringSpot(spot, ctrl: self)
    }
  }
  
  @IBAction func editTapped(sender: AnyObject) {
    performSegueWithIdentifier("EditSpot", sender: spot)
  }
  
  @IBAction func tapAction(sender: AnyObject) {
    self.performSegueWithIdentifier("SpotSettings", sender: self)
  }
  
  @IBAction func inviteTapped(sender: AnyObject) {
    // Make sure the device can send text messages
    showSheet()
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if (editingStyle == UITableViewCellEditingStyle.Delete) {
      var alert = UIAlertController(title: "Are you sure?", message: "This will remove the user from this spot", preferredStyle: UIAlertControllerStyle.Alert)

      alert.addAction(UIAlertAction(title: "I'm sure", style: .Destructive, handler: { action in
        println("destroy")
      }))
      
      alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
        println("Click of cancel button")
      }))
      
      self.presentViewController(alert, animated: true, completion: nil)
      // handle delete (by removing the data from your array and updating the tableview)
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if spot.admin == true  {
      if let user = getUser(indexPath.section, row: indexPath.row) {
        if (!user.admin) {
          performSegueWithIdentifier("ShowUser", sender: user)
          return
        }
      }
    }
    
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  func getUser(section: Int, row: Int) -> User? {
    if section == 0 {
      return spot.yes[row]
    } else if section == 1 {
      return spot.no[row]
    } else if section == 2 {
      return spot.maybe[row]
    } else {
      return nil
    }
  }
  
  func showSheet() {
    let alertController = UIAlertController(title: "Invite People to this Spot", message: nil, preferredStyle: .ActionSheet)
    
    let smsAction = UIAlertAction(title: "Invite via SMS", style: .Default, handler: { _ in self.openSMS() })
    alertController.addAction(smsAction)
    
    let emailAction = UIAlertAction(title: "Invite via email", style: .Default, handler: { _ in self.openEmail() })
    alertController.addAction(emailAction)
    
    let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func openSMS() {
//    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
//      postRequest("gen_invite", ["spotid": spot.id, "token":token], { json in self.handleToken(json)} , { _ in self.handleErr()})
//      // Obtain a configured MFMessageComposeViewController
//      
//      // Present the configured MFMessageComposeViewController instance
//      // Note that the dismissal of the VC will be handled by the messageComposer instance,
//      // since it implements the appropriate delegate call-back
//    }
    if (messageComposer.canSendText()) {
      if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
        postRequest("gen_invite", ["spotid": spot.id, "token":token], { json in self.handleToken(json)} , { _ in self.handleErr()})
        // Obtain a configured MFMessageComposeViewController
        
        // Present the configured MFMessageComposeViewController instance
        // Note that the dismissal of the VC will be handled by the messageComposer instance,
        // since it implements the appropriate delegate call-back
      }
    } else {
      // Let the user know if his/her device isn't able to send text messages
      let errorAlert = UIAlertView(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.", delegate: self, cancelButtonTitle: "OK")
      errorAlert.show()
    }
  }
  
  func handleToken(json:NSDictionary?) {
    if (messageComposer.canSendText()) {
      println("respjson: \(json)")
      if let pjson = json {
        let messageComposeVC = messageComposer.configuredMessageComposeViewController()
        if let pin = pjson["token"] as? String {
          let m = "You've been invited to join a spot on Maybe.  Go to http://shmay.github.io/mayweb?pin=\(pin) to join the spot."
          messageComposeVC.body = m
          presentViewController(messageComposeVC, animated: true, completion: nil)
        }
      }
    }
  }
  
  func handleErr() {
    println("handleErr")
  }

  func openEmail() {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("gen_invite", ["spotid": spot.id, "token":token], { json in
        if let j = json {
          if let pin = j["pin"] as? String {
            let m = "You've been invited to join a spot on Maybe.  Go to http://shmay.github.io/mayweb/?pin=\(pin) to join the spot."
            var emailTitle = "You've been invited to join a Spot on Maybe"
            var messageBody = m
            var mc: MFMailComposeViewController = MFMailComposeViewController()
            //    mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            self.presentViewController(mc, animated: true, completion: nil)
          }
        }
      } , { _ in self.handleErr()})
      // Obtain a configured MFMessageComposeViewController
      
      // Present the configured MFMessageComposeViewController instance
      // Note that the dismissal of the VC will be handled by the messageComposer instance,
      // since it implements the appropriate delegate call-back
    }


  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("UserCell") as! UITableViewCell
    
    if indexPath.section == 0 {
      let u = spot.yes[indexPath.row]
      cell.textLabel!.text = u.name
    } else if indexPath.section == 1 {
      let u = spot.no[indexPath.row]
      cell.textLabel!.text = u.name
    } else if indexPath.section == 2 {
      let u = spot.maybe[indexPath.row]
      cell.textLabel!.text = u.name
    }
    
    return cell
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return spot.yes.count
    } else if section == 1 {
      return spot.no.count
    } else if section == 2 {
      return spot.maybe.count
    } else {
      return 0
    }
  }
  
  override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 5.0))
    footerView.backgroundColor = UIColor.whiteColor()
    
    return footerView
  }
  
  override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 5.0
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 3
  }
  
  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    var str = "?"
    
    if section == 0 {
      str = "Yes (\(spot.yes.count))"
    } else if section == 1 {
      str = "No (\(spot.no.count))"
    } else if section == 2 {
      str = "Maybe (\(spot.maybe.count))"
    }
    
    return str
  }
  
  func userController(controller: UserController, removedUser user:User) {
    controller.dismissViewControllerAnimated(true, completion: nil)
 
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("remove_user", ["token": token, "uid": user.id, "spotid":spot.id], {json in }, {_ in })
    }
  }

  func editSpotController(controller: EditSpotController, updatedName name: String) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    
    title = name
    spot.name = name
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      postRequest("edit_spot", ["name": name, "spotid":spot.id,"token": token], {json in self.handleResp(json)}, {_ in self.handleErr()})
    }
  }
  
  func editSpotControllerRemoveSpot(controller: EditSpotController) {
    if let token = NSUserDefaults.standardUserDefaults().valueForKey("token") as? String {
      self.locationsController.spotCtrl = nil
      postRequest("remove_spot", ["token": token, "spotid":spot.id], { json in
        controller.dismissViewControllerAnimated(true, completion: { action in
          self.locationsController.navigationController?.popViewControllerAnimated(true)
        })
      }, { _ in self.handleErr() })
    }
  }
  
  func trackingChanged() {
    locationsController.tableView.reloadData()
  }
  
  func handleResp(json: NSDictionary?) {}
    
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "EditSpot" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! EditSpotController
      vc.name = spot.name
      vc.delegate = self
    } else if segue.identifier == "SpotSettings" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! SpotSettingsController
      vc.spotView = self
      vc.spot = spot
    } else if segue.identifier == "ShowUser" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! UserController

      vc.delegate = self
      vc.user = sender as! User
    }
  }
}