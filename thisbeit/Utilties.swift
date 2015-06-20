//
//  Utilties.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

func showSimpleAlertWithTitle(title: String!, #message: String, #viewController: UIViewController) {
  let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
  let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
  alert.addAction(action)
  viewController.presentViewController(alert, animated: true, completion: nil)
}