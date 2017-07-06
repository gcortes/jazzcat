//
//  Influences.swift
//  jazzcat
//
//  Created by Curt Rowe on 9/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let influenceUpdateNotification = Notification.Name(rawValue:"com.zetcho.influenceUpdated")

class Influences: RailsData {
    // Make it a singleton
    static let shared = Influences()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "influences"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "influences"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: influenceWasAdded)
        dispatchGroup.wait()
    }
    //################################################################################################
    func influenceWasAdded(row: [String: Any]?) {
        super.table.append(row!)
        let nc = NotificationCenter.default
        nc.post(name:influenceUpdateNotification,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "influences/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: influenceWasUpdated)
    }
    //################################################################################################
    func influenceWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        var key = -1
        for (index, influence) in super.table.enumerated() {
            if influence["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:influenceUpdateNotification,
                object: row,
                userInfo:["type":"add", "date":Date()])
        }
        else {
            print("Influences: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "influences/" + row
        let id = Int(row)
        super.deleteRailsRow(rest: rest, completionHandler: influenceWasDeleted, roundTrip: id as Any)
    }
    //################################################################################################
    func influenceWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let rowID = roundTrip as? Int {
        //if let value = roundTrip as? String {
            //let rowID = Int(value)
            for (index, label) in super.table.enumerated() {
                if label["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: influenceUpdateNotification,
                    //object: [ "id": roundTrip ],
                    object: [ "id": rowID ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("influenceWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("influenceWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func filterByInfluence(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // load table in case it hasn't been loaded. If it has, the function returns immediately
        loadTable()

        for row in super.table {
            if row["influence_id"] as? Int == id {
                filteredRows.append(super.getRow(id: row["id"] as! Int))
            }
        }
        return filteredRows
    }
    //################################################################################################
    func filterByInfluencee(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // load table in case it hasn't been loaded. If it has, the function returns immediately
        loadTable()

        for row in super.table {
            if row["influencee_id"] as? Int == id {
                filteredRows.append(super.getRow(id: row["id"] as! Int))
            }
        }
        return filteredRows
    }
}
