//
//  ViewController.swift
//  BluetoothDummy
//
//  Created by Alessandro BABINI on 1/26/16.
//  Copyright © 2016 Alessandro BABINI. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

let API_SITE = "http://humon.co/api/v1"

// Global peripherals
var gPeripheral: CBPeripheral!

var gCentralManager: CBCentralManager!

// Keeps track of recording status
var isRecording: Bool = false

var Timestamp: Int {
    return Int(NSDate().timeIntervalSince1970)
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate {
    
    // User access token
    let accessToken: String = "ulJs1l1dRa1EHwrvuPJ1b8wV+LF2we0c3BXOxOmlyX6s9Fi2qQQSG3IetXJm8Vw5RCK5eNOaXhZ0nnCopcXILw=="

    // Keeps track of how long we have been scanning
    var scanTimer: NSTimer = NSTimer()
    
    // Logs sensor values
    var sensorDataValues: String = ""
    
    // Keeps track of the preferred peripheral name
    let peripheralName: String = "HumonB"
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    
    
    
    @IBAction func recordButtonPressed(sender: AnyObject) {
        
        if gPeripheral != nil && gPeripheral.state == CBPeripheralState.Connected {
            
            if !isRecording {
                sensorDataValues = ""
                isRecording = true
                recordButton.setTitle("Recording", forState: .Normal)
            } else {
                // Save data here
                self.saveData()
            }
        } else {
            BSXData.text = "Name cannot be blank."
        }
      
    }
    
    // Setup IBOutlets and IBActions here
    @IBOutlet weak var connectButton: UIButton!
    
    // Displays connection status
    
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    
    @IBOutlet weak var BSXData: UILabel!
    
    @IBAction func connectButtonPressed(sender: AnyObject) {
        
        if nameField.text != nil && nameField.text != "" {
            // If not connected, attempt to connect
            if !isDeviceConnected {
                
                gCentralManager = CBCentralManager(delegate: self, queue: nil)
                gCentralManager.delegate = self
                allowInteraction(false)
                connectButton.setTitle("Connecting", forState: .Normal)
                connectionStatusLabel.text = ""
                scanTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ViewController.stopScanning), userInfo: nil, repeats: false)
            } else {
                self.saveData()
                self.invalidateConnection()
            }
        } else {
            BSXData.text = "Name cannot be blank."
        }
        
    }
    
    // Save data locally until a wireless network connection becomes available
    func saveLocally() -> Void {
        print("Save locally")
        
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let entity =  NSEntityDescription.entityForName("BSXData", inManagedObjectContext:managedContext)
        
        let valuesToSave = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        let myValues = String(self.sensorDataValues)
        
        //3
        valuesToSave.setValue(myValues, forKey: "humonSensorData")
        
        if nameField.text != nil && nameField.text != "" {
            valuesToSave.setValue(nameField.text!, forKey: "username")
        } else {
            valuesToSave.setValue("UsernameBlank", forKey: "username")
        }
        
        //4
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        // Regardless of whether or not this action succeeds, if we can't save locally, discard the data and move on.
        self.sensorDataValues = ""
    }
    
    // Save Signal Strength
    func saveData() -> Void {
        
        isRecording = false
        recordButton.setTitle("Record", forState: .Normal)
        
        if sensorDataValues.characters.count > 1 {
            
            // Check if we have a WiFi connection
            // To check for WiFi connection
            let reachability: Reachability
            do {
                reachability = try Reachability.reachabilityForInternetConnection()
                
                if reachability.isReachable() {
                    print("WiFi connection available")
                    
                    // Begin packaging data into meaningful format
                    let humonSensorValues: NSMutableDictionary = NSMutableDictionary()
                    humonSensorValues["sensor_values"] = sensorDataValues
                    if nameField.text != nil && nameField.text != "" {
                        humonSensorValues["user"] = nameField.text
                    } else {
                        humonSensorValues["user"] = "UsernameBlank"
                    }
                    
                    // Upload to the backend here
                    self.uploadToAWS(humonSensorValues)
                }
                else {
                    self.saveLocally()
                }
                
            } catch {
                print("Unable to create Reachability")
                // Save locally
                self.saveLocally()
            }
            
        }
        
        
        
        
    }
    
    // Upload to the backend
    func uploadToAWS(bsxLogs: NSDictionary) -> Void {
        
        let urlExtension: String = "/betalogs"
        var request: NSMutableURLRequest? = NSMutableURLRequest()
        
        request = request!.generateRequest(bsxLogs, urlExtension: urlExtension)
        
        if request != nil {
            
            print("Request is not nil. Upload here.")
            self.uploadAsynchronously(bsxLogs, request: request!)
            
        }
        else {
            print("Request is nil.")
        }
    }
    
    // Upload in a background thread
    func uploadAsynchronously(bsxLogs: NSDictionary, request: NSURLRequest) -> Void {
        
        let session = NSURLSession.sharedSession()
        var uploadData: NSData? = NSData()
        
        if NSJSONSerialization.isValidJSONObject(bsxLogs) {
            
            do {
                
                uploadData =  try NSJSONSerialization.dataWithJSONObject(bsxLogs, options: NSJSONWritingOptions(rawValue: 0))
                if uploadData != nil {
                    
                    session.uploadTaskWithRequest(request, fromData: uploadData, completionHandler: { (uploadResponseData, uploadResponse, uploadError) -> Void in
                        if uploadError == nil && uploadResponse != nil && String(data: uploadResponseData!, encoding: NSUTF8StringEncoding) == "1" {
                            
                            print("Upload succeeded -- clearing values here")
                            self.sensorDataValues = ""
                        }
                        else {
                            // An error occurred -- save locally
                            print("Error --failed upload. Saving locally.")
                            self.saveLocally()
                            
                        }
                    }).resume()
                }
                else {
                    
                    print("uploadData is nil")
                    self.saveLocally()
                }
                
            } catch {
                print("Failed upload asynchronously -- saving locally")
                self.saveLocally()
            }
        }
        else {
            print("Not valid serialization.")
        }
        
    }
    
    // This keeps track of our connection
    var isDeviceConnected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("BluetoothDummy did load")
        
        self.nameField.delegate = self
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    func dismissKeyboard() -> Void {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stopScanning() {
        // Stop scanning
        gCentralManager.stopScan()
        // Alert here that the connection did not work
        connectionStatusLabel.text = "Not found"
        // Stop timer
        scanTimer.invalidate()
        
        self.invalidateConnection()
        
    }
    
    func invalidateConnection() -> Void {
        
        allowInteraction(true)
        if gPeripheral != nil && gPeripheral.state == CBPeripheralState.Connected {
            gCentralManager.cancelPeripheralConnection(gPeripheral)
        }
        gPeripheral = nil
        connectionStatusLabel.text = "Not Connected"
        connectButton.setTitle("Connect", forState: .Normal)
        isDeviceConnected = false
        BSXData.text = ""
        
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOff {
            print("Powered off Bluetooth")
        }
        else if central.state == CBCentralManagerState.PoweredOn {
            print("Powered on and now looking for new devices")
            gCentralManager.scanForPeripheralsWithServices(nil, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Discovered perihperal: \(peripheral)")
        //
        if peripheral.name == peripheralName { //"insight" {
            self.allowInteraction(true)
            scanTimer.invalidate()
            gCentralManager.stopScan()
            gPeripheral = peripheral
            gPeripheral.delegate = self
            print("Stop scanning and connect")
            gCentralManager.connectPeripheral(gPeripheral, options: nil)
        }
    }
    
    func allowInteraction(status: Bool) -> Void {
        if status == true {
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        } else {
            if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Now connected to peripheral: \(peripheral.name)")
        isDeviceConnected = true
        connectionStatusLabel.text = ""
        self.sensorDataValues = ""
        connectButton.setTitle("Disconnect", forState: .Normal)
        gPeripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Failed")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected ")
        self.saveData()
        self.invalidateConnection()
    }
    // Peripheral methods
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        //print("Discovered services: \(peripheral.services)")
        for service in peripheral.services! {
            print("Discovered service: \(service.description)")
            //if service.UUID == CBUUID(string: "180A") {
                print("Discovering characteristics")
                peripheral.discoverCharacteristics(nil, forService: service)
            //}
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Discovered characteristics: \(service.characteristics)")
        for characteristic in service.characteristics! {
            //print("Discovered characteristic: \(characteristic)")
            peripheral.readValueForCharacteristic(characteristic)
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        //var datastring = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        if let betaData = characteristic.value {
            var betaDataVals = arrayFromData(betaData)
            betaDataVals.insert(Timestamp, atIndex: 0)
            if isRecording {
                BSXData.text = "Connected and recording."
                // Record data
                sensorDataValues += "\(betaDataVals)"
            } else {
                BSXData.text = "Connected."
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        connectionStatusLabel.text = "RSSI: \(RSSI)"
        // print("Received Signal Strength Indicator: \(RSSI)")
        if isRecording {
            // Record here
            // rssiValues.append(RSSI)
        }
    }
    
    
}

extension NSMutableURLRequest {
    
    // generates all the requests to the server and converts stuff to JSON
    func generateRequest(dict: NSDictionary, urlExtension: String) -> NSMutableURLRequest? {
        
        let accessToken: String = "ulJs1l1dRa1EHwrvuPJ1b8wV+LF2we0c3BXOxOmlyX6s9Fi2qQQSG3IetXJm8Vw5RCK5eNOaXhZ0nnCopcXILw=="
        
        let urlString = API_SITE.stringByAppendingString(urlExtension)
        let url = NSURL(string: urlString)
        
        let request = NSMutableURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 600)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token token=\(accessToken)", forHTTPHeaderField: "Authorization")
        //request.setValue(String(json.length), forHTTPHeaderField: "Content-length")
        //request.HTTPBody = json
        
        return request
    }
}



