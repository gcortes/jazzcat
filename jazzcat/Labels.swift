//
//  Labels.swift
//  jazzcat
//
//  Created by Curt Rowe on 24/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let labelUpdateNotification = Notification.Name(rawValue:"com.zetcho.labelUpdated")

class Labels: RailsData {
    // This class is a singleton
    static let shared = Labels()
    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "labels"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "labels"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: labelWasAdded)
        dispatchGroup.wait()
    }
    //################################################################################################
    func labelWasAdded(row: [String: Any]?) {
        var key = -1
        if let name = row?["name"] as? String {
            for (index, label) in super.table.enumerated() {
                if name <= label["name"] as! String {
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
            nc.post(name:labelUpdateNotification,
                object: row,
                userInfo:["type":"add"])
        }
        else {
            print("Labels: JSON missing name: ", row as Any)
        }
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "labels/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: labelWasUpdated)
    }
    //################################################################################################
    func labelWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, label) in super.table.enumerated() {
            if label["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:labelUpdateNotification,
                object: row,
                userInfo:["type":"update"])
        }
        else {
            print("Labels: error Handling label update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "labels/" + row
        super.deleteRailsRow(rest: rest, completionHandler: labelWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func labelWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let value = roundTrip as? String {
            let rowID = Int(value)
            for (index, label) in super.table.enumerated() {
                if label["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: labelUpdateNotification,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("labelWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("labelWasDeleted: no roundTrip data")
        }
    }
}
