//
//  MusicQueue.swift
//  jazzcat
//
//  Created by Curt Rowe on 15/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Foundation


let musicQueueUpdateNotification = Notification.Name(rawValue:"com.zetcho.musicQueueUpdate")

class MusicQueue {
    // Make it a singleton
    static let shared = MusicQueue()

    var table: [Int]
    let nc = NotificationCenter.default

    //################################################################################################
    //Making it private prevents the use of the default '()' initializer for this class.
    private init() {
        table = []
    }
    //################################################################################################
    func count() -> Int {
        return table.count
    }
    //################################################################################################
    func queueFirst(trackID: Int) {
        table.insert(trackID, at: 0)
        //let nc = NotificationCenter.default
        nc.post(name: musicQueueUpdateNotification, object: nil, userInfo: [:])
    }
    //################################################################################################
    func queueLast(trackID: Int) {
        table.append(trackID)
        //let nc = NotificationCenter.default
        nc.post(name: musicQueueUpdateNotification, object: nil, userInfo: [:])
    }
    //################################################################################################
    func dequeue() -> Int {
        let trackID = table[0]
        table.remove(at: 0)
        nc.post(name: musicQueueUpdateNotification, object: nil, userInfo: [:])
        return trackID
    }
    //################################################################################################
    func remove(at: Int) {
        table.remove(at: at)
        nc.post(name: musicQueueUpdateNotification, object: nil, userInfo: [:])
    }
    //################################################################################################
    func clear() {
        table = []
        //let nc = NotificationCenter.default
        nc.post(name: musicQueueUpdateNotification, object: nil, userInfo: [:])
    }
}