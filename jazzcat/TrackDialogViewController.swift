//
//  trackDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 31/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

class TrackDialogViewController: NSViewController {

    let iTunes = ITunes()
    var delegate: tableDataDelegate!

    let tracks = Tracks.shared
    var trackRow: [String: Any] = [:]
    var requestType: RequestType!

    let compositions = Compositions.shared
    let compositionTableTag = 1
    var compositionSave: String!
    @IBOutlet weak var composition: NSComboBox!

    let tempos = Tempos.shared
    let tempoTableTag = 2
    @IBOutlet weak var tempo: NSComboBox!

    let groups = Groups.shared
    let groupTableTag = 3
    @IBOutlet weak var group: NSComboBox!

    let sources = Sources.shared
    let sourceTableTag = 6
    @IBOutlet weak var source: NSComboBox!

    @IBOutlet weak var metadataTopView: NSScrollView!
    let trackMetadata = TrackMetadata.shared
    @IBOutlet weak var metadata: NSTableView!
    let metadataTableTag = 7
    var selectedMetadata = -1
    var trackMetadataFilter: [[String:Any]] = []

    let trackTags = TrackTags.shared
    var augmentedTrackTags: [[String:Any]] = []

    @IBOutlet weak var disk: NSTextField!
    let diskFieldTag = 10
    @IBOutlet weak var track: NSTextField!
    let trackFieldTag = 11
    var originalTrack: Int!
    @IBOutlet weak var take: NSTextField!
    let takeFieldTag = 12
    @IBOutlet weak var time: NSTextField!
    let timeFieldTag = 13
    @IBOutlet weak var rating: NSLevelIndicator!
    let ratingFieldTag = 14
    @IBOutlet weak var favorite: NSButton!
    let favoriteFieldTag = 15
    @IBOutlet weak var notes: NSTextField!
    let notesFieldTag = 16

    @IBOutlet weak var lastPlayedDate: NSTextField!
    @IBOutlet weak var playCount: NSTextField!

    @IBOutlet weak var processButton: NSButton!
    @IBOutlet weak var addAndRepeatButton: NSButton!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    // Data retrieved from iTunes
    var playedDate: Date?

    var repeatAdd: Bool = false

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        compositions.loadTable()
        composition.tag = compositionTableTag
        //composition.completes = true
        composition.reloadData()

        disk.tag = diskFieldTag
        track.tag = trackFieldTag
        take.tag = takeFieldTag
        time.tag = timeFieldTag
        rating.tag = ratingFieldTag
        favorite.tag = favoriteFieldTag
        notes.tag = notesFieldTag

        tempos.loadTable()
        tempo.tag = tempoTableTag
        tempo.reloadData()

        groups.loadTable()
        group.tag = groupTableTag
        group.reloadData()

        sources.loadTable()
        source.tag = sourceTableTag
        source.reloadData()

        trackMetadata.loadTable()
        metadata.tag = metadataTableTag

        trackTags.loadTable()
        augmentedTrackTags = trackTags.table
        trackMetadataFilter = []
        for index in 0..<augmentedTrackTags.count {
            augmentedTrackTags[index]["selected"] = false
            augmentedTrackTags[index]["metadata_id"] = 0
        }
        metadata.reloadData()
        metadata.action = #selector(onItemClicked)
        //print("leaving viewDidLoad")
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()
        if self.delegate == nil {
            print("Delegate not set. Exiting")
            let application = NSApplication.shared()
            application.stopModal()
        }
        requestType = delegate.getRequestType()
        initializeDialog()
        let nc = NotificationCenter.default
        nc.addObserver(forName: compositionUpdateNotification, object: nil, queue: nil, using: catchCompositionNotification)
    }
    //################################################################################################
    func catchCompositionNotification(notification: Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let compositionRow = notification.object as? [String: Any]
            else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", composition)
        composition.reloadData()
        var selectedComposition = 0
        if changeType == "add" || changeType == "update" {
            // todo: this setting may be done for some other add
            postEvent(input: "composition", status: InputStatus.valid)
            selectedComposition = compositions.getIndex(foreignKey: compositionRow["id"] as! Int)
        }
        composition.selectItem(at: selectedComposition)
    }
    //################################################################################################
    func initializeDialog() {
        trackRow = delegate.getDataSourceRow(entity: DataEntity.track, request: requestType)
        //print("trackRow: ", trackRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
            addAndRepeatButton.isEnabled = false
        }
        else {
            processButton.title = "Add"
            // Don't allow metadata changes on add. There is no track id to use in adding them.
            // It makes no sense to do it as that track can't be played until it's added.
            metadataTopView.isHidden = true
        }
        if let value = trackRow["composition_name"] as? String {
            composition.stringValue = value
            let foreignKey = trackRow["composition_id"] as! Int
            let index = compositions.getIndex(foreignKey: foreignKey)
            //print("get input index: ", index)
            composition.selectItem(at: index)
        }
        else {
            composition.stringValue = ""
            let index = composition.indexOfSelectedItem
            if index > -1 {
                composition.deselectItem(at: index)
            }
        }
        if let value = trackRow["disk"] as? Int {
            disk.integerValue = value
        }
        if var value = trackRow["track"] as? Int {
            if repeatAdd == true {
                value += 1
            }
            track.integerValue = value
            if requestType == RequestType.update {
                originalTrack = value       // Save for editing
            }
            else {
                originalTrack = -1
            }
        }

        if let value = trackRow["take"] as? String {
            take.stringValue = value
        }
        else {
            take.stringValue = ""
        }

        if let value = trackRow["time"] as? String {
            time.stringValue = value
        }
        else {
            time.stringValue = ""
        }

        if let value = trackRow["tempo_name"] as? String {
            tempo.stringValue = value
            let index = tempos.getIndex(foreignKey: trackRow["tempo_id"] as! Int)
            tempo.selectItem(at: index)
        }
        else {
            tempo.stringValue = ""
            let index = tempo.indexOfSelectedItem
            if index > -1 {
                tempo.deselectItem(at: index)
            }
        }

        if let value = trackRow["group_type"] as? String {
            group.stringValue = value
            let index = groups.getIndex(foreignKey: trackRow["group_id"] as! Int)
            group.selectItem(at: index)
        }
        else {
            group.stringValue = ""
            let index = group.indexOfSelectedItem
            if index > -1 {
                group.deselectItem(at: index)
            }
        }

        if let value = trackRow["source_name"] as? String {
            source.stringValue = value
            let index = sources.getIndex(foreignKey: trackRow["source_id"] as! Int)
            source.selectItem(at: index)
        }
        else {
            source.stringValue = ""
            let index = source.indexOfSelectedItem
            if index > -1 {
                source.deselectItem(at: index)
            }
        }

        if let value = trackRow["rating"] as? Int {
            rating.integerValue = value
        }
        else {
            rating.integerValue = 0
        }
        if let value = trackRow["favorite"] as? Bool {
            if value == true {
                favorite.state = NSOnState
            }
            else {
                favorite.state = NSOffState
            }
        }
        else {
            favorite.state = NSOffState
        }
        if let value = trackRow["notes"] as? String {
            notes.stringValue = value
        }
        else {
            notes.stringValue = ""
        }
        if let value = trackRow["last_played"] as? String {
            let ISO8601DateFormatter = DateFormatter()
            ISO8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
            ISO8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ISO8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = ISO8601DateFormatter.date(from: value) {
                //print("date: ", date)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
                lastPlayedDate.stringValue = dateFormatter.string(from: date)
            }
            else {
                print("Last Played date error. Value: ", value)
            }
        }
        else {
            lastPlayedDate.stringValue = ""
        }
        if let value = trackRow["play_count"] as? Int {
            playCount.integerValue = value
        }

        if requestType == RequestType.update {
            trackMetadataFilter = trackMetadata.filterByTrack(id: trackRow["id"] as! Int)
            //print("trackMetadataFilter count: ", trackMetadataFilter.count)
            for metadatum in trackMetadataFilter {
                //print("metadatum: ", metadatum)
                for index in 0..<augmentedTrackTags.count {
                    if metadatum["track_tag_id"] as! Int == augmentedTrackTags[index]["id"] as! Int {
                        augmentedTrackTags[index]["selected"] = true
                        augmentedTrackTags[index]["metadata_id"] = metadatum["id"] as! Int
                    }
                }
            }
            metadata.reloadData()
        }
        // Since no changes have been made, only allow cancel to terminate
        // Buttons are enabled in postEvent()
        processButton.isEnabled = false
        addAndRepeatButton.isEnabled = false
        // set the state machine
        inputStatus = [:]
        dialogState = DialogState.ready

        composition.becomeFirstResponder()
    }
    //################################################################################################
    @IBAction func ratingAction(_ sender: Any) {
        //print("rating field value: ", rating.stringValue)
        postEvent(input: "rating", status: InputStatus.valid)
    }
    //################################################################################################
    @IBAction func favoriteAction(_ sender: Any) {
        //print("favorite field value: ", favorite.stringValue)
        postEvent(input: "favorite", status: InputStatus.valid)
    }
    //################################################################################################
    @IBAction func synchronizeClicked(_ sender: NSButton) {
        //var trackUpdates: Dictionary<String, Any> = [:]
        let persistentID = trackRow["persistent_id"] as! String
        if persistentID != "" {
            do {
                playedDate = try iTunes.tracks[ITUIts.persistentID == persistentID].playedDate.get()
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
                lastPlayedDate.stringValue = dateFormatter.string(from: (playedDate!))
                //print("playedDate: ", playedDate)
            }
            catch {
                print("no date returned")
            }

            do {
                let playedCount = try iTunes.tracks[ITUIts.persistentID == persistentID].playedCount.get() as Int
                playCount.integerValue = playedCount
                postEvent(input: "sync", status: InputStatus.valid)
            }
            catch {
                print("Track synchronization failed")
            }
        }
    }
    //################################################################################################
    @IBAction func processAndRepeatButtonPressed(_ sender: Any) {
        repeatAdd = true
        processRow()
    }
    //################################################################################################
    @IBAction func processButtonPressed(_ sender: Any) {
        repeatAdd = false
        processRow()
    }
    //################################################################################################
    func processRow() {
        var tableRow: [String: Any] = [:]
        let index = composition.indexOfSelectedItem
        //NSLog("composition indexOfSelectedItem")
        tableRow["composition_id"] = compositions.table[index]["id"]
        tableRow["track"] = track.integerValue
        tableRow["disk"] = disk.integerValue
        tableRow["take"] = take.stringValue
        tableRow["time"] = time.stringValue

        if tempo.indexOfSelectedItem > -1 {
            tableRow["tempo_id"] = tempos.table[tempo.indexOfSelectedItem]["id"]
        }

        if group.indexOfSelectedItem > -1 {
            tableRow["group_id"] = groups.table[group.indexOfSelectedItem]["id"]
        }

        if source.indexOfSelectedItem > -1 {
            tableRow["source_id"] = sources.table[source.indexOfSelectedItem]["id"]
        }

        if favorite.state == NSOnState {
            tableRow["favorite"] = true
        }
        else {
            tableRow["favorite"] = false
        }

        tableRow["rating"] = rating.integerValue
        tableRow["notes"] = notes.stringValue

        if playedDate != nil {
            tableRow["last_played"] = "\(playedDate!)"
        }

        tableRow["play_count"] = playCount.integerValue

        if requestType == RequestType.add {
            tableRow["record_id"] = trackRow["record_id"]
            tracks.addRowAndNotify(rowData: tableRow)
            if repeatAdd == true {
                initializeDialog()
            }
        }
        else {
            let rowID = String(describing: trackRow["id"]!)
            //print("tableRow: ", tableRow, " row: ", rowID)
            tracks.updateRowAndNotify(row: rowID, rowData: tableRow)

            for index in 0..<augmentedTrackTags.count {
                //print("augmentedTrackTags row: ", augmentedTrackTags[index])
                if (augmentedTrackTags[index]["selected"] as! Bool == true) &&
                       (augmentedTrackTags[index]["metadata_id"] as! Int == 0) {
                    var newMetadata: [String:Any] = [:]
                    newMetadata["track_id"] = trackRow["id"]
                    newMetadata["track_tag_id"] = augmentedTrackTags[index]["id"]
                    //print("add metadata: ", newMetadata)
                    trackMetadata.addRowAndNotify(rowData: newMetadata)
                    continue
                }
                if (augmentedTrackTags[index]["selected"] as! Bool == false) &&
                       (augmentedTrackTags[index]["metadata_id"] as! Int != 0) {
                    let rowID = String(describing: augmentedTrackTags[index]["metadata_id"]!)
                    print("delete metadata id: ", rowID)
                    trackMetadata.deleteRowAndNotify(row: rowID)
                    continue
                }
            }
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    func postEvent(input: String, status: InputStatus) {
        //print("in postEvent - input: ", input, " status: ", status)
        inputStatus[input] = status
        switch dialogState {
            case DialogState.ready:
                if status == InputStatus.invalid {
                    dialogState = DialogState.invalid
                    processButton.isEnabled = false
                    addAndRepeatButton.isEnabled = false
                }
                else {
                    dialogState = DialogState.valid
                    processButton.isEnabled = true
                    addAndRepeatButton.isEnabled = true
                }

            case DialogState.valid:
                if status == InputStatus.invalid {
                    dialogState = DialogState.invalid
                    processButton.isEnabled = false
                    addAndRepeatButton.isEnabled = false
                }

            case DialogState.invalid:
                if status == InputStatus.valid {
                    var result = InputStatus.valid
                    for row in inputStatus {
                        if row.value == InputStatus.invalid {
                            result = InputStatus.invalid
                            break
                        }
                    }
                    if result == InputStatus.valid {
                        dialogState = DialogState.valid
                        processButton.isEnabled = true
                        addAndRepeatButton.isEnabled = true
                    }
                }
        }
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
    func addComposition(name: String) {
        var row: Dictionary<String, Any> = [:]
        row["name"] = name
        row["style_id"] = 61
        compositions.addRowAndNotify(rowData: row)
    }
    //################################################################################################
    func isValid() -> Bool {
        return true
    }
    //####################################################################################################
    @objc private func onItemClicked() {
        //print("row \(metadata.clickedRow), col \(metadata.clickedColumn) clicked")
        let clickedRow = metadata.clickedRow
        let clickedColumn = metadata.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if augmentedTrackTags[clickedRow]["selected"] as! Bool == true {
                augmentedTrackTags[clickedRow]["selected"] = false
            }
            else {
                augmentedTrackTags[clickedRow]["selected"] = true
            }
            postEvent(input: "metadata", status: InputStatus.valid)
            metadata.reloadData()
        }
    }
}
//####################################################################################################
//####################################################################################################

extension TrackDialogViewController: NSComboBoxDataSource {

    //################################################################################################
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //print("Starting numberOfItems. comboBox.tag", comboBox.tag)
        var count = 0
        switch comboBox.tag {
            case compositionTableTag:
                count = compositions.table.count
            case tempoTableTag:
                count = tempos.table.count
            case groupTableTag:
                count = groups.table.count
//            case moodTableTag:
//                count = moods.table.count
            case sourceTableTag:
                count = sources.table.count
//            case accessibilityTableTag:
//                count = accessibilities.table.count
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
            case compositionTableTag:
                let compositionRow: Dictionary<String, Any> = compositions.table[index]
                if let val = compositionRow["name"] as? String {
                    entry = val
                    //print("entry: ", entry)
                }
            case tempoTableTag:
                let tempoRow: Dictionary<String, Any> = tempos.table[index]
                //if let val = tempoRow["name"] as? String {
                if let val = tempoRow["name"] as? String {
                    entry = val
                }
            case groupTableTag:
                let groupRow: Dictionary<String, Any> = groups.table[index]
                if let val = groupRow["name"] as? String {
                    entry = val
                }
            case sourceTableTag:
                let sourceRow: Dictionary<String, Any> = sources.table[index]
                if let val = sourceRow["name"] as? String {
                    entry = val
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
            case compositionTableTag:
                index = findMatch(table: compositions.table, string: string)
            case tempoTableTag:
                index = findMatch(table: tempos.table, string: string)
            case groupTableTag:
                index = findMatch(table: groups.table, string: string)
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
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        //print("Starting textShouldEndEditing - tag: ", control.tag, "selectedRow: ", composition.indexOfSelectedItem)
        var result: Bool = true
        switch control.tag {
            case compositionTableTag:
                if composition.indexOfSelectedItem == -1 {
                    if (dialogOKCancel(question: "Entry not found.", text: "Entry is not in the table, Add it?")) {
                        addComposition(name: composition.stringValue)
                        result = true     // add a new composition
                    }
                    else {
                        result = false    // remain in the field
                        postEvent(input: "composition", status: InputStatus.invalid)
                    }
                }
                else {
                    postEvent(input: "composition", status: InputStatus.valid)
                }
            case diskFieldTag:
                // todo: validate against existing disks
                if disk.integerValue == 0 {
                    postEvent(input: "disk", status: InputStatus.invalid)
                    result = false
                }
                else {
                    postEvent(input: "disk", status: InputStatus.valid)
                }
            case trackFieldTag:
                if track.integerValue == 0 {
                    postEvent(input: "track", status: InputStatus.invalid)
                    result = false
                }
                else {
                    if track.integerValue != originalTrack {
                        var data: Dictionary<String, Any> = [:]
                        data["disk"] = disk.integerValue
                        data["track"] = track.integerValue
                        result = delegate.verifyInput(field: "track", input: data)
                        if result == false {
                            dialogErrorReason(text: "The track you entered is a duplicate.")
                            postEvent(input: "track", status: InputStatus.invalid)
                        }
                        else {
                            postEvent(input: "track", status: InputStatus.valid)
                        }
                    }
                    else {
                        postEvent(input: "track", status: InputStatus.valid)
                    }
                }
            case takeFieldTag:
                //print("take should end value: ", take.stringValue)
                postEvent(input: "take", status: InputStatus.valid)
            case timeFieldTag:
                //print("time should value: ", time.stringValue)
                postEvent(input: "tim", status: InputStatus.valid)
            case notesFieldTag:
                //print("notes should end value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)
            default:
                print("Tag not found in textShouldEndEditing")
                break
        }
        return result
    }
}

//####################################################################################################

extension TrackDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    // The only purpose for handling this notification is to record a change in 'select only' comboboxes
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //print("Starting comboBoxSelectionDidChange. Tag: ", comboBox.tag)
        switch comboBox.tag {
            case compositionTableTag:
                postEvent(input: "composition", status: InputStatus.valid)
            case tempoTableTag:
                postEvent(input: "tempo", status: InputStatus.valid)
            case groupTableTag:
                postEvent(input: "group", status: InputStatus.valid)
            case sourceTableTag:
                postEvent(input: "source", status: InputStatus.valid)
            default:
                break
        }
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, completedString string: String) -> String? {
        //print("Starting completedString. Tag: ", aComboBox.tag)
        var returnString = ""
        switch aComboBox.tag {
            case compositionTableTag:
                returnString = findFirstOccurrence(table: compositions.table, string: string)
            case tempoTableTag:
                returnString = findFirstOccurrence(table: tempos.table, string: string)
            case groupTableTag:
                returnString = findFirstOccurrence(table: groups.table, string: string)
            case sourceTableTag:
                returnString = findFirstOccurrence(table: sources.table, string: string)
            default:
                break
        }
        return returnString
    }
    //################################################################################################
    // This function only works when the table contains a "name" entry
    func findFirstOccurrence(table: [[String: Any]], string: String) -> String {
        //print("Starting findFirstOccurrence parm string: ", string)
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
        //print("findFirstOccurrence returning: ", returnString)
        return returnString
    }
    //################################################################################################
/*    func comboBoxWillPopUp(_ notification: Notification) {
/*        if let searchStr = notification.object?.string{
            self.filterDataArray(searchStr)
        }*/
        //print("comboBoxWillPopUp")
    }*/
    //################################################################################################
    override func controlTextDidChange(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        //print("text did change: ", control)
        switch control.tag {
            case compositionTableTag:
                //print("character count: ", composition.stringValue.characters.count)
                if composition.stringValue.characters.count > 60 {
                    composition.stringValue = compositionSave
                    NSBeep()
                }
                else {
                    compositionSave = composition.stringValue
                }
                break
            case diskFieldTag:
                //print("disk field value: ", disk.integerValue)
                if disk.integerValue == 0 {
                    postEvent(input: "disk", status: InputStatus.invalid)
                }
            case trackFieldTag:
                //print("track field value: ", track.integerValue)
                if track.integerValue == 0 {
                    postEvent(input: "track", status: InputStatus.invalid)
                }
            case takeFieldTag:
                //print("take field value: ", take.stringValue)
                postEvent(input: "take", status: InputStatus.valid)
            case timeFieldTag:
                //print("time field value: ", time.stringValue)
                postEvent(input: "time", status: InputStatus.valid)
            /*case ratingFieldTag:
                print("rating field value: ", time.stringValue)
                postEvent(input: "rating", status: VALID)*/
            case notesFieldTag:
                //print("notes field value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)
            default:
                break
        }
    }
}

//####################################################################################################
//####################################################################################################

extension TrackDialogViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case metadataTableTag:
                count = augmentedTrackTags.count
            default:
                count = 0
        }
        return count
    }
}

//####################################################################################################
//####################################################################################################

extension TrackDialogViewController: NSTableViewDelegate {

    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        // which row was selected?
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        switch tag {
            case metadataTableTag:
                // selectedRow is -1 if you click in the table, but not on a row
                selectedMetadata = selectedRow
//                if (selectedRow >= 0) {

            //if let value = filers.table[selectedRow]["name"] as? String {
            //    titleOutput.stringValue = value
            //}
//                }
            default:
                print("Filter table selection did change entered the default")
        }
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let column = tableColumn!.identifier
        //print("column: ", column)
        // blank it here to avoid multiple settings below
        result.textField?.stringValue = ""

        switch tableView.tag {
            case metadataTableTag:
                // get the "Item" for the row
                let item = augmentedTrackTags[row]

                switch column {
                    case "selected":
                        //print("tag row: ", item)
                        if item["selected"] as! Bool == true {
                            result.textField?.stringValue = "✽"
                            //✽
                            //HEAVY TEARDROP-SPOKED ASTERISK
                            //Unicode: U+273D, UTF-8: E2 9C BD
                        }
                    case "name":
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                    default:
                        print("Unknown column in metadata view table: ", column)
                }
            default:
                print("Metadata table column entered the default")
        }
        return result
    }
}
