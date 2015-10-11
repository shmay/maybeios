//
//  Utilties.swift
//  thisbeit
//
//  Created by Kyle Murphy on 6/19/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit
var currentUser: User?

func showSimpleAlertWithTitle(title: String!, message: String, viewController: UIViewController, onok: (() -> Void)?) {
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
  let re = try! NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
  let matches = re.matchesInString(text, options: [], range: NSRange(location: 0, length: text.utf16.count))
  
  var collectMatches: Array<String> = []
  for match in matches {
    // range at index 0: full match
    // range at index 1: first capture group
    let substring = (text as NSString).substringWithRange(match.rangeAtIndex(1))
    collectMatches.append(substring)
  }
  return collectMatches
}

func postRequest(path: String, params: Dictionary<String, String>, success: (resp: NSDictionary?) -> Void, errorCb: () -> Void) {
  let url = NSURL(string: "\(serverURL)/\(path)")
  let request = NSMutableURLRequest(URL: url!)
  let session = NSURLSession.sharedSession()
  request.HTTPMethod = "POST"

  print("url: \(url?.absoluteString)")
  
  do {
    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
  } catch let error as NSError {
    print(error)
    request.HTTPBody = nil
  }
  
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.addValue("application/json", forHTTPHeaderField: "Accept")

  let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
    print("Response: \(response)")
    let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
    print("Body: \(strData)")
    
    do {
      if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
        success(resp: json)
        // Okay, the parsedJSON is here, let's get the value for 'success' out of it
        let success = json["success"] as? Int
        print("Succes: \(success)")
      } else {
        // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
        let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
        print("Error could not parse JSON: \(jsonStr)")
      }
    } catch {
      print(error)
      let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
      errorCb()
      print("Error could not parse JSON: '\(jsonStr)'")
    }
    
  })

  task.resume()
}