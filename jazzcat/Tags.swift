//
//  Tags.swift
//  jazzcat
//
//  Created by Curt Rowe on 13/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

//let tagUpdateNotification = Notification.Name(rawValue:"com.zetcho.trackTagUpdated")

class Tags: RailsData {
    var routing: String!
    var notifier: Notification.Name!
    //################################################################################################
    //private override init() {

    //} //Prevents the use of the default '()' initializer for this class.
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        //let rest = "track_tags"
        let rest = routing!
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        //let rest = "track_tags"
        let rest = routing!
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: rowWasAdded)
        dispatchGroup.wait()
    }
    //################################################################################################
    func rowWasAdded(row: [String: Any]?) {
        var key = -1
        //var firstName: String!
        guard let name = row?["name"] as? String else {
            print("TrackTags: JSON missing name: ", row as Any)
            return
        }
        //if let name = row?["name"] as? String {
            for (index, tag) in super.table.enumerated() {
                if name <= tag["name"] as! String {
                    key = index
                    break
                }
            }
        //}
        // If key is unchanged, the name is greater than any in the table.
        // Append it to the end
        if key == -1 {
            super.table.append(row!)
        }
        else {
            super.table.insert(row!, at: key)
        }
        let nc = NotificationCenter.default
        //nc.post(name:trackTagUpdateNotification,
        nc.post(name:notifier,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        //let rest = "track_tags/" + row
        let rest = routing! + "/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: rowWasUpdated)
    }
    //################################################################################################
    func rowWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, trackTag) in super.table.enumerated() {
            if trackTag["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            //nc.post(name:trackTagUpdateNotification,
            nc.post(name:notifier,
                object: row,
                userInfo:["type":"add", "date":Date()])
        }
        else {
            print("Tracks: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        //let rest = "track_tags/" + row
        let rest = routing! + "/" + row
        super.deleteRailsRow(rest: rest, completionHandler: rowWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func rowWasDeleted(roundTrip: Any? = nil) {
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
                //nc.post(name: trackTagUpdateNotification,
                nc.post(name:notifier,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("trackTagWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("trackTagWasDeleted: no roundTrip data")
        }
    }
}
