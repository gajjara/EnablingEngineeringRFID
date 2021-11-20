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
    var epcMessages: [String: String]! = [
        "E200001D960801852620A1F0":"Tag 1",
        "E200001D96080161262087C8": "Tag 2",
        "E200001D960802312650D263": "Tag 3",
        "E200001D9608015326207F08": "Tag 4",
        "E200001D960802092640BB20": "Tag 5",
        "E200001D960802192640CAED": "Tag 6",
        "E200001D960802032640BB1D": "Tag 7",
        "E200001D9608016026207FF8": "Tag 8",
        "E200001D9608017126209939": "Tag 9",
        "E200001D9608015226207738": "Tag 10",
        "E200001D960801972620B2DE": "Tag 11",
        "E200001D960802282640CB42": "Tag 12",
        "E200001D960802342640D28":  "Tag 13",
        "E200001D960801792620A1ED": "Tag 14",
        "E200001D960802332640D25C": "Tag 15",
        "E200001D960802272640D259": "Tag 16",
        "E200001D960802302650CB3F": "Tag 17",
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
        utterance.pitchMultiplier = 0.25
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
            //print("Rx: " + val)
            self.rxTextLabel.text = val
            
            let parsed = self.parseRawEPC(string: val)
            if parsed != "" {
                let message = self.epcMessages[parsed]
                self.rxTextLabel.text = message
                if message != nil {
                    self.speak(string: message!)
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
