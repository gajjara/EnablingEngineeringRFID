//
//  Bluetooth.swift
//  DiscTrackerTest
//
//  Created by Anuj Gajjar on 5/1/20.
//  Copyright © 2020 Anuj Gajjar. All rights reserved.
//

// Imports
import CoreBluetooth

/// Class to handle bluetooth connection, transmission, recieving
class Bluetooth: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    /// Initalizer
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Service UUID
    private let serviceUUID = CBUUID(string: "741ec900-e00f-4fdd-92f2-508f0a916a6b")
    // Recieving UUID (Transmission UUID on ESP32)
    private let rxUUID = CBUUID(string: "2b679569-93b8-41fa-b237-fcc41bdb13cf")
    // Transmission UUID (Recieving UUID on ESP32)
    private let txUUID = CBUUID(string: "0bad1b5c-130d-4df4-9f56-8ea7afb52222")
    
    // BT Central Manager
    private var centralManager: CBCentralManager!
    // Peripheral
    public var myPeripheral: CBPeripheral!
    // Transmission characteristic
    private var txChar: CBCharacteristic!
    // Recieving characteristic
    private var rxChar: CBCharacteristic!
    
    // Boolean to inform connection
    public var connected = false
    public var informRx = false
    
    // Recieving string
    public var rx = ""
    private var rxOld = ""

    // Handle an updated state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE powered on")
            // Turned on
            central.scanForPeripherals(withServices: nil, options: nil)
        }
        else {
            print("Something wrong with BLE")
            connected = false
        }
    }
    
    // Handle peripheral discovery
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        if let pname = peripheral.name {
            print("Discovered peripheral: " + pname)
            if pname.contains("ESP") {
                self.centralManager.stopScan()
                
                self.myPeripheral = peripheral
                self.myPeripheral?.delegate = self
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    // Handle connection to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        connected = true
        self.myPeripheral?.discoverServices(nil)
    }
    
    // Handle disconnection to peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        connected = false
        self.centralManager.connect(myPeripheral, options: nil)
    }
    
    // Discover peripheral services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            // Discover characteristics in services
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Discover characteristics and discover their properties
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
        print(characteristic)
        // Find characteristic to write to
        if characteristic.properties.contains(.write) {
            print("\(characteristic.uuid): properties contains .write")
            peripheral.setNotifyValue(true, for: characteristic)
            self.txChar = characteristic
        }
        // Find characteristic to recieve values from
        if characteristic.properties.contains(.notify) {
            print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic)
            self.rxChar = characteristic
        }
      }
    }
    
    // Handle characteristic values update
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        // If recieving characteristic, update value
        case self.rxUUID:
            rx = readValue()
            if(rxOld != rx) {
                print("Rx: " + rx)
                rxOld = rx
                informRx = true
            }
        // Handle error/extranoues case
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
      }
    }
    
    // Handle writing to a characteristic
    func peripheral(_ peripheral: CBPeripheral,
    didWriteValueFor characteristic: CBCharacteristic,
               error: Error?)
    {
        // Handle error in writing (don't need to write directly)
        if let error = error {
            print("error: \(error)")
            return
        }
    }
    
    /**
    Write a value to the transmitting characteristic.
     
    - Parameter val: the vlaue to write
     
    - Returns: Void
    */
    func writeValue(val: String) {
        if(myPeripheral != nil && txChar != nil) {
            //print("Writing: " + val)
            self.myPeripheral.writeValue(val.data(using: .utf8)!, for: self.txChar, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    /**
    Read a value from the transmitting characteristic (call when characteristic updates value)
     
    - Parameter Void
     
    - Returns: The string of the value recieved
    */
    func readValue() -> String {
        if(myPeripheral != nil && rxChar != nil && txChar != nil) {
            // Handle any nil values with guard
            guard let data = self.rxChar.value ?? "null".data(using: .utf8)
                else { return "" }
            return String(decoding: data, as: UTF8.self)
        }
        // Return if peripheral, rxChar, or txChar are not functioning
        else {
            return ""
        }
    }
}
