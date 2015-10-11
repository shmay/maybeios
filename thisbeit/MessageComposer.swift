//
//  MessageComposer.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/21/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import Foundation

import MessageUI

class MessageComposer: NSObject, MFMessageComposeViewControllerDelegate {
  
  // A wrapper function to indicate whether or not a text message can be sent from the user's device
  func canSendText() -> Bool {
    return MFMessageComposeViewController.canSendText()
  }
  
  // Configures and returns a MFMessageComposeViewController instance
  func configuredMessageComposeViewController() -> MFMessageComposeViewController {
    let messageComposeVC = MFMessageComposeViewController()
    messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
    messageComposeVC.body = "You've been invited to join a Maybe spot.  Head to http://invite.textmaybe.com/?pin=8CDFJUH to join up."
    return messageComposeVC
  }
  
  // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
  func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
}