//
//  RecordTags.swift
//  jazzcat
//
//  Created by Curt Rowe on 13/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let recordTagUpdateNotification = Notification.Name(rawValue:"com.zetcho.recordTagUpdated")

class RecordTags: Tags {
    // Make it a singleton
    static let shared = RecordTags()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {
        super.init()
        super.routing = "record_tags"
        super.notifier = Notification.Name(rawValue: "com.zetcho.recordTagUpdated")
    }
}