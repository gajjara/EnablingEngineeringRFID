
/**
 * File: Bluetooth.cpp
 * Language: C++ with C++ Compatible C Code
 * Standard: GNU++11
 * 
 * @brief
 * Is the Bluetooth cpp file.
 * Defines all the necessary objects and functions
 * for Bluetooth transmission and recieving.
 * 
 * @author      Anuj Gajjar
 * @date        2021-10-26
 * @version     1.0
 */

#include "Bluetooth.h"

namespace Bluetooth {    
    BLEServer *server = NULL;
    BLECharacteristic *charTx = NULL;
    BLECharacteristic *charRx = NULL;
    bool connection = false;
    String rx = "";

    void ServerCallbacks::onConnect(BLEServer *pServer) {
        Serial.println("Connected");
        connection = true;
    }

    void ServerCallbacks::onDisconnect(BLEServer *pServer) {
        connection = false;
    }
    
    void Callbacks::onWrite(BLECharacteristic *characteristic) {
        // Do Nothing
    }
        
    void initialize() {
        // Bluetooth Initialize
        BLEDevice::init("ESP32");

        // Initialize server
        server = BLEDevice::createServer();
        server->setCallbacks(new ServerCallbacks());
        BLEService *service = server->createService(SERVICE_UUID);

        // Init Characteristics
        charTx = 
            service->createCharacteristic(TX_UUID, BLECharacteristic::PROPERTY_NOTIFY);
        charTx->addDescriptor(new BLE2902());
        charRx = 
            service->createCharacteristic(RX_UUID, BLECharacteristic::PROPERTY_WRITE);
        charRx->setCallbacks(new Callbacks());

        // Start
        service->start();
        server->getAdvertising()->start();
    }

    void transmit(String value) {
        // Try catch to catch exceptions
        try {
            // Write to CharTx and notify
            charTx->setValue(value.c_str());
            charTx->notify(); 
            Serial.println("Tx: " + value);
        } 
        catch(...) {
            Serial.println("Error Writing"); 
        }
    }

    void recieve() {
        // Update rx
        std::string value = charRx->getValue();
        String temp = value.c_str();
        //Serial.println("Rx: " + temp);
        if(temp != rx) {
            rx = temp;
            Serial.println("Rx: " + rx);
        }
    }
}
