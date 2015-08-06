//
//  AboutViewController.swift
//  thisbeit
//
//  Created by Kyle Murphy on 8/5/15.
//  Copyright (c) 2015 Kyle Murphy. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
  @IBOutlet weak var webV: UIWebView!
  @IBAction func tapClose(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load the BullsEye.html file into the web view.
    if let htmlFile = NSBundle.mainBundle().pathForResource("about", ofType: "html") {
      let htmlData = NSData(contentsOfFile: htmlFile)
      let baseURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath)
      webV.loadData(htmlData, MIMEType: "text/html", textEncodingName: "UTF-8", baseURL: baseURL)
    }
  }
  
}

