//
//  Artists.swift
//  Catbox
//
//  Created by Curt Rowe on 22/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let artistUpdateNotification = Notification.Name(rawValue:"com.zetcho.artistUpdated")

class Artists: RailsData {
    // Make it a singleton
    static let shared = Artists()
    //################################################################################################
    private override init() {

    } //Prevents the use of the default '()' initializer for this class.
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "artists"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "artists"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: artistWasAdded)
        dispatchGroup.wait()
    }
    //################################################################################################
    func artistWasAdded(row: [String: Any]?) {
        var key = -1
        var firstName: String!
        guard let lastName = row?["last_name"] as? String else {
            print("Artists: JSON missing last name: ", row as Any)
            return
        }
        // first_name can be null. Replace with a space whist sort before all letters
        firstName = row?["first_name"] as? String
        if firstName == nil {
            firstName = " "
        }
        for (index, artist) in super.table.enumerated() {
            if lastName < artist["last_name"] as! String {
                key = index
                break
            }
            if lastName == artist["last_name"] as! String {
                if firstName <= artist["first_name"] as! String {
                    key = index
                    break
                }
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
        nc.post(name:artistUpdateNotification,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "artists/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: artistWasUpdated)
    }
    //################################################################################################
    func artistWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, artist) in super.table.enumerated() {
            if artist["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:artistUpdateNotification,
                object: row,
                userInfo:["type":"add", "date":Date()])
        }
        else {
            print("Tracks: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "artists/" + row
        super.deleteRailsRow(rest: rest, completionHandler: artistWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func artistWasDeleted(roundTrip: Any? = nil) {
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
                nc.post(name: artistUpdateNotification,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("artistWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("artistWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func parseName(fullName: String) -> Dictionary<String, String> {
        let nameParts = fullName.components(separatedBy: " ")
        var parsedName: Dictionary<String, String> = [:]
        parsedName["first_name"] = nameParts[0]
        if nameParts.count > 1 {
            parsedName["last_name"] = nameParts[1]
        }
        return parsedName
    }
}
