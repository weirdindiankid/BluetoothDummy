//
//  OTAViewController.swift
//  BluetoothDummy
//
//  Created by Dharmesh Tarapore on 8/22/16.
//  Copyright © 2016 Alessandro BABINI. All rights reserved.
//

import Foundation
import UIKit

class OTAViewController: UIViewController {
    
    // IBActions and IBOutlets
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func otaButtonPressed(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("OTAViewController view did load")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
