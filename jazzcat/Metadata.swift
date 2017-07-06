//
//  Metadata.swift
//  jazzcat
//
//  Created by Curt Rowe on 6/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let metadataUpdateNotification = Notification.Name(rawValue:"com.zetcho.metadataUpdated")

class Metadata: RailsData {
    // Make it a singleton
    //static let shared = TrackMetadata()
    var routing: String!
    var notifier: Notification.Name!
    //################################################################################################
    //init() {
    // Overridden by child
    //}
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
        super.table.append(row!)
        let nc = NotificationCenter.default
        //nc.post(name:metatdataTagUpdateNotification,
        nc.post(name:notifier,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        //let rest = "track_tags/" + row
        let rest = routing + "/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: rowWasUpdated)
    }
    //################################################################################################
    func rowWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, tableRow) in super.table.enumerated() {
            if tableRow["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            //nc.post(name:metadataTagUpdateNotification,
            nc.post(name:notifier,
                object: row,
                userInfo:["type":"add", "date":Date()])
        }
        else {
            print("Metadata: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        //let rest = "track_tags/" + row
        let rest = routing + "/" + row
        super.deleteRailsRow(rest: rest, completionHandler: rowWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func rowWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let value = roundTrip as? String {
            let rowID = Int(value)
            for (index, tableRow) in super.table.enumerated() {
                if tableRow["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                //nc.post(name: metadataUpdateNotification,
                nc.post(name:notifier,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("metadataWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("metaTagWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func filterByType(id: Int, filterType: String) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // load table in case it hasn't been loaded. If it has, the function returns immediately
        loadTable()

        for row in super.table {
            if row[filterType] as? Int == id {
                filteredRows.append(super.getRow(id: row["id"] as! Int))
            }
        }
        return filteredRows
    }
}
