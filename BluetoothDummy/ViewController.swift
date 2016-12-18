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
    return Int(Date().timeIntervalSince1970)
}


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate {
    
    // User access token
    let accessToken: String = "ulJs1l1dRa1EHwrvuPJ1b8wV+LF2we0c3BXOxOmlyX6s9Fi2qQQSG3IetXJm8Vw5RCK5eNOaXhZ0nnCopcXILw=="

    // Keeps track of how long we have been scanning
    var scanTimer: Timer = Timer()
    
    // Logs sensor values
    var sensorDataValues: String = ""
    
    // Keeps track of the preferred peripheral name
    let peripheralName: String = "HumonB"
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    
    
    
    @IBAction func recordButtonPressed(_ sender: AnyObject) {
        
        if gPeripheral != nil && gPeripheral.state == CBPeripheralState.connected {
            
            if !isRecording {
                sensorDataValues = ""
                isRecording = true
                recordButton.setTitle("Recording", for: UIControlState())
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
    
    @IBAction func connectButtonPressed(_ sender: AnyObject) {
        
        if nameField.text != nil && nameField.text != "" {
            // If not connected, attempt to connect
            if !isDeviceConnected {
                
                gCentralManager = CBCentralManager(delegate: self, queue: nil)
                gCentralManager.delegate = self
                allowInteraction(false)
                connectButton.setTitle("Connecting", for: UIControlState())
                connectionStatusLabel.text = ""
                scanTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ViewController.stopScanning), userInfo: nil, repeats: false)
            }
        } else {
            BSXData.text = "Name cannot be blank."
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        if gPeripheral != nil && gPeripheral.state == CBPeripheralState.connected {
            gCentralManager.cancelPeripheralConnection(gPeripheral)
        }
        gPeripheral = nil
        connectionStatusLabel.text = "Not Connected"
        connectButton.setTitle("Connect", for: UIControlState())
        isDeviceConnected = false
        BSXData.text = ""
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOff {
                print("Powered off Bluetooth")
            }
            else if central.state == CBManagerState.poweredOn {
                print("Powered on and now looking for new devices")
                gCentralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered perihperal: \(peripheral)")
        //
        if peripheral.name == peripheralName { //"insight" {
            self.allowInteraction(true)
            scanTimer.invalidate()
            gCentralManager.stopScan()
            gPeripheral = peripheral
            gPeripheral.delegate = self
            print("Stop scanning and connect")
            gCentralManager.connect(gPeripheral, options: nil)
        }
    }
    
    func allowInteraction(_ status: Bool) -> Void {
        if status == true {
            if UIApplication.shared.isIgnoringInteractionEvents {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
        } else {
            if !UIApplication.shared.isIgnoringInteractionEvents {
                UIApplication.shared.beginIgnoringInteractionEvents()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Now connected to peripheral: \(peripheral.name)")
        isDeviceConnected = true
        connectionStatusLabel.text = ""
        self.sensorDataValues = ""
        connectButton.setTitle("Disconnect", for: UIControlState())
        gPeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected ")
        self.invalidateConnection()
    }
    // Peripheral methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("Discovered services: \(peripheral.services)")
        for service in peripheral.services! {
            print("Discovered service: \(service.description)")
            //if service.UUID == CBUUID(string: "180A") {
                print("Discovering characteristics")
                peripheral.discoverCharacteristics(nil, for: service)
            //}
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics: \(service.characteristics)")
        for characteristic in service.characteristics! {
            //print("Discovered characteristic: \(characteristic)")
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let datastring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        print("data received: \(datastring)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
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
    func generateRequest(_ dict: NSDictionary, urlExtension: String) -> NSMutableURLRequest? {
        
        let accessToken: String = "ulJs1l1dRa1EHwrvuPJ1b8wV+LF2we0c3BXOxOmlyX6s9Fi2qQQSG3IetXJm8Vw5RCK5eNOaXhZ0nnCopcXILw=="
        
        let urlString = API_SITE + urlExtension
        let url = URL(string: urlString)
        
        let request = NSMutableURLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 600)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token token=\(accessToken)", forHTTPHeaderField: "Authorization")
        //request.setValue(String(json.length), forHTTPHeaderField: "Content-length")
        //request.HTTPBody = json
        
        return request
    }
}



