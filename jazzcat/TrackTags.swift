//
//  TrackTags.swift
//  jazzcat
//
//  Created by Curt Rowe on 6/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let trackTagUpdateNotification = Notification.Name(rawValue:"com.zetcho.trackTagUpdated")

class TrackTags: Tags {
    // Make it a singleton
    static let shared = TrackTags()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {
        super.init()
        super.routing = "track_tags"
        super.notifier = Notification.Name(rawValue: "com.zetcho.trackTagUpdated")
    }
}