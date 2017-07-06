//
//  RecordMetadata.swift
//  jazzcat
//
//  Created by Curt Rowe on 13/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let recordMetadataUpdateNotification = Notification.Name(rawValue:"com.zetcho.recordMetadataUpdated")

class RecordMetadata: Metadata {
    // Make it a singleton
    static let shared = RecordMetadata()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {
        super.init()
        super.routing = "record_metadata"
        super.notifier =  Notification.Name(rawValue:"com.zetcho.recordMetadataUpdated")
    }
    //################################################################################################
    func filterByRecord(id: Int) -> [[String:Any]] {
/*        var filteredRows: [[String:Any]] = []

        // load table in case it hasn't been loaded. If it has, the function returns immediately
        loadTable()

        for row in super.table {
            if row["record_id"] as? Int == id {
                filteredRows.append(super.getRow(id: row["id"] as! Int))
            }
        }*/
        return super.filterByType(id: id, filterType: "record_id")
    }
}
