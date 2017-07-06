//
//  TrackMetadata.swift
//  jazzcat
//
//  Created by Curt Rowe on 6/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let trackMetadataUpdateNotification = Notification.Name(rawValue:"com.zetcho.trackMetadataUpdated")

class TrackMetadata: Metadata {
    // Make it a singleton
    static let shared = TrackMetadata()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {
        super.init()
        super.routing = "track_metadata"
        super.notifier =  Notification.Name(rawValue:"com.zetcho.trackMetadataUpdated")
    }
    //################################################################################################
    func filterByTrack(id: Int) -> [[String:Any]] {
        var filteredRows: [[String:Any]] = []

        // load table in case it hasn't been loaded. If it has, the function returns immediately
        loadTable()

        for row in super.table {
            if row["track_id"] as? Int == id {
                filteredRows.append(super.getRow(id: row["id"] as! Int))
            }
        }
        return filteredRows
    }
}
