//
//  Compostions.swift
//  jazzcat
//
//  Created by Curt Rowe on 26/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let compositionUpdateNotification = Notification.Name(rawValue:"com.zetcho.compositionUpdated")

class Compositions: RailsData {
    // Make it a singleton
    static let shared = Compositions()

    //################################################################################################
    private override init() {

    } //Prevents the use of the default '()' initializer for this class.
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "compositions"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "compositions"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: compositionWasAdded)
    }
    //################################################################################################
    func compositionWasAdded(row: [String: Any]?) {
        var key = -1
        if let name = row?["name"] as? String {
            for (index, composition) in super.table.enumerated() {
                if name <= composition["name"] as! String {
                    key = index
                    break
                }
            }
            // If key is unchanged, the name is greater than any in the table.
            // Append it to the end
            if key == -1 {
                super.table.append(row!)
            }
            else {
                super.table.insert(row!, at: key)
            }
            let nc = NotificationCenter.default
            nc.post(name: compositionUpdateNotification,
                object: row,
                userInfo: ["type": "add"])
        }
        else {
            print("Compositions: JSON missing name: ", row as Any)
        }
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "compositions/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: compositionWasUpdated)
    }
    //################################################################################################
    func compositionWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, composition) in super.table.enumerated() {
            if composition["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:compositionUpdateNotification,
                object: row,
                userInfo:["type":"update"])
        }
        else {
            print("Compositions: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "compositions/" + row
        super.deleteRailsRow(rest: rest, completionHandler: compositionWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func compositionWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let value = roundTrip as? String {
            let rowID = Int(value)
            for (index, composition) in super.table.enumerated() {
                if composition["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: compositionUpdateNotification,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("compositionWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("compositionWasDeleted: no roundTrip data")
        }
    }
}
