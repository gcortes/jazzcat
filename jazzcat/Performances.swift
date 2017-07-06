//
//  Performances.swift
//  jazzcat
//
//  Created by Curt Rowe on 15/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let performanceUpdateNotification = Notification.Name(rawValue:"com.zetcho.performanceUpdate")

class Performances: RailsData {
    // Make it a singleton
    static let shared = Performances()

    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable() {
        if isLoaded == true { return }
        let rest = "performances"
        super.loadRailsTable(rest: rest)
        dispatchGroup.wait()
    }
    //################################################################################################
    func addRowAndNotify(rowData: Dictionary<String, Any>) {
        let rest = "performances"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: performanceWasAdded)
    }
    //################################################################################################
    // Performance history is sorted from distant to recent
    func performanceWasAdded(row: [String: Any]?) {
            super.table.append(row!)
            let nc = NotificationCenter.default
            nc.post(name: performanceUpdateNotification,
                object: row,
                userInfo: ["type": "add"])
    }
}