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
 * @date        2020-07-29
 * @version     3.0   
 */

#include "Bluetooth.h"

namespace Bluetooth {    
    BLEServer *server = NULL;
    BLECharacteristic *charTx = NULL;
    BLECharacteristic *charRx = NULL;
    unsigned long starttime = 0;
    unsigned long endtime = 0;
    bool connection = false;
    String rx = "";

    void ServerCallbacks::onConnect(BLEServer *pServer) {
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

    void tx(String value) {
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

    void transmit(String type, String item, Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo) {
        String value = "";
        if (type == TRANSMIT) {
            // Generate transmit format string
            value = TRANSMIT + ":";
            
            // Add courseinfo item
            if (item == COURSEINFO) value = value + courseinfo.toString();
            // Add holeinfo item
            else if (item == HOLEINFO) value = value + holeinfo.toString();
            // Add round info item
            else if (item == ROUNDINFO) value = value + roundinfo.toString();
        }
        else {
            // Generate REQUEST type
            value = type + ":" + "Item:" + item + ";";
        }
        // Transmit the value through tx characteristic
        tx(value);
    }

    void recieve(Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo) {
        // Update rx
        std::string value = charRx->getValue();
        String temp = value.c_str();
        if(temp != rx) {
            rx = temp;
            String val = rx;
            Serial.println("Rx: " + val);
            
            // Process string
            if (contains(val, TRANSMIT)) {
                // Process a transmit
                processTransmit(val, courseinfo, holeinfo, roundinfo);
            }
            else if (contains(val, REQUEST)) {
                // Process a request, and transmit back requested value
                if (contains(val, COURSEINFO)) transmit(TRANSMIT, COURSEINFO, courseinfo, holeinfo, roundinfo);
                else if (contains(val, HOLEINFO)) transmit(TRANSMIT, HOLEINFO, courseinfo, holeinfo, roundinfo);
                else if (contains(val, ROUNDINFO)) transmit(TRANSMIT, ROUNDINFO, courseinfo, holeinfo, roundinfo);
            }
        }
    }

    String itemAndValue(String values, String item) {
        // Try-catch for exception handling
        try {
            // Find the item in the string
            String tofind = item + ":";
            int findlen = tofind.length();
            int loc1 = values.indexOf(tofind);

            // Create substring with the value of the item (and the rest of values string)
            int cutloc = loc1 + findlen;
            String sub = values.substring(cutloc); 

            // Identify where a ';' seperator occurs (indicates end of value)
            // This based on the data format specified for DiscTracker
            int loc2 = sub.indexOf(";") + cutloc;

            // Return the item and value
            String itemandval = values.substring(loc1,loc2);
            return itemandval;
        }
        catch(...) {
            // Return a blank string if an exception occurs
            return "";
        }
    }

    String value(String values, String item) {
        try {
            // Get item and value
            String itemandvalue = itemAndValue(values,item);
            // Return value
            return itemandvalue.substring(item.length()+1);
        }
        catch(...) { 
            // Return a blank string if an exception occurs
            return "";
        }
    }

    bool contains(String str1, String str2) {
        // Get index of str2 in str1  
        int index = str1.indexOf(str2);

        // If index is within range of indices for str1, then str1 contains str2
        if(index >= 0 && index < str1.length()) return true;
        else return false;
    }

    int toInt(String value) {
        // Try catch in case parsing fails
        try {
            return value.toInt();
        }
        catch(...) { 
            // Return 0 if parsing fails
            return 0; 
        }
    }

    int* toIntArray(String value) {
        // Convert Arduino String to std::string 
        std::string s = value.c_str();
        
        // Allocate and initialize array
        int *arr = (int*)malloc(sizeof(int)*ARRSIZE);
        for(int i = 0; i < ARRSIZE; i=i+1) arr[i] = 0;

        // Split string by commas
        char sep = ',';
        int counter = 0;
        for(size_t p=0, q=0; p!=s.npos; p=q) {
            std::string temp = s.substr(p+(p!=0), (q=s.find(sep, p+1))-p-(p!=0));
            // Populate array
            arr[counter] = toInt(temp.c_str());
            counter = counter + 1;
        }
        return arr;
    }

    void processTransmit(String transmit, Objects::CourseInfo &courseinfo, Objects::HoleInfo &holeinfo, Objects::RoundInfo &roundinfo) {
        // Take out TRANSMIT tag
        String cut = TRANSMIT + ":";
        int index = transmit.indexOf(cut);
        String values = transmit.substring(index + (cut.length()));

        // Get item type, (i.e. CourseInfo, HoleInfo, RoundInfo)
        String item = value(values, "Item");
        if (contains(item, COURSEINFO)) {
            // Parse values
            courseinfo.par = toInt(value(values, "par"));
            courseinfo.holes = toInt(value(values, "holes"));
            courseinfo.distance = toInt(value(values, "distance"));
            courseinfo.coursename = value(values, "coursename");
            courseinfo.newcourse = false;
        }
        else if (contains(item, HOLEINFO)) {
            int hole = toInt(value(values, "hole"));

            // Notify new hole
            if (hole != holeinfo.hole && (holeinfo.hole == 0)) {
                // Parse values
                holeinfo.hole = hole;
                holeinfo.par = toInt(value(values, "par"));
                holeinfo.strokes = toInt(value(values, "strokes"));
                holeinfo.throws = toInt(value(values, "throws"));
                holeinfo.distance = toInt(value(values, "distance"));
                holeinfo.putdistance = toInt(value(values, "putdistance"));
                holeinfo.selection = value(values, "selection");
            }
        }
        else if (contains(item, ROUNDINFO)) {
            // Free pars, distances, throws, strokes, putdistances
            if(roundinfo.pars != NULL && roundinfo.distances != NULL && roundinfo.throws != NULL && roundinfo.strokes != NULL && roundinfo.putdistances != NULL) {
                free(roundinfo.pars);
                free(roundinfo.distances);
                free(roundinfo.throws);
                free(roundinfo.strokes);
                free(roundinfo.putdistances);
            }

            // Parse values
            roundinfo.pars = toIntArray(value(values,"pars"));
            roundinfo.distances = toIntArray(value(values,"distances"));
            roundinfo.throws = toIntArray(value(values, "throws"));
            roundinfo.strokes = toIntArray(value(values, "strokes"));
            roundinfo.putdistances = toIntArray(value(values, "putdistances"));
        }
    }
}