//
//  Records.swift
//  Catbox
//
//  Created by Curt Rowe on 22/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let recordUpdateNotification = Notification.Name(rawValue:"com.zetcho.recordUpdate")

enum RecordSort {
    case alphabetical
    case added
    case recorded
}

class Records: RailsData {
    // Make it a singleton
    static let shared = Records()

    //var labels = Labels.shared
    var currentOrder = ""
    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable() {
        if isLoaded == true { return }
        let rest = "records"
        currentOrder = "name"
        super.loadRailsTable(rest: rest)
        dispatchGroup.wait()
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "records"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: recordWasAdded)
    }
    //################################################################################################
    func recordWasAdded(row: [String: Any]?) {
        var key = -1
        if let name = row?["name"] as? String {
            for (index, record) in super.table.enumerated() {
                if name <= record["name"] as! String {
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
            nc.post(name: recordUpdateNotification,
                object: row,
                userInfo: ["type": "add"])
        }
        else {
            print("Records: JSON missing name: ", row as Any)
        }
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "records/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: recordWasUpdated)
    }
    //################################################################################################
    func recordWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, record) in super.table.enumerated() {
            if record["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:recordUpdateNotification,
                object: row,
                userInfo:["type":"add"])
        }
        else {
            print("Tracks: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "records/" + row
        super.deleteRailsRow(rest: rest, completionHandler: recordWasDeleted, roundTrip: row)
        dispatchGroup.wait()
    }
    //################################################################################################
    func recordWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let value = roundTrip as? String {
            let rowID = Int(value)
            for (index, record) in super.table.enumerated() {
                if record["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: recordUpdateNotification,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("recordWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("recordWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func filterRecordsByLabel(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        loadTable()

        for record in super.table {
            if record["label_id"] as? Int == id {
                filteredRows.append(super.getRow(id: record["id"] as! Int))
            }
        }
        return filteredRows
    }
    //################################################################################################
/*    func orderRows(order: String) {
        var rest: String = ""
        if order == "recent" {
            rest = "records/recent"
            currentOrder = "recent"
        }
        else {
            print("unknown order sent to orderRows")
        }
        super.loadRailsTable(rest: rest)
        //super.orderRailsTable(rest: rest!, completionHandler: completionHandler)
        dispatchGroup.wait()
    }*/
    //################################################################################################
    func order(by: RecordSort) {

        switch by {
            case RecordSort.alphabetical:
                table.sort { ($0["name"] as! String) < ($1["name"] as! String) }
            case RecordSort.added:
                table.sort { ($0["date_added"] as! String) > ($1["date_added"] as! String) }
            case RecordSort.recorded:
                table.sort { ($0["recording_year"] as! String) < ($1["recording_year"] as! String) }
        }
    }
}
