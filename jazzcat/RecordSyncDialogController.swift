//
//  RecordSyncDialogController.swift
//  jazzcat
//
//  Created by Curt Rowe on 14/3/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

class RecordSyncDialogController: NSViewController {

    let nc = NotificationCenter.default
    var delegate: tableDataDelegate!

    let iTunes = ITunes()

    let records = Records.shared
    var recordRow: Dictionary<String, Any> = [:]

    var tracks = Tracks.shared

    var jazzCatTracks: [[String:Any]] = []
    var trackIndex: Int!
    @IBOutlet weak var jazzCatTable: NSTableView!
    let jazzCatTableTag = 1
    var newTrackRow: [String: Any] = [:]

    var iTunesTracks: [[String: Any]] = []
    @IBOutlet weak var iTunesTable: NSTableView!
    let iTunesTableTag = 2
    var iTunesIndex: Int = -1

    let compositions = Compositions.shared

    @IBOutlet weak var compositionTable: NSTableView!
    let compositionTableTag = 3
    var newCompositions: [[ String: Any]] = []
    var compositionObserver: NSObjectProtocol!

    let sources = Sources.shared

    @IBOutlet weak var sourceTable: NSComboBox!
    let sourceTableTag = 4
    var selectedSource: Int = -1

    @IBOutlet weak var addCompositionButton: NSButton!
    @IBOutlet weak var retryButton: NSButton!
    @IBOutlet weak var stopBuildButton: NSButton!
    @IBOutlet weak var buildButton: NSButton!

    @IBOutlet weak var newCompositionName: NSTextField!

    @IBOutlet weak var jazzCatRecordName: NSTextField!
    @IBOutlet weak var iTunesRecordName: NSTextField!
    @IBOutlet weak var jazzCatTrackCount: NSTextField!
    @IBOutlet weak var iTunesTrackCount: NSTextField!
    @IBOutlet weak var iTunesDateAdded: NSTextField!
    @IBOutlet weak var recordDateAdded: NSTextField!

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        jazzCatTable.tag = jazzCatTableTag
        iTunesTable.tag = iTunesTableTag

        compositionTable.tag = compositionTableTag
        compositions.loadTable()
        compositionTable.reloadData()

        sourceTable.tag = sourceTableTag
        sources.loadTable()
        sourceTable.reloadData()

        compositionObserver = nc.addObserver(forName:compositionUpdateNotification, object:nil, queue:nil,
            using:catchCompositionNotification)
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()

        if self.delegate == nil {
            print("Delegate not set. Exiting")
            let application = NSApplication.shared()
            application.stopModal()
        }
        initializeDialog()
    }
    //################################################################################################
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //print("viewWillDisappear called")
        nc.removeObserver(compositionObserver)
    }
    //################################################################################################
    func catchCompositionNotification(notification:Notification) -> Void {
        //print("catchCompositionNotification called")

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let compositionRow = notification.object as? [String: Any]
        else {
            print("No userInfo found in notification")
            return
        }
        if changeType == "add" {
            for index in 0..<jazzCatTracks.count {
                if jazzCatTracks[index]["composition_name"] as! String == compositionRow["name"] as! String {
                    let id = compositionRow["id"] as! Int
                    jazzCatTracks[index]["composition_id"] = id
                    break
                }
            }
            newCompositions.append(compositionRow)
            jazzCatTable.reloadData()
            refreshTracks()
        }
        compositionTable.reloadData()
        //selectedComposition = compositions.getIndex(foreignKey: composition?["id"] as! Int)
        //compositionTable.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func initializeDialog() {

        retryButton.isEnabled = false
        addCompositionButton.isEnabled = false
        stopBuildButton.isEnabled = false
        newCompositionName.isEnabled = false

        recordRow = delegate.getDataSourceRow(entity: DataEntity.record, request: RequestType.update)
        jazzCatRecordName.stringValue = recordRow["name"] as! String

        filterTracks(foreignKey: recordRow["id"] as! Int)

        filterITunesTracks(foreignKey: recordRow["name"] as! String)
        iTunesTable.reloadData()

        if iTunesTracks.count > 0 {
            let dateAdded = iTunesTracks[0]["date_added"] as! Date
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "dd MMM yyyy"
            iTunesDateAdded.stringValue = dateFormatter.string(from: dateAdded)
        }

        if let dateAdded = recordRow["date_added"] as? String {
            let ISO8601DateFormatter = DateFormatter()
            ISO8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
            ISO8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ISO8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = ISO8601DateFormatter.date(from: dateAdded) {
                //print("date: ", date)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "dd MMM yyyy"
                recordDateAdded.stringValue = dateFormatter.string(from: date)
            }
        }
    }
    //################################################################################################
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func stopBuildClicked(_ sender: NSButton) {
        buildButton.isEnabled = true
        stopBuildButton.isEnabled = false
    }
    //################################################################################################
    @IBAction func addCompositionClicked(_ sender: NSButton) {
        let name = newCompositionName.stringValue
        if name != "" {
            //print("newCompositionName: ", name)
            newTrackRow["composition_name"] = name
            //jazzCatTracks.table.append(newTrackRow)
            jazzCatTracks.append(newTrackRow)
            addComposition(name: name)
            newCompositionName.stringValue = ""
            newCompositionName.isEnabled = false
            newTrackRow = [:]
            buildNewRows()
        }
        else {
            dialogErrorReason(text: "Composition name must not be blank")
        }
    }
    //################################################################################################
    @IBAction func retryButtonClicked(_ sender: NSButton) {
        let name = newCompositionName.stringValue as String
        if name != "" {
            iTunesTracks[iTunesIndex]["name"] = name
            iTunesTable.reloadData()
            newTrackRow = [:]
            buildNewRows()
            // todo: update iTunes with new name
        }
        else {
            dialogErrorReason(text: "Composition name must not be blank")
        }
    }
    //################################################################################################
    @IBAction func synchronizeButtonClicked(_ sender: NSButton) {
        var rowData: [String: Any] = [:]
        for track in jazzCatTracks {
            rowData = track
            if let date = rowData["last_played"] {
                rowData["last_played"] = "\(date)"
            }
            rowData["composition_name"] = nil
            //print("rowData: ", rowData)
            tracks.addRowAndNotify(rowData: rowData)
        }
        var recordUpdate: [String:Any] = [:]
        recordUpdate["date_added"] = "\(String(describing: iTunesTracks[0]["date_added"]))"
        //print("recordUpdate: ", recordUpdate)
        let rowID = String(describing: recordRow["id"]!)
        records.updateRowAndNotify(row: rowID, rowData: recordUpdate)
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func buildButtonClicked(_ sender: NSButton) {
        selectedSource = sourceTable.indexOfSelectedItem as Int
        if selectedSource == -1 {
            dialogErrorReason(text: "You must select a source before building")
            return
        }
        buildNewRows()
    }
    //################################################################################################
    func buildNewRows() {
        //var newTrackRow: [String: Any] = [:]
        var match: Bool = false
        var fullMatch: Bool = false
        var matchRow: Int = -1


        addCompositionButton.isEnabled = false
        retryButton.isEnabled = false
        buildButton.isEnabled = false
        stopBuildButton.isEnabled = true

        for (index, iTunesRow) in iTunesTracks.enumerated() {
            iTunesIndex = index
            //Check for existing rows using persistent id's
            //If found, skip to them
            var duplicate: Bool = false
            for track in jazzCatTracks {
                if iTunesRow["persistent_id"] as! String == track["persistent_id"] as! String {
                    duplicate = true
                    //print("duplicate found")
                    break
                }
            }
            if duplicate == true { continue }

            let iTunesName = iTunesRow["name"] as! String
            let nameCount = iTunesName.characters.count - 1
            let startIndex = iTunesName.startIndex
            fullMatch = true
            match = false

            for length in (1...nameCount).reversed() {
                let endIndex = iTunesName.index(iTunesName.startIndex, offsetBy: length)
                //print("start index: ", startIndex, " end index: ", endIndex, " length: ", length)
                let nameFragment = iTunesName[startIndex...endIndex]
                //print("iTunes name: ", nameFragment)

                for (index, row) in compositions.table.enumerated() {
                    let dataString = row["name"] as! String
                    if dataString.commonPrefix(with: nameFragment,
                        options: String.CompareOptions.caseInsensitive).lengthOfBytes(using: String.Encoding.utf8) ==
                           nameFragment.lengthOfBytes(using: String.Encoding.utf8) {
                        match = true
                        matchRow = index
                        newTrackRow["composition_id"] = row["id"] as! Int
                        //print("row id: ", row["id"], " name: ", row["name"])
                        break
                    }
                }
                if match == true {break}
                fullMatch = false
            }
            if match == true {
                //print("fullMatch: ", fullMatch)
                if fullMatch == false {
                    // Only a partial match was found.
                    // It will be used to position the cursor in the compositions table
                    newCompositionName.isEnabled = true
                    newCompositionName.stringValue = iTunesName
                    addCompositionButton.isEnabled = true
                    retryButton.isEnabled = true
                    buildJazzCatTrack(iTunesRow: iTunesRow)
                    compositionTable.scrollRowToVisible(matchRow)
                    return
                }
                else {
                    // An exact match was found
                    buildJazzCatTrack(iTunesRow: iTunesRow)
                    jazzCatTracks.append(newTrackRow)
                    // todo: move this after testing
                    jazzCatTable.reloadData()
                    newTrackRow = [:]
                    continue
                }
            }
            else { // some composition don't match anything for some strange reason
                //print("match is false")
                newCompositionName.isEnabled = true
                newCompositionName.stringValue = iTunesName
                addCompositionButton.isEnabled = true
                retryButton.isEnabled = true
                buildJazzCatTrack(iTunesRow: iTunesRow)
                return
            }
        }
        buildButton.isEnabled = true
        stopBuildButton.isEnabled = false
        addCompositionButton.isEnabled = false
        retryButton.isEnabled = false
    }
    //################################################################################################
    func buildJazzCatTrack(iTunesRow: [String:Any]) {
        newTrackRow["record_id"] = recordRow["id"]
        newTrackRow["composition_name"] = iTunesRow["name"] as! String
        newTrackRow["disk"] = iTunesRow["disk"]
        newTrackRow["track"] = iTunesRow["track"]
        newTrackRow["time"] = iTunesRow["time"]
        newTrackRow["persistent_id"] = iTunesRow["persistent_id"]
        newTrackRow["play_count"] = iTunesRow["play_count"]
        newTrackRow["rating"] = iTunesRow["rating"]
        newTrackRow["favorite"] = iTunesRow["loved"]
        if let date = iTunesRow["last_played"] {
            newTrackRow["last_played"] = date
        }
        newTrackRow["source_id"] = sources.table[selectedSource]["id"]
    }
    //################################################################################################
    func filterITunesTracks(foreignKey: String) {
        //print("foreign key: ", foreignKey)
        do {
            let results = try iTunes.playlists[1].search(for_: foreignKey, only: ITU.albums) as [ITUItem]
            //print("results count: ", results.count)

            if results.count > 0 {
                var entry: Dictionary<String, Any> = [:]
                iTunesTracks = []
                for row in results {
                    let album = try row.album.get() as String
                    //print("album: ", album)
                    if album == foreignKey {
                        entry["disk"] = try row.discNumber.get() as Int
                        entry["track"] = try row.trackNumber.get() as Int
                        entry["play_count"] = try row.playedCount.get() as Int
                        entry["name"] = try row.name.get() as String
                        entry["persistent_id"] = try row.persistentID.get()
                        entry["time"] = try row.time.get() as String
                        entry["rating"] = try (row.rating.get() as Int / 20)
                        entry["loved"] = try row.loved.get() as Bool
                        let stringDate = try row.dateAdded.get()
                        if let dateAdded = stringDate as? Date{
                            entry["date_added"] = dateAdded
                        }
                        let value = try row.playedDate.get()
                        if let playedDate = value as? Date {
                            entry["last_played"] = playedDate
                        }
                        iTunesTracks.append(entry)
                        //print("entry: ", entry)
                        entry = [:]
                    }
                }
            }
        }
        catch {
            print("album search failed")
        }
        iTunesTrackCount.integerValue = iTunesTracks.count
    }
    //################################################################################################
    func filterTracks(foreignKey: Int) {
        //let id = String(describing: foreignKey)
        //jazzCatTracks.filterRows(id: id, filter: "record", completionHandler: trackFilterWasRead)
        jazzCatTracks = tracks.filterTracksByRecord(id: foreignKey)
        jazzCatTable.reloadData()
        jazzCatTrackCount.integerValue = jazzCatTracks.count
    }
    //################################################################################################
/*    func dialogOKCancel(question: String, text: String) -> Bool {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = question
        dialog.informativeText = text
        dialog.addButton(withTitle: "Yes")
        dialog.addButton(withTitle: "No")
        let res = dialog.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }*/
    //################################################################################################
    func dialogErrorReason(text: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = "Error"
        dialog.informativeText = text
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
    }
    //################################################################################################
    func addComposition(name: String) {
        var row: Dictionary<String, Any> = [:]
        row["name"] = name
        row["style_id"] = 61
        compositions.addRowAndNotify(rowData: row)
    }
    //################################################################################################
    func refreshTracks() {
        let count = jazzCatTracks.count - 1
        for index in 0...count {
            for composition in newCompositions {
                if jazzCatTracks[index]["composition_name"] as! String == composition["name"] as! String {
                    jazzCatTracks[index]["composition_id"] = composition["id"] as! Int
                    //print("Adding composition id: ", composition["id"]!)
                }
            }
        }
    }
}
//####################################################################################################
//####################################################################################################
extension RecordSyncDialogController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case jazzCatTableTag:
                count = jazzCatTracks.count
                //print("jazzCatTable count: ", count)
            case iTunesTableTag:
                count = iTunesTracks.count
                //print("iTunesTable count: ", count)
            case compositionTableTag:
                count = compositions.table.count
                //print("compositions table count: ", count)
            //case sourceTableTag:
              //  count = sources.table.count
            default:
                print("unknown table tag:", tableView.tag)
        }
        return count
    }
}

//####################################################################################################
//####################################################################################################
extension RecordSyncDialogController: NSTableViewDelegate {

    //################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView

        switch tableView.tag {
            case jazzCatTableTag :
                // get the "Item" for the row
                let item = jazzCatTracks[row]

                //if tableColumn!.identifier == "track" {
                switch tableColumn!.identifier {
                    case "disk", "track", "play_count", "rating", "composition_id", "record_id", "source_id" :
                        if let val = item[tableColumn!.identifier] as? Int {
                            result.textField?.integerValue = val
                        }
                        else {
                            // if the attribute's value is missing enter a blank string
                            result.textField?.stringValue = ""
                        }
                    case "last_played" :
                        if let val = item[(tableColumn?.identifier)!] as? Date {
                            //print("date found: ", val)
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US")
                            dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
                            //lastPlayedDate.stringValue = dateFormatter.string(from: (playedDate!))
                            result.textField?.stringValue = dateFormatter.string(from: (val))
                        }
                        else {
                            result.textField?.stringValue = ""
                        }
                    case "favorite":
                        if let val = item[(tableColumn?.identifier)!] as? Bool {
                            if val == true {
                                result.textField?.stringValue = "Y"
                                //tableRow["favorite"] = true
                            }
                            else {
                                result.textField?.stringValue = ""
                                //tableRow["favorite"] = false
                            }
                        }
                    default:
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                        else {
                            // if the attribute's value is missing enter a blank string
                            result.textField?.stringValue = ""
                        }
                }
            //print(result.textField?.stringValue)
            case iTunesTableTag :
                let item = iTunesTracks[row]

                switch tableColumn!.identifier {
                    case "track", "disk" :
                        if let val = item[tableColumn!.identifier] as? Int {
                            result.textField?.integerValue = val
                        }
                        else {
                            // if the attribute's value is missing enter a blank string
                            result.textField?.stringValue = ""
                        }
                    default:
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                        else {
                            // if the attribute's value is missing enter a blank string
                            result.textField?.stringValue = ""
                        }
                }
            case compositionTableTag:
                let item = compositions.table[row]
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }
                else {
                    // if the attribute's value is missing enter a blank string
                    result.textField?.stringValue = ""
                }
            /*case sourceTableTag:
                let item = sources.table[row]
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }*/
            default:
                print("Unknown tag in table data")
        }
        return result
    }
}
//####################################################################################################
//####################################################################################################
extension RecordSyncDialogController: NSComboBoxDataSource {

    //################################################################################################
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //print("Starting numberOfItems. comboBox.tag", comboBox.tag)
        var count: Int = 0
        switch comboBox.tag {
            case sourceTableTag:
                count = sources.table.count
            default:
                //print("Invalid combobox tag: ", comboBox.tag)
                count = 0
        }
        //print("Ending numberOfItems. count: ", count)
        return count
    }
    //################################################################################################
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        //print("Starting objectValueForItemAt index: ", index)
        var entry: String = "object not found"
        guard index > -1 else {
            print("Invalid index in objectValueForItemAt index: ", index)
            return entry
        }
        switch comboBox.tag {
            case sourceTableTag:
                let sourceRow: Dictionary<String, Any> = sources.table[index]
                if let val = sourceRow["name"] as? String {
                    entry = val
                    //print("entry: ", entry)
                }
            default:
                entry = "comboBox tag not found"
        }
        return entry
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        //print("Starting indexOfItemWithStringValue: ", string)
        var index = NSNotFound
        switch aComboBox.tag {
            case sourceTableTag:
                index = findMatch(table: sources.table, string: string)
            default:
                break
        }
        //print("ending indexOfItemWithStringValue - index: ", index)
        return index
    }
    //################################################################################################
    // This function assumes the table has an entry "name"
    func findMatch(table: [[String: Any]], string: String) -> Int {
        var matchIndex = NSNotFound
        for (index, dataRow) in table.enumerated() {
            if dataRow["name"] as! String == string {
                matchIndex = index
                break
            }
        }
        return matchIndex
    }
    //################################################################################################
    // The only purpose for handling this notification is to record a change in 'select only' comboboxes
    /*func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //print("Starting comboBoxSelectionDidChange. Tag: ", comboBox.tag)
        switch comboBox.tag {
            case sourceTableTag:
                postEvent(input: "source", status: InputStatus.valid)
            default:
                break
        }
    }*/
}
//####################################################################################################
//####################################################################################################
extension RecordSyncDialogController: NSComboBoxDelegate {

    //################################################################################################
/*    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //NSLog("Starting comboBoxSelectionDidChange - Tag: ", comboBox.tag)
        switch comboBox.tag {
            case sourceTableTag:
                postEvent(input: "source", status: InputStatus.valid)
            default:
                break
        }
        //NSLog("Ending comboBoxSelectionDidChange: starting")
    }*/
    //################################################################################################
/*    func comboBox(_ aComboBox: NSComboBox, completedString string: String) -> String? {
        //print("Starting completedString. Tag: ", aComboBox.tag)
        var returnString = ""
        switch aComboBox.tag {
            case sourceTableTag:
                returnString = findFirstOccurrence(table: sources.table, string: string)
            default:
                break
        }
        return returnString
    }*/
    //################################################################################################
    // This function only works when the table contains a "name" entry
    func findFirstOccurrence(table: [[String: Any]], string: String) -> String {
        //NSL("Starting findFirstOccurrence parm string: ", string)
        var returnString = ""
        for var dataRow in table {
            let dataString = dataRow["name"] as! String
            if dataString.commonPrefix(with: string,
                options: String.CompareOptions.caseInsensitive).lengthOfBytes(using: String.Encoding.utf8) ==
                   string.lengthOfBytes(using: String.Encoding.utf8) {
                //print("findFirstOccurrence dataRow: ", dataRow)
                returnString = dataRow["name"] as! String
                break
            }
        }
        //NSLog("Ending findFirstOccurrence returning: ", returnString)
        return returnString
    }
    //################################################################################################
/*    override func controlTextDidChange(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        //NSLog("Starting controlTextDidChange: ", control.tag)
        switch control.tag {
            case nameFieldTag:
                //print("name field value: ", name.stringValue)
                postEvent(input: "name", status: InputStatus.valid)
            default:
                break
        }
    }*/
}

