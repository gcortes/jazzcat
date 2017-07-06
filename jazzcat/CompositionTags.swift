//
//  CompositionTags.swift
//  jazzcat
//
//  Created by Curt Rowe on 25/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation

let compositionTagUpdateNotification = Notification.Name(rawValue:"com.zetcho.compositionTagUpdated")

class CompositionTags: Tags {
    // Make it a singleton
    static let shared = CompositionTags()
    //################################################################################################
    //Private prevents the use of the default '()' initializer for this class.
    private override init() {
        super.init()
        super.routing = "composition_tags"
        super.notifier = Notification.Name(rawValue: "com.zetcho.compositionTagUpdated")
    }
}