//
//  ViewController.swift
//  EnablingEngineeringBLETest
//
//  Created by Anuj Gajjar on 10/26/21.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    var synthesizer: AVSpeechSynthesizer!
    var bluetooth: Bluetooth!
    var prevTx: String! = ""
    var prevTag: String! = ""
    var epcMessages: [String: String]! = [
        "E200001D960801852620A1F0": "Entrance turn right for coffe and pastries, and turn left for all the other groceries",
        "E200001D96080161262087C8": "Floral on your right side, produce on your left side, and go straight for other groceries",
        "E200001D960802312650D263": "Fresh fruit and veggies are on your left side, dairy aisle is on your right side",
        "E200001D9608015326207F08": "Baking aisle is on your right side, and cereals are on your left",
        "E200001D960802092640BB20": "Apple Jacks, Boo Berry, and Crispix are on your right.",
        "E200001D960802192640CAED": "Tag 6, Turn Left",
        "E200001D960802032640BB1D": "Tag 7, Turn Left",
        "E200001D9608016026207FF8": "Tag 8, Turn Left",
        "E200001D9608017126209939": "Tag 9, Turn Right",
        "E200001D9608015226207738": "Tag 10, Turn Right",
        "E200001D960801972620B2DE": "Tag 11, Turn Right",
        "E200001D960802282640CB42": "Tag 12, Turn Right",
        "E200001D960802342640D28":  "Tag 13",
        "E200001D960801792620A1ED": "Tag 14, Go Backward",
        "E200001D960802332640D25C": "Tag 15, Go Backward",
        "E200001D960802272640D259": "Tag 16, Go Backward",
        "E200001D960802302650CB3F": "Tag 17, Go Backward",
        "E200001D960802052650BB26": "Tag 18",
        "E200001D9608017026209175": "Tag 19",
    ]
    
    @IBOutlet var rxTextLabel: UITextView!
    @IBOutlet var txTextField: UITextField!
    @IBOutlet var connectionLabel: UITextView!
    
    @IBAction func sendVal() {
        let text: String = txTextField.text!
        if text != self.prevTx {
            self.tx(value: text)
            self.prevTx = text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // View setup
        self.rxTextLabel.font = rxTextLabel.font?.withSize(20)
        
        // Text to speech setup
        do {
              try AVAudioSession.sharedInstance().setCategory(.playback)
           } catch(let error) {
               print(error.localizedDescription)
           }
        self.synthesizer = AVSpeechSynthesizer()
        
        // Bluetooth setup
        self.bluetooth = Bluetooth()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {timer in
            self.connectionLabel.text = String(self.bluetooth.connected)
            self.recieve()
        }
    }
}

// Text to speech extension
extension ViewController {
    /**
     Speaks a string value
     
     - Parameter string: the String to utter
     
     - Returns: Void
     */
    func speak(string: String) {
        let utterance = AVSpeechUtterance(string: string)
        self.synthesizer.speak(utterance)
    }
}

// Bluetooth Extension
extension ViewController {
    /**
    Transmit string through tx BLE characteristic.

    - Parameter value: Transmit string through tx BLE characteristic
     
    - Returns: Void
    */
    func tx(value: String) {
        self.bluetooth.writeValue(val: value)
        print("Tx: " + value)
    }
    
    /**
    Recieving function for bluetooth.

    - Parameter Void
     
    - Returns: Void
    */
    func recieve() {
        if(self.bluetooth.informRx) {
            // Update recieved value
            let val = self.bluetooth.rx
            
            let parsed = self.parseRawEPC(string: val)
            if parsed != "" {
                if parsed != prevTag {
                    let message = self.epcMessages[parsed]
                    self.rxTextLabel.text = message
                    if message != nil {
                        self.speak(string: message!)
                    }
                    prevTag = parsed
                }
            }
            self.bluetooth.informRx = false
        }
    }
    
    /**
    Function parses a string with Raw EPC strings.
     
     - Parameter string: a String containing raw EPC strings
     
     - Returns: String
     */
    func parseRawEPC(string: String!) -> String {
        // Split EPC strings by spaces
        guard let components = string.split(separator: " ") as [Substring]? else {
            return ""
        }
        // Split EPC strings by endline characters
        guard let components1 = components[0].split(separator: "\r\n") as [Substring]? else {
            return ""
        }
        // Get back the first EPC string
        guard let result = String(components1[0]) as String?  else {
            return ""
        }
        return result
    }
}
