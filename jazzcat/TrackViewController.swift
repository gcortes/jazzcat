//
//  trackViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 31/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

class TrackViewController: JazzCatViewController {

    let iTunes = ITunes()

    var requestType: RequestType!

    let musicQueue = MusicQueue.shared

    let trackMetadata = TrackMetadata.shared

    let trackTags = TrackTags.shared

    var trackFilter: [[String: Any]] = []
    let trackFilterTableViewTag = 1
    var selectedTrackTag: Int = -1
    @IBOutlet weak var trackFilterTableView: NSTableView!

    let compositionMetadata = CompositionMetadata.shared

    let compositionTags = CompositionTags.shared

    var compositionFilter: [[String:Any]] = []
    let compositionFilterTableViewTag = 2
    var selectedCompositionTag: Int = -1
    @IBOutlet weak var compositionFilterTableView: NSTableView!

    @IBOutlet weak var clearButton: NSButton!

    let tracks = Tracks.shared
    var trackFilterActive: Bool = false
    var filteredTracks: [[String:Any]] = []

    let trackTableViewTag = 3
    var selectedTrack: Int = -1
    @IBOutlet weak var trackTableView: NSTableView!

    @IBOutlet var trackMenu: NSMenu!

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        tracks.loadTable()
        trackTableView.tag = trackTableViewTag
        trackTableView.reloadData()

        clearButton.isEnabled = false
        trackTags.loadTable()
        trackFilter = trackTags.table
        for index in 0..<trackFilter.count {
            trackFilter[index]["include"] = false
            trackFilter[index]["exclude"] = false
        }
        trackFilterTableView.tag = trackFilterTableViewTag
        trackFilterTableView.reloadData()
        trackFilterTableView.action = #selector(onTrackItemClicked)

        compositionTags.loadTable()
        compositionFilter = compositionTags.table
        for index in 0..<compositionFilter.count {
            compositionFilter[index]["include"] = false
            compositionFilter[index]["exclude"] = false
        }
        compositionFilterTableView.tag = compositionFilterTableViewTag
        compositionFilterTableView.reloadData()
        compositionFilterTableView.action = #selector(onCompositionItemClicked)

        let nc = NotificationCenter.default
        nc.addObserver(forName: trackUpdateNotification, object: nil, queue: nil, using: catchTrackNotification)
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()
        // If no row selected, select the first one if there is one
        if selectedTrack == -1 {
            if tracks.table.count > 0 {
                selectedTrack = 0
            }
        }
        trackTableView.selectRowIndexes(NSIndexSet(index: 0) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    override func selectRow(selectionData: [String:Any]) {
        //print("In Track selectRow")
        guard let trackID = selectionData["id"] as? Int
            else {
            print("TrackViewController:selectRow - Incorrect selection data received.")
            return
        }
        let index = tracks.getIndex(foreignKey: trackID)
        if index > -1 {
            selectedTrack = index
        }
        trackTableView.selectRowIndexes(NSIndexSet(index: selectedTrack) as IndexSet, byExtendingSelection: false)
        trackTableView.scrollRowToVisible(selectedTrack)
    }
    //################################################################################################
    func catchTrackNotification(notification: Notification) -> Void {
        //print("Catch notification: ", notification.userInfo)

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let trackRow = notification.object as? [String: Any]
            else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", track)
        trackTableView.reloadData()
        if changeType == "add" || changeType == "update" {
            if let key = trackRow["id"] as? Int {
                selectedTrack = tracks.getIndex(foreignKey: key)
            }
        }
        if changeType == "delete" {
            if selectedTrack >= tracks.table.count {
                selectedTrack -= 1
            }
        }
        trackTableView.selectRowIndexes(NSIndexSet(index: selectedTrack) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    @objc private func onTrackItemClicked() {
        //print("row \(trackFilterTableView.clickedRow), col \(trackFilterTableView.clickedColumn) clicked")
        let clickedRow = trackFilterTableView.clickedRow
        let clickedColumn = trackFilterTableView.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if trackFilter[clickedRow]["include"] as! Bool == true {
                trackFilter[clickedRow]["include"] = false
            }
            else {
                trackFilter[clickedRow]["include"] = true
            }
            trackFilterTableView.reloadData()
        }
        if clickedColumn == 2 {
            if trackFilter[clickedRow]["exclude"] as! Bool == true {
                trackFilter[clickedRow]["exclude"] = false
            }
            else {
                trackFilter[clickedRow]["exclude"] = true
            }
            trackFilterTableView.reloadData()
        }
    }
    //################################################################################################
    @objc private func onCompositionItemClicked() {
        //print("row \(compositionFilterTableView.clickedRow), col \(compositionFilterTableView.clickedColumn) clicked")
        let clickedRow = compositionFilterTableView.clickedRow
        let clickedColumn = compositionFilterTableView.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if compositionFilter[clickedRow]["include"] as! Bool == true {
                compositionFilter[clickedRow]["include"] = false
            }
            else {
                compositionFilter[clickedRow]["include"] = true
            }
            compositionFilterTableView.reloadData()
        }
        if clickedColumn == 2 {
            if compositionFilter[clickedRow]["exclude"] as! Bool == true {
                compositionFilter[clickedRow]["exclude"] = false
            }
            else {
                compositionFilter[clickedRow]["exclude"] = true
            }
            compositionFilterTableView.reloadData()
        }
    }
    //################################################################################################
    @IBAction func playMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            do {
                let persistentID = tracks.table[selectedTrack]["persistent_id"] as! String
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
    @IBAction func queueFirstMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            let id: Int = tracks.table[selectedTrack]["id"] as! Int
            musicQueue.queueFirst(trackID: id)
        }
    }
    //################################################################################################
    @IBAction func queueLastMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            let id: Int = tracks.table[selectedTrack]["id"] as! Int
            musicQueue.queueLast(trackID: id)
        }
    }
    //################################################################################################
    @IBAction func trackDetailsClicked(_ sender: NSMenuItem) {
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
            trackTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func clearButtonClicked(_ sender: NSButton) {
        trackFilterActive = false
        for index in 0..<trackFilter.count {
            trackFilter[index]["include"] = false
            trackFilter[index]["exclude"] = false
        }
        trackFilterTableView.reloadData()
        for index in 0..<compositionFilter.count {
            compositionFilter[index]["include"] = false
            compositionFilter[index]["exclude"] = false
        }
        compositionFilterTableView.reloadData()
        trackTableView.reloadData()
        clearButton.isEnabled = false
    }
    //################################################################################################
    @IBAction func filterButtonClicked(_ sender: NSButton) {
        filteredTracks = []
        for track in tracks.table {
            // metadata are the tags assoicated with the track
            let metadata = trackMetadata.filterByTrack(id: track["id"] as! Int)
            if metadata.count == 0 { continue }
            for item in metadata {
                for tag in trackFilter {
                    if tag["id"] as! Int == item["track_tag_id"] as! Int && tag["include"] as! Bool == true {
                        filteredTracks.append(track)
                    }
                }
            }
        }
        trackFilterActive = true
        trackTableView.reloadData()
        clearButton.isEnabled = true
    }
    //################################################################################################
    @IBAction func goToArtistMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.artists
            selectionData["id"] = tracks.table[selectedTrack]["artist_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func goToCompositionMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.compositions
            selectionData["id"] = tracks.table[selectedTrack]["composition_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func goToRecordMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.records
            selectionData["id"] = tracks.table[selectedTrack]["record_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification, object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
}
//####################################################################################################
//####################################################################################################

extension TrackViewController: tableDataDelegate {

    //################################################################################################
    func putDataSourceRow(entity: DataEntity, row: Dictionary<String, Any>) {
        switch entity {
            case DataEntity.track:
                for (key, value) in row {
                    tracks.table[selectedTrack][key] = value
                }
                trackTableView.reloadData()
            default:
                break
        }
    }
    //################################################################################################
    func getRequestType() -> RequestType {
        return requestType
    }
    //################################################################################################
    func verifyInput(field: String, input: Any) -> Bool {
        //var result: Bool = true
        switch field {
            case "track":
                break
            // todo: fix the commented out code
            // Verify that the input is not a duplicate
            /*let data = input as! Dictionary<String, Any>
            for trackRow in tracksFilter {
                if trackRow["disk"] as! Int == data["disk"] as! Int
                       && trackRow["track"] as! Int == data["track"] as! Int {
                    result = false
                    break
                }
            }*/
            default:
                print("Invalid input passed in verifyInput")
        }
        //return result
        return true
    }
    //################################################################################################
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any> {
        //print("selected track: ", selectedTrack)
        var returnData: Dictionary<String, Any> = [:]
        switch entity {
            case DataEntity.track:
                if request == RequestType.update {
                    if trackFilterActive == true {
                        returnData = filteredTracks[selectedTrack]
                    }
                    else {
                        returnData = tracks.table[selectedTrack]
                    }
                }
            default:
                break
        }
        return returnData
    }
}

//####################################################################################################
//####################################################################################################

extension TrackViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case trackTableViewTag:
                if trackFilterActive == true {
                    count = filteredTracks.count
                }
                else {
                    count = tracks.table.count
                }
            case trackFilterTableViewTag:
                count = trackFilter.count
            case compositionFilterTableViewTag:
                count = compositionFilter.count
            default:
                break
        }
        return count
    }
}

//####################################################################################################
//####################################################################################################

extension TrackViewController: NSTableViewDelegate {

    func blankOutField(field: NSTextField) {
        field.stringValue = ""
    }
    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard  let tag = (notification.object as AnyObject).tag,
               let selectedRow = (notification.object as AnyObject).selectedRow
            else {
            return
        }
        switch tag {
            case trackTableViewTag:
                selectedTrack = selectedRow
            case trackFilterTableViewTag:
                selectedTrackTag = selectedRow
            case compositionFilterTableViewTag:
                selectedCompositionTag = selectedRow
            default:
                break
        }
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let column = tableColumn!.identifier
        // blank here once instead of in multiple places in the case statement
        result.textField?.stringValue = ""

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"

        switch tableView.tag {
            case trackTableViewTag:
                // get the "Item" for the row
                var item: [String:Any] = [:]
                if trackFilterActive == true {
                    item = filteredTracks[row]
                }
                else {
                    item = tracks.table[row]
                }

                switch column {
                    case "rating":
                        if let rating = item[tableColumn!.identifier] as? Int {
                            if rating > 0 {
                                let star = "\u{2605}"
                                var stars = ""
                                for _ in 1...rating {
                                    stars = stars + star
                                }
                                result.textField?.stringValue = stars
                            }
                        }

                    case "favorite":
                        if let favorite = item[tableColumn!.identifier] as? Bool {
                            if favorite == true {
                                result.textField?.stringValue = "\u{2665}"
                            }
                        }

                    case "last_played":
                        if let value = item[tableColumn!.identifier] as? String {
                            //print("found string date: ", value)
                            let ISO8601DateFormatter = DateFormatter()
                            ISO8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            ISO8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            ISO8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                            if let playedDate = ISO8601DateFormatter.date(from: value) {
                                //print("converted string to date: ", playedDate)
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = Locale(identifier: "en_US")
                                dateFormatter.dateFormat = "dd MMM yyyy"
                                //lastPlayedDate.stringValue = dateFormatter.string(from: playedDate)

                                let today = Date()
                                //let dateFormatter = DateFormatter()
                                //dateFormatter.locale = Locale(identifier: "en_US")
                                //dateFormatter.dateFormat = "dd MMM yyyy"
                                let stringToday = dateFormatter.string(from: (today))
                                let stringPlayedDate = dateFormatter.string(from: (playedDate))
                                if stringToday == stringPlayedDate {
                                    dateFormatter.dateFormat = "HH:mm"
                                    result.textField?.stringValue = dateFormatter.string(from: (playedDate))
                                }
                                else {
                                    result.textField?.stringValue = stringPlayedDate
                                }
                            }
                        }

                    case "play_count":
                        if let count = item[tableColumn!.identifier] as? Int {
                            result.textField?.integerValue = count
                        }

                    default:
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                }
            case trackFilterTableViewTag:
                let item = trackFilter[row]
                switch column {
                    case "include":
                        //print("tag row: ", item)
                        if item["include"] as! Bool == true {
                            result.textField?.stringValue = "✽"
                            //✽
                            //HEAVY TEARDROP-SPOKED ASTERISK
                            //Unicode: U+273D, UTF-8: E2 9C BD
                        }
                    case "name":
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                    case "exclude":
                        //print("tag row: ", item)
                        if item["exclude"] as! Bool == true {
                            result.textField?.stringValue = "✽"
                        }
                    default:
                        print("Unknown column in filterTableView: ", column)
                }

                // get the value for this column
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }
            case compositionFilterTableViewTag:
                let item = compositionFilter[row]
                //print("compositionFiler row: ", item)
                switch column {
                    case "include":
                        //print("tag row: ", item)
                        if item["include"] as! Bool == true {
                            result.textField?.stringValue = "✽"
                            //✽
                            //HEAVY TEARDROP-SPOKED ASTERISK
                            //Unicode: U+273D, UTF-8: E2 9C BD
                        }
                    case "name":
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                    case "exclude":
                        //print("tag row: ", item)
                        if item["exclude"] as! Bool == true {
                            result.textField?.stringValue = "✽"
                        }
                    default:
                        print("Unknown column in filterTableView: ", column)
                }

                // get the value for this column
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }
            default:
                break
        }
        return result
    }
}
