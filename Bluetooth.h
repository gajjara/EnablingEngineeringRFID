/**
 * File: Bluetooth.h
 * Language: C/C++ Header
 * Standard: GNU++11 
 * 
 * @brief
 * Is the Bluetooth header file.
 * Declares all the necessary objects and functions
 * for Bluetooth transmission and recieving.
 * 
 * @author      Anuj Gajjar
 * @date        2021-10-26
 * @version     1.0
 */

// IMPORTS
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Define header file
#ifndef BLUETOOTH_H
#define BLUETOOTH_H

// BLUETOOTH UUIDs //
#define SERVICE_UUID "741ec900-e00f-4fdd-92f2-508f0a916a6b" // BLE Service UUID
#define RX_UUID "0bad1b5c-130d-4df4-9f56-8ea7afb52222"  // Recieving UUID
#define TX_UUID "2b679569-93b8-41fa-b237-fcc41bdb13cf"  // Transmiting UUID
#define TIMEOUT 5000      // Timeout time

namespace Bluetooth {
    // BLE Server pointer
    extern BLEServer *server;
    // BLE Characteristic for transmission
    extern BLECharacteristic *charTx;
    // BLE Characteristic for recieving
    extern BLECharacteristic *charRx;
    
    // Boolean for verifying bluetooth connection
    extern bool connection;

    // String for holding recieved value (From Rx BLE Characteristic)
    extern String rx;

    // Server Callbacks class
    class ServerCallbacks: public BLEServerCallbacks {
        void onConnect(BLEServer *pServer);

        void onDisconnect(BLEServer *pServer);
    };
  
    // BLE Callbacks class
    class Callbacks: public BLECharacteristicCallbacks {
        void onWrite(BLECharacteristic *characteristic);
    };

    /**
     * Initializes the Bluetooth server, and the servers services and characteristics.
     * 
     * @param void
     * @return void
     */ 
    void initialize();

    /**
     * Transmits an Arduino String using the TX BLE Characteristic.
     * 
     * @param value the value to transmit
     * @return void
     */ 
    void transmit(String value);

    /**
     * Recieving function for bluetooth.
     * Handles a TRANSMIT or REQUEST type basd on the DiscTracker data format.
     * Needs references to the (DiscTracker) structs to be modified/acessed.
     * 
     * @return void
     */
    void recieve();
}

#endif
