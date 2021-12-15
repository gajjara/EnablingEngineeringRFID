#include "Arduino.h"
#include "Bluetooth.h"

HardwareSerial s = HardwareSerial(2);
String oldRecieved = "";
String recieved = "";

void setup() {
    // put your setup code here, to run once:
    Serial.begin(115200);
    s.begin(115200);
    Bluetooth::initialize();
    delay(500);
    Bluetooth::transmit("Hello iPhone");
}

void loop() {
    // put your main code here, to run repeatedly:
    if(s.available() > 0) {
        while(s.available() > 0) {
            char r = s.read();
            recieved += r;
        }
        Serial.println("Read Tag " + recieved);
        Bluetooth::transmit(recieved);
        recieved = "";
    }
    /*
    if(Serial.available() > 0) { 
        recieved = Serial.readString(); 
        if(oldRecieved != recieved) {
            Serial.println("RxUART " + recieved);
            Bluetooth::transmit(recieved);
        }
    }
    */
    /*
    if (Serial.available() > 0) { 
        String r = Serial.readString();
        Bluetooth::transmit(r);
    }
    */
    delay(500);
    Bluetooth::recieve();
    delay(500);
}
