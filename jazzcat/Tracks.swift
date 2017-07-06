//
//  Tracks.swift
//  jazzcat
//
//  Created by Curt Rowe on 27/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let trackUpdateNotification = Notification.Name(rawValue:"com.zetcho.trackUpdated")

class Tracks: RailsData {
    // Make it a singleton
    static let shared = Tracks()

    let compositions = Compositions.shared

    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "flatTracks"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "tracks"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: trackWasAdded)
    }
    //################################################################################################
    func trackWasAdded(row: [String: Any]?) {
        //print("track.trackWasAdded - row: ", row)
        // The tracks are unsorted so just append it to the end
        super.table.append(row!)
        let nc = NotificationCenter.default
        nc.post(name:trackUpdateNotification,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "tracks/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: trackWasUpdated)
        //dispatchGroup.wait()
    }
    //################################################################################################
    func trackWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        //print("trackWasUpdated row: ", row)
        guard let updatedRow = row,
              let id = updatedRow["id"] as? Int
        else {
            print("trackWasUpdated: missing or invalid id in row: ", row as Any)
            return
        }
        var key = -1
        for (index, track) in super.table.enumerated() {
            if track["id"] as! Int == id {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name: trackUpdateNotification,
                object: row,
                userInfo: ["type": "add", "date": Date()])
        }
        else {
            print("Tracks: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "tracks/" + row
        super.deleteRailsRow(rest: rest, completionHandler: trackWasDeleted, roundTrip: row)
    }
    //################################################################################################
    func trackWasDeleted(roundTrip: Any? = nil) {
        //print("tracks.trackWasDeleted - roundTrip: ", roundTrip as Any)
        var rowID = -1
        var key = -1
        if let id = roundTrip as? String {
            rowID = Int(id)!
            for (index, track) in super.table.enumerated() {
                if track["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: trackUpdateNotification,
                    object: [ "id": rowID ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("trackWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("trackWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    // The tracks rows are just used to get the record title and recording date.
    func filterTracksByComposition(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        loadTable()
        //labels.loadTable()

        for track in super.table {
            if track["composition_id"] as? Int == id {
                filteredRows.append(super.getRow(id: track["id"] as! Int))
            }
        }
        return filteredRows
    }
    //################################################################################################
    func filterTracksByRecord(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // Make sure they are loaded
        loadTable()
        compositions.loadTable()

        for track in super.table {
            if track["record_id"] as? Int == id {
                //var filterTrack = super.getRow(id: track["id"] as! Int)
                //filterTrack["composition_name"] = compositions.table[filterTrack["composition_id"]["composition_name"]]
                filteredRows.append(super.getRow(id: track["id"] as! Int))
            }
        }
        if filteredRows.count > 1 {
            filteredRows.sort { ($0["disk"] as! Int, $0["track"] as! Int) <
                ($1["disk"] as! Int, $1["track"] as! Int)  }
        }
        return filteredRows
    }
    //################################################################################################
    func getPersistentID(persistentID: String) -> [String:Any]? {
        //var dummy: [String: Any] = [:]
        for track in super.table {
            if let trackPersistentID = track["persistent_id"] as? String {
                if trackPersistentID == persistentID {
                    return track
                }
            }
        }
        return nil
    }
}
