//
//  ViewController.swift
//  DiscTrackerTest
//
//  Created by DiscTracker on 5/1/20.
//  Copyright © 2020 DiscTracker. All rights reserved.
//
// NOTE: Code structure here is similar to the DiscTracker
// C++/Arduino code

// Imports
import UIKit
import CoreBluetooth

// Bluetooth types and items
let TRANSMIT = "TRANSMIT";
let REQUEST = "REQUEST";
let COURSEINFO = "CourseInfo";
let HOLEINFO = "HoleInfo";
let ROUNDINFO = "RoundInfo";

/// Struct to hold course info
struct CourseInfo {
    /// Course total par
    var par: Int
    /// Course total holes
    var holes: Int
    /// Course total distance
    var distance: Int
    /// Course name
    var coursename: String
}
/// Extension to generate course info description
extension CourseInfo: CustomStringConvertible {
    /// CourseInfo description
    var description: String {
        return  "Item:" + COURSEINFO +
                ";par:" + String(par) +
                ";holes:" + String(holes) +
                ";distance:" + String(distance) +
                ";coursename:" + coursename + ";"
    }
}

/// Struct to hold hole info
struct HoleInfo {
    /// Current hole
    var hole: Int
    /// Par at current hole
    var par: Int
    /// Current strokes
    var strokes: Int
    /// Current strokes
    var _throws: Int
    /// Hole distance
    var distance: Int
    /// Hole putdistance
    var putdistance: Int
    /// Previous selection
    var selection: String
}
/// Extension to generate hole info description
extension HoleInfo: CustomStringConvertible {
    /// HoleInfo description
    var description: String {
        return  "Item:" + HOLEINFO +
                ";hole:" + String(hole) +
                ";par:" + String(par) +
                ";strokes:" + String(strokes) +
                ";throws:" + String(_throws) +
                ";distance:" + String(distance) +
                ";putdistance:" + String(putdistance) +
                ";selection:" + selection + ";"
    }
}

/// Struct to hold round info
struct RoundInfo {
    /// Round pars (each array value is for each hole)
    var pars: [Int]
    /// Round distances (each array value is for each hole)
    var distances: [Int]
    /// Round throws (each array value is for each hole)
    var _throws: [Int]
    /// Round strokes (each array value is for each hole)
    var strokes: [Int]
    /// Round putdistances (each array value is for each hole)
    var putdistances: [Int]
}
/// Extension to generate round info description
extension RoundInfo: CustomStringConvertible {
    /**
    Return an array parsed as a string.
    This string adheres to the DiscTracker data fromat.
     
    - Parameter arr: the array to be parsed as a string
     
    - Returns: The array parsed as a string
    */
    func arrToString(arr: [Int]) -> String {
        var toreturn = ""
        var counter = 0
        for item in arr {
            toreturn = toreturn + String(item)
            counter = counter + 1
            if(counter < arr.count) {
                toreturn = toreturn + ","
            }
        }
        toreturn = toreturn + ";"
        return toreturn
    }
    /// RoundInfo description
    var description: String {
        return  "Item:" + ROUNDINFO + ";" +
            "pars:" + arrToString(arr: pars) +
                "distances:" + arrToString(arr: distances) +
                    "throws:" + arrToString(arr: _throws) +
                        "strokes:" + arrToString(arr: strokes) +
                            "putdistances:" + arrToString(arr: putdistances)
    }
}

/// View Controller
class ViewController: UIViewController {
    // Bluetooth class enable
    var bluetooth: Bluetooth!
    
    // Structs init
    var courseinfo = CourseInfo(par: 10, holes: 3, distance: 100, coursename: "DiscGolf")
    var holeinfo = HoleInfo(hole: 1, par: 0, strokes: 0, _throws: 1, distance: 0, putdistance: 0, selection: "")
    var roundinfo = RoundInfo(pars: [3,4,3], distances: [40,30,30], _throws: [0], strokes: [0], putdistances: [0])

    // Labels for showing values
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var courseNameLabel: UILabel!
    @IBOutlet var courseParLabel: UILabel!
    @IBOutlet var courseHolesLabel: UILabel!
    @IBOutlet var courseDistanceLabel: UILabel!
    @IBOutlet var holeHoleLabel: UILabel!
    @IBOutlet var holeParLabel: UILabel!
    @IBOutlet var holeStrokesLabel: UILabel!
    @IBOutlet var holeThrowsLabel: UILabel!
    @IBOutlet var holeDistanceLabel: UILabel!
    @IBOutlet var holeSelectionLabel: UILabel!
        
    /// Class initializer
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init bluetooth
        self.bluetooth = Bluetooth()
        
        // On a loop, recieve values and update labels
        Timer.scheduledTimer(withTimeInterval: 0, repeats: true) {timer in
            self.recieve()
            self.updateLabels()
        }
    }

    /**
    Update the UILabels based on the current status of app/ESP32

    - Parameter Void
     
    - Returns: Void
    */
    func updateLabels() {
        // Update connection label
        if(self.bluetooth.connected == true) {
            self.statusLabel.text = "Status: Connected"
        }
        else {
            self.statusLabel.text = "Status: Disconnected"
        }
        
        // Update course info labels
        self.courseNameLabel.text = "Course Name: " + courseinfo.coursename
        self.courseParLabel.text = "Par: " + String(courseinfo.par)
        self.courseHolesLabel.text = "Holes: " + String(courseinfo.holes)
        self.courseDistanceLabel.text = "Distance: " + String(courseinfo.distance)
        
        // Update hole info labels
        self.holeHoleLabel.text = "Hole: " + String(holeinfo.hole)
        self.holeParLabel.text = "Par: " + String(holeinfo.par)
        self.holeStrokesLabel.text = "Strokes: " + String(holeinfo.strokes)
        self.holeThrowsLabel.text = "Throws: " + String(holeinfo._throws)
        self.holeDistanceLabel.text = "Distance: " + String(holeinfo.distance)
        self.holeSelectionLabel.text = "Selection: " + holeinfo.selection
        
        // Update round info labels
        //self.roundThrowsLabel.text = "Throws: " + holeinfo.hole.description
        //self.roundStrokesLabel.text = "Strokes: " + holeinfo.hole.description
        //self.roundDistanceLabel.text = "Put Distances: " + holeinfo.hole.description
    }
}

/// Bluetooth Extension to View controller
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
    Transmits values based on the data format for DiscTracker.
    Transmits a TRANSMIT or REQUEST type with a COURSEINFO, ROUNDINFO, or HOLEINFO item.
     
    - Parameter type: the type specifier for a transmission
    - Parameter item: the item specifier for a transmission
     
    - Returns: Void
    */
    func transmit(type: String, item: String) {
        var value = ""
        // Generate TRANSMIT type
        if(type == TRANSMIT) {
            value = TRANSMIT + ":"
            // Add item, and append item description
            
            if(item == COURSEINFO) {
                value = value + courseinfo.description
            }
            else if(item == HOLEINFO) {
                value = value + holeinfo.description
            }
            else if(item == ROUNDINFO) {
                value = value + roundinfo.description
            }
        }
        // Generate REQUEST type
        else {
            value = type + ":" + "Item:" + item + ";"
        }
        // Transmit value
        tx(value: value)
    }
    
    /**
    Recieving function for bluetooth.
    Handles a TRANSMIT or REQUEST type basd on the DiscTracker data format.

    - Parameter Void
     
    - Returns: Void
    */
    func recieve() {
        if(self.bluetooth.informRx) {
            // Update recievde value
            let val = self.bluetooth.rx
            //print("Rx: " + val)
            
            // Process transmit
            if(val.contains(TRANSMIT)) {
                self.processTransmit(transmit: val)
            }
            // Handle request by sending back requested item
            else if(val.contains(REQUEST)) {
                //print(val)
                if(val.contains(COURSEINFO)) {
                    transmit(type: TRANSMIT, item: COURSEINFO)
                }
                else if(val.contains(HOLEINFO)) {
                    transmit(type: TRANSMIT, item: HOLEINFO)
                }
                else if(val.contains(ROUNDINFO)) {
                    transmit(type: TRANSMIT, item: ROUNDINFO)
                }
            }
            
            self.bluetooth.informRx = false
        }
    }
    
    /**
    Process a TRANSMIT type value that is recieved.
    This populates the CourseInfo, HoleInfo, and RoundInfo struct

    - Parameter transmit: the TRANSMIT type values recieved
     
    - Returns: Desc
    */
    func processTransmit(transmit: String) {
        // Find TRANSMIT component of string and cut out
        var cut = "TRANSMIT:"
        var indexint = indexOf(string: transmit, value: cut)
        var index = toStringIndex(string: transmit, index: indexint)
        
        // Generate substring removing TRANSMIT tag
        let all = String(transmit[index...])
        
        // Parse CourseInfo information
        if(all.contains(COURSEINFO)) {
            // Parse substring removing CourseInfo tag
            cut = "Item:CourseInfo"
            indexint = indexOf(string: all, value: cut)
            index = toStringIndex(string: all, index: indexint)
            let courseinfo = String(all[index...])
            
            // Parse values
            self.courseinfo.par = parseInt(string: Value(values: courseinfo,item: "par"))
            self.courseinfo.holes = parseInt(string: Value(values: courseinfo,item: "holes"))
            self.courseinfo.distance = parseInt(string: Value(values: courseinfo, item: "distance"))
            self.courseinfo.coursename = Value(values: courseinfo, item: "coursename");
        }
        // Parse HoleInfo information
        else if(all.contains(HOLEINFO)) {
            // Parse substring removing HoleInfo tag
            cut = "Item:HoleInfo"
            indexint = indexOf(string: all, value: cut)
            index = toStringIndex(string: all, index: indexint)
            let holeinfo = String(all[index...])
            
            // Parse values
            self.holeinfo.hole = parseInt(string: Value(values: holeinfo, item: "hole"));
            self.holeinfo.par = parseInt(string: Value(values: holeinfo, item: "par"));
            self.holeinfo.strokes = parseInt(string: Value(values: holeinfo, item: "strokes"));
            self.holeinfo._throws = parseInt(string: Value(values: holeinfo, item: "throws"));
            self.holeinfo.distance = parseInt(string: Value(values: holeinfo, item: "distance"));
            self.holeinfo.putdistance = parseInt(string: Value(values: holeinfo, item: "putdistance"));
            self.holeinfo.selection = Value(values: holeinfo, item: "selection");
        }
        // Parse RoundInfo information
        else if(all.contains(ROUNDINFO)) {
            // Parse substring removing RoundInfo tag
            cut = "Item:RoundInfo"
            indexint = indexOf(string: all, value: cut)
            index = toStringIndex(string: all, index: indexint)
            let roundinfo = String(all[index...])
            
            // Parse values (but catch any exceptions)
            do {
                self.roundinfo.pars = try parseIntArray(string: Value(values: roundinfo, item: "pars"));
                self.roundinfo.distances = try parseIntArray(string: Value(values: roundinfo, item: "distances"));
                self.roundinfo._throws = try parseIntArray(string: Value(values: roundinfo, item: "throws"));
                self.roundinfo.strokes = try parseIntArray(string: Value(values: roundinfo, item: "strokes"));
                self.roundinfo.putdistances = try parseIntArray(string: Value(values: roundinfo, item: "putdistances"));
            }
            catch {}
        }
    }
}

/// Bluetooth Processing Extension to View controller
extension ViewController {
    /**
    Process value from a string containing various values.
    Processing based on data format for DiscTracker.
     
    - Parameter values: the set of various values
    - Parameter item: the item to obtain the value from
     
    - Returns: a string containing the value of the item
    */
    func Value(values: String, item: String) -> String {
        // Cut string and find index
        let tofind = item + ":"
        let findlen = tofind.count
        let loc1 = indexOf(string: values, value: tofind)
        let cutloc = loc1 + findlen
        let index1 = toStringIndex(string: values, index: cutloc)
        
        // Generate substring containing only the value
        let sub = values[index1...]
        
        // Cut string and find next ";"
        let loc2 = indexOf(string: String(sub), value: ";") + cutloc
        let index2 = toStringIndex(string: values, index: loc2)
        let range = index1..<index2
        
        // Return the value
        return String(values[range])
    }
    
    /**
    Parse integer from a String.

    - Parameter string: The string containing th einteger to parse
     
    - Returns: the string parsed as an integer, otherwise 0 if parsing fails
    */
    func parseInt(string: String) -> Int {
        return Int(string) ?? 0
    }
    
    /**
    String (seperated by commas) to Int array
    Seperation by commas occurs based on the data format for DiscTracker

    - Parameter string: The string to parse to an array

    - Throws: NSError if parsing of array fails
     
    - Returns: The string parsed as an integer array
    */
    func parseIntArray(string: String) throws -> [Int] {
        let strArray = string.components(separatedBy: ",")
        //print(strArray.description)
        let intArray = try strArray.map {
            (int:String)->Int in
            guard Int(int) != nil else {
                throw NSError.init(domain:  " \(int) is not digit", code: -99, userInfo: nil)
            }
            return Int(int)!
        }
        return intArray
    }

}

/// String processing extension to ViewController
extension ViewController {
    /**
    Returns the integer index of a substring (index based on string being a char array)
     within another string.

    - Parameter string: the string
    - Parameter value: the substring
     
    - Returns: The integer index of the substring in the string, otherwise -1 if the substring does not exist in the string
    */
    func indexOf(string: String, value: String) -> Int {
        if let range: Range<String.Index> = string.range(of: value) {
            let index: Int = string.distance(from: string.startIndex, to: range.lowerBound)
            return index
        }
        else {
            return -1
        }
    }
    
    /**
    Parses the string index based on an integer index.

    - Parameter string: the string to get an index from
    - Parameter index: the integer index
    - Parameter item: Desc
     
    - Returns: The parsed string index
    */
    func toStringIndex(string: String, index: Int) -> String.Index {
        return string.index(string.startIndex, offsetBy: index)
    }
}
