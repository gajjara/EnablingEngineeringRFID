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
 * @date        2020-07-29
 * @version     3.0   
 */

// IMPORTS
#include "Constants.h"
#include "Objects.h"
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

    // Unsigned long to hold a start time for timeout counting
    extern unsigned long starttime;
    // Unsigned long to hold an end time for timeout counting
    extern unsigned long endtime;
    
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
    void tx(String value);
    
    /**
     * Transmits values based on the data format for DiscTracker.
     * Transmits a TRANSMIT or REQUEST type with a COURSEINFO, ROUNDINFO, or HOLEINFO item.
     * Needs references to the (DiscTracker) structs to be modified/acessed.
     * 
     * @param type the type specifier for a transmission
     * @param item the item specifier for a transmission
     * @param courseinfo the CourseInfo struct object
     * @param holeinfo the HoleInfo struct object
     * @param roundinfo the RoundInfo struct object
     * @return void
     */
    void transmit(String type, String item, Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo);

    /**
     * Recieving function for bluetooth.
     * Handles a TRANSMIT or REQUEST type basd on the DiscTracker data format.
     * Needs references to the (DiscTracker) structs to be modified/acessed.
     * 
     * @param courseinfo the CourseInfo struct object
     * @param holeinfo the HoleInfo struct object
     * @param roundinfo the RoundInfo struct object
     * @return void
     */
    void recieve(Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo);

    /**
     * Process item and value from a string containing various values
     * 
     * @param values the set of various values
     * @param item the item to identify
     * @return a string containing the item identifier and its value
     */
    String itemAndValue(String values, String item);

    /**
     * Process value from a string containing various values
     * Processing based on data format for DiscTracker
     * 
     * @param values the set of various values
     * @param item the item to obtain the value from
     * @return a string containing the value of the item
     */ 
    String value(String values, String item);

    /**
     * Check if a string contains a substring
     * 
     * @param str1 the string
     * @param str2 the substring
     * @return true if str1 contains str2, false if not
     */ 
    bool contains(String str1, String str2);

    /**
     * String to Int
     * 
     * @param value the String
     * @return the parsed integer of the string, if parsing fails, then 0
     */
    int toInt(String value);

    /**
     * String (seperated by commas) to Int
     * Seperation by commas occurs based on the data format for DiscTracker
     * 
     * @param value the String
     * @return pointer to an array of size specified by ARRSIZE
     */ 
    int* toIntArray(String value);

    /**
     * Process a TRANSMIT type value that is recieved.
     * This populates the CourseInfo, HoleInfo, and RoundInfo struct.
     * Needs references to the (DiscTracker) structs to be modified/acessed.
     * 
     * @param transmit the TRANSMIT type values recieved
     * @param courseinfo the CourseInfo struct object
     * @param holeinfo the HoleInfo struct object
     * @param roundinfo the RoundInfo struct object
     * @return void
     */ 
    void processTransmit(String transmit, Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo);
}

#endif