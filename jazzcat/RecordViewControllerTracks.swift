//
//  RecordViewControllerTracks.swift
//  jazzcat
//
//  Created by Curt Rowe on 1/5/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

extension RecordViewController {
    //################################################################################################
    func catchTrackNotification(notification:Notification) -> Void {
        var matchIndex = -1
        guard let userInfo = notification.userInfo,
            let changeType = userInfo["type"] as? String,
            let trackRow = notification.object as? [String: Any]
            else {
                print("No userInfo found in notification")
                return
        }
        //print("record: ", track)
        let changeKey = trackRow["id"] as! Int

        if changeType == "add" || changeType == "update" {
            if records.table[selectedRecord]["id"] as! Int != trackRow["record_id"] as! Int {
                // not on this record, ignore
                return
            }
        }
        if changeType == "delete" {
            // Check to see if it is in the filter table
            for (index, track) in tracksFilter.enumerated() {
                if track["id"] as! Int == changeKey {
                    matchIndex = index
                    break
                }
            }
            // Not found, ignore
            if matchIndex == -1 { return }
        }
        filterTracks(foreignKey: records.table[selectedRecord]["id"] as! Int)
        // Set to the first track in case it isn't found
        selectedTrack = 0
        for (index, track) in tracksFilter.enumerated() {
            if track["id"] as! Int == changeKey {
                selectedTrack = index
                break
            }
        }
        trackTable.selectRowIndexes(NSIndexSet(index: selectedTrack) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func filterTracks(foreignKey: Int) {
        tracksFilter = tracks.filterTracksByRecord(id: foreignKey)
        var firstValue = ""
        for track in tracksFilter {
            if let value = track["source_name"] as? String {
                if firstValue == "" {
                    firstValue = value
                    source.stringValue = value
                    continue
                }
                if value != firstValue {
                    source.stringValue = "mixed"
                    break
                }
                source.stringValue = value
            }
        }
        trackTable.reloadData()
    }
    //################################################################################################
    @IBAction func addTrack(_ sender: NSButton) {
        callTrackDialog(type: RequestType.add)
    }
    //################################################################################################
    func trackTableDoubleClick(_ sender: AnyObject) {
        callTrackDialog(type: RequestType.update)
    }
    //################################################################################################
    @IBAction func getTrackInfoClicked(_ sender: NSMenuItem) {
        callTrackDialog(type: RequestType.update)
    }
    //################################################################################################
    func callTrackDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let trackDialogWindowController = storyboard.instantiateController(withIdentifier: "trackWindowControllerScene")
        as! NSWindowController

        if let trackDialogWindow = trackDialogWindowController.window {
            let trackDialogViewController = trackDialogWindow.contentViewController as! TrackDialogViewController
            requestType = type
            trackDialogViewController.delegate = self
            let application = NSApplication.shared()
            application.runModal(for: trackDialogWindow)
            // And we're back
            self.view.window!.makeKey()
            recordTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func deleteTrack(_ sender: NSButton) {
        if selectedTrack > -1 {
            let deleteID = String(describing: tracksFilter[selectedTrack]["id"]!)
            tracks.deleteRowAndNotify(row: deleteID)
        }
        else {
            // todo: handle error
        }
    }
    //################################################################################################
    func highestDisk() -> Int {
        var disk = 1
        for track in tracksFilter {
            if track["disk"] as! Int > disk {
                disk = track["disk"] as! Int
            }
        }
        return disk
    }
    //################################################################################################
    func nextTrack(disk: Int) -> Int {
        var nextTrack = 0
        for track in tracksFilter {
            if disk == track["disk"] as! Int &&
                   track["track"] as! Int > nextTrack {
                nextTrack = track["track"] as! Int
            }
        }
        nextTrack = nextTrack + 1
        return nextTrack
    }
    //################################################################################################
    @IBAction func advanceTrackClicked(_ sender: NSButton) {
        do {
            let recordName = records.table[selectedRecord]["name"]
            let results = try iTunes.playlists[1].search(for_: recordName!) as [ITUItem]
            //print("results count: ", results.count)

            if results.count > 0 {
                for row in results {
                    let trackNumber = try row.trackNumber.get()
                    let trackName = try row.name.get()
                    let trackTime = try row.time.get()
                    let trackID = try row.persistentID.get()
                    print("track: ", trackNumber, " name: ", trackName, " time: ", trackTime, " id: ", trackID)
                }
            }
        }
        catch {
            print("album search failed")
        }
    }
    //################################################################################################
//    func trackWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        // No sync data is displayed so no need for a refresh.
//    }
    //################################################################################################
    @IBAction func playTrackClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            //let trackID = "C70EA9CDC276CB6D"
            do {
                let persistentID = tracksFilter[selectedTrack]["persistent_id"] as! String
                if persistentID != "" {
                    try iTunes.tracks[ITUIts.persistentID == persistentID].play()
                }
            }
            catch {
                print("Error attempting to play a track")
            }
        }
    }
    //################################################################################################
    @IBAction func queueFirstClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            let id: Int = tracksFilter[selectedTrack]["id"] as! Int
            musicQueue.queueFirst(trackID: id)
            //playList.insert(id, at: 0)
            //let name = tracksFilter[selectedTrack]["composition_name"] as! String
            //print("Inserting ", id, "into playList. Title: ", name)
            //print("selectedTrack: ", selectedTrack)
            //print("row: ", tracksFilter[selectedTrack])
        }
    }
    //################################################################################################
    @IBAction func queueLastClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            let id: Int = tracksFilter[selectedTrack]["id"] as! Int
            musicQueue.queueLast(trackID: id)
            //playList.append(id)
        }
    }
}
