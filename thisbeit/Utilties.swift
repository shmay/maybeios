//
//  Utilties.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
var currentUser: User?

func showSimpleAlertWithTitle(title: String!, #message: String, #viewController: UIViewController, #onok: (() -> Void)?) {
  let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
  let action = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
    if let ok = onok {
      ok()
    }
  })
  alert.addAction(action)
  viewController.presentViewController(alert, animated: true, completion: nil)
}

func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}

func showAlert(msg: String) {
  let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
  let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
  alertController.addAction(okAction)
  
  
  if var topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
    while let presentedViewController = topController.presentedViewController {
      topController = presentedViewController
    }
    
    topController.presentViewController(alertController, animated: true, completion: nil)
  }
  
}

func showAlert(msg: String, forController controller: UIViewController) {
  let alertController = UIAlertController(title: nil, message: msg, preferredStyle: .Alert)
  let okAction = UIAlertAction(title: "OK", style: .Default,handler: nil)
  alertController.addAction(okAction)

  controller.presentViewController(alertController, animated: true, completion: nil)
}

func regexMatches(pattern: String, text: String) -> Array<String> {
  let re = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)!
  let matches = re.matchesInString(text, options: nil, range: NSRange(location: 0, length: count(text.utf16)))
  
  var collectMatches: Array<String> = []
  for match in matches as! Array<NSTextCheckingResult> {
    // range at index 0: full match
    // range at index 1: first capture group
    let substring = (text as NSString).substringWithRange(match.rangeAtIndex(1))
    collectMatches.append(substring)
  }
  return collectMatches
}

func postRequest(path: String, params: Dictionary<String, String>, success: (resp: NSDictionary?) -> Void, errorCb: () -> Void) {
  let url = NSURL(string: "\(serverURL)/\(path)")
  var request = NSMutableURLRequest(URL: url!)
  var session = NSURLSession.sharedSession()
  request.HTTPMethod = "POST"

  var err: NSError?
  println("url: \(url?.absoluteString)")
  request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.addValue("application/json", forHTTPHeaderField: "Accept")

  var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
    println("Response: \(response)")
    var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
    println("Body: \(strData)")
    var err: NSError?
    var json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as? NSDictionary

    // Did the JSONObjectWithData constructor return an error? If so, log the error to the console
    if(err != nil) {
      println(err!.localizedDescription)
      let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
      errorCb()
      println("Error could not parse JSON: '\(jsonStr)'")
    } else {
      // The JSONObjectWithData constructor didn't return an error. But, we should still
      // check and make sure that json has a value using optional binding.
      if let parseJSON = json {
        success(resp: json)
        // Okay, the parsedJSON is here, let's get the value for 'success' out of it
        var success = parseJSON["success"] as? Int
        println("Succes: \(success)")
      }
      else {
        // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
        let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
        println("Error could not parse JSON: \(jsonStr)")
      }
    }
  })

  task.resume()
}