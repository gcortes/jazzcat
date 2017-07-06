//
//  RecordFilter.swift
//  jazzcat
//
//  Created by Curt Rowe on 4/7/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

class FilteredRecords {

    var table: [[String:Any]] = []
    //################################################################################################
    func getIndex(foreignKey: Int) -> Int {
        if let index = table.index(where: { (record) -> Bool in
            record["id"] as! Int == foreignKey }) {
            return index
        }
        else {
            return -1
        }
    }
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