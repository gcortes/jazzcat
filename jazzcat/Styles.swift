//
//  Styles.swift
//  jazzcat
//
//  Created by Curt Rowe on 28/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

class Styles: RailsData {
    // Make it a singleton
    static let sharedInstance = Styles()
    //private init() {} //Prevents the use of the default '()' initializer for this class.
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "styles"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
    //################################################################################################
    func addRow(rowData: Dictionary<String, Any>, completionHandler: @escaping ([String: Any]?) -> Void) {
        let rest = "styles"
        super.addRailsRow(rest: rest, rowData: rowData, completionHandler: completionHandler)
        dispatchGroup.wait()
    }
    //################################################################################################
    func updateRow(row: String, rowData: Dictionary<String,Any>, roundTrip: Any? = nil,
                   completionHandler: @escaping ([String: Any]?, Any?) -> Void) {
        let rest = "styles/" + row
        super.updateRailsRow(rest: rest, rowData: rowData, roundTrip: roundTrip, completionHandler: completionHandler)
        dispatchGroup.wait()
    }
    //################################################################################################
    func deleteRow(row: String, completionHandler: @escaping (Any) -> Void, roundTrip: Any) {
        let rest = "styles/" + row
        super.deleteRailsRow(rest: rest, completionHandler: completionHandler, roundTrip: roundTrip)
        dispatchGroup.wait()
    }
}
