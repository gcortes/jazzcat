//
//  Credits.swift
//  jazzcat
//
//  Created by Curt Rowe on 27/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let creditUpdateNotification = Notification.Name(rawValue:"com.zetcho.creditUpdated")

class Credits: RailsData {
    // Make it a singleton
    static let shared = Credits()

    let artists = Artists.shared
    let records = Records.shared
    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "credits"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "credits"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: creditWasAdded)
    }
    //################################################################################################
    func creditWasAdded(row: [String: Any]?) {
        // The credit table is not sorted so just add to the end
        super.table.append(row!)

        let nc = NotificationCenter.default
        nc.post(name:creditUpdateNotification,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "credits/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: creditWasUpdated)
    }
    //################################################################################################
    func creditWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, credit) in super.table.enumerated() {
            if credit["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:creditUpdateNotification,
                object: row,
                userInfo:["type":"update"])
        }
        else {
            print("Credits: error Handling track update: ", row ?? "row is empty", " table count: ", super.table.count)
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "credits/" + row
        super.deleteRailsRow(rest: rest, completionHandler: creditWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func creditWasDeleted(roundTrip: Any? = nil) {
        var rowID = -1
        var key = -1
        if let value = roundTrip as? String {
            rowID = Int(value)!
            for (index, credit) in super.table.enumerated() {
                if credit["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: creditUpdateNotification,
                    object: [ "id": rowID ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("creditWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("creditWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func filterCreditsByArtist(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // Make sure the tables are loaded
        loadTable()
        artists.loadTable()
        records.loadTable()

        for credit in super.table {
            if credit["artist_id"] as? Int == id {
                var filterRow = credit
                let record = records.getRow(id: credit["record_id"] as! Int)
                filterRow["record_name"] = record["name"]
                filterRow["recording_year"] = record["recording_year"]
                let artist = artists.getRow(id: record["artist_id"] as! Int)
                filterRow["leader_name"] = artist["name"]
                filteredRows.append(filterRow)
            }
        }
        if filteredRows.count > 1 {
            filteredRows.sort { ($0["recording_year"] as! String) < ($1["recording_year"] as! String)  }
        }
        return filteredRows
    }
    //################################################################################################
    func filterCreditsByRecord(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        loadTable()
        artists.loadTable()

        for credit in super.table {
            if credit["record_id"] as? Int == id {
                var filterRow = credit
                let artist = artists.getRow(id: credit["artist_id"] as! Int)
                filterRow["artist_name"] = artist["name"]
                filteredRows.append(filterRow)
                //filteredRows.append(super.getRow(id: credit["id"] as! Int))
            }
        }
        /*if filteredRows.count > 1 {
            filteredRows.sort { ($0["disk"] as! Int, $0["track"] as! Int) <
                ($1["disk"] as! Int, $1["track"] as! Int)  }
        }*/
        return filteredRows
    }
}
