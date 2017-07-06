//
//  Groups.swift
//  jazzcat
//
//  Created by Curt Rowe on 2/2/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

class Groups: RailsData {
    // Make it a singleton
    static let shared = Groups()
    //################################################################################################
    //Making it prevents the use of the default '()' initializer for this class.
    private override init() {

    }
    //################################################################################################
    func loadTable(wait: Bool = true) {
        if isLoaded == true { return }
        let rest = "groups"
        super.loadRailsTable(rest: rest)
        if wait == true {
            dispatchGroup.wait()
        }
    }
}
