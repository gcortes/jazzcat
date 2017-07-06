//
//  Composers.swift
//  jazzcat
//
//  Created by Curt Rowe on 29/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let composerUpdateNotification = Notification.Name(rawValue:"com.zetcho.composerUpdated")

class Composers: RailsData {
    // Make it a singleton
    static let shared = Composers()

    let compositions = Compositions.shared
    let artists = Artists.shared

    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "composers"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "composers"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: composerWasAdded)
        dispatchGroup.wait()
    }
    //################################################################################################
    func updateRowAndNotify(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil) {
        let rest = "composers/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: composerWasUpdated)
    }
    //################################################################################################
    // The composer table is not sorted nor displayed.
    func composerWasAdded(row: [String: Any]?) {
        // Append it to the end
        super.table.append(row!)
        let nc = NotificationCenter.default
        nc.post(name:composerUpdateNotification,
            object: row,
            userInfo:["type":"add"])
    }
    //################################################################################################
    func composerWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        print("composerWasUpdated - row: ", row as Any)
        var key = -1
        for (index, composer) in super.table.enumerated() {
            if composer["id"] as! Int == row?["id"] as! Int {
                key = index
                break
            }
        }
        if key >= 0 {
            super.table[key] = row!
            let nc = NotificationCenter.default
            nc.post(name:composerUpdateNotification,
                object: row,
                userInfo:["type":"add", "date":Date()])
        }
        else {
            print("Composers: error Handling track update")
        }
    }
    //################################################################################################
    func deleteRowAndNotify(row: String) {
        let rest = "composers/" + row
        super.deleteRailsRow(rest: rest, completionHandler: composerWasDeleted, roundTrip: row)
        dispatchGroup.wait()
    }
    //################################################################################################
    func composerWasDeleted(roundTrip: Any? = nil) {
        var key = -1
        if let value = roundTrip as? String {
            let rowID = Int(value)
            for (index, composer) in super.table.enumerated() {
                if composer["id"] as? Int == rowID {
                    key = index
                    break
                }
            }
            if key >= 0 {
                super.table.remove(at: key)
                let nc = NotificationCenter.default
                nc.post(name: composerUpdateNotification,
                    object: [ "id": roundTrip ],
                    userInfo: ["type": "delete"])
            }
            else {
                print("composerWasDeleted: deleted row not found in dictionary")
            }
        }
        else {
            print("composerWasDeleted: no roundTrip data")
        }
    }
    //################################################################################################
    func filterArtistsByComposition(id: Int) -> [[String:Any]] {
        //print("filterArtistByComposition - id: ", id)
        var filteredRows: [[String:Any]] = []

        // Make sure the tables are loaded
        loadTable()
        artists.loadTable()

        for composer in table {
            //print("composer: ", composer)
            if composer["composition_id"] as? Int == id {
                var foundRow = composer
                let artist = artists.getRow(id: composer["artist_id"] as! Int)
                foundRow["name"] = artist["name"]
                filteredRows.append(foundRow)
            }
        }
        //print("filterArtistByComposition - filteredRows: ", filteredRows)
        return filteredRows
    }
    //################################################################################################
    // Find all compositions for a given artist
    func filterCompositionsByArtist(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // Make sure the tables are loaded
        compositions.loadTable()

        for composer in super.table {
            if composer["artist_id"] as? Int == id {
                var foundRow = compositions.getRow(id: composer["composition_id"] as! Int)
                foundRow["role"] = composer["role"]
                filteredRows.append(foundRow)
            }
        }
        return filteredRows
    }
}
