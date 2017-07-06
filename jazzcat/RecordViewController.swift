//
//  RecordViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 20/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

class RecordViewController: JazzCatViewController {

    // Protocol support
    let iTunes = ITunes()
    var rowUpdate: Bool = false

    var requestType: RequestType!

    // Look up tables
    let artists = Artists.shared

    var selectedArtist: Int = -1

    let labels = Labels.shared

    let compositions = Compositions.shared

    var selectedComposition: Int = -1

    // Used to control music queue
    let musicQueue = MusicQueue.shared

    let records = Records.shared
    let filteredRecords = FilteredRecords()

    //var filteredRecords: [[String:Any]] = []
    var recordFilterActive: Bool = false
    let recordTableViewTag = 1
    var selectedRecordID: Int = -1
    // -1 means no selection
    var selectedRecord: Int = -1
    @IBOutlet weak var recordTableView: NSTableView!
    @IBOutlet weak var recordTableHeader: NSTableHeaderView!

    let tracks = Tracks.shared

    let trackTableTag = 2
    // -1 means no selection
    var selectedTrack: Int = -1
    var tracksFilter: [[String: Any]] = []
    @IBOutlet weak var trackTable: NSTableView!

    let credits = Credits.shared

    let creditsTableTag = 3
    // -1 means no selection
    var selectedCredit: Int = -1
    var creditsFilter: [[String: Any]] = []
    @IBOutlet weak var creditTable: NSTableView!

    let recordMetadata = RecordMetadata.shared
    let recordTags = RecordTags.shared

    var recordFilter: [[String:Any]] = []
    let recordFilterTableViewTag = 4
    var selectedRecordTag: Int = -1
    var clearFilterRequested: Bool = false
    @IBOutlet weak var recordFilterTableView: NSTableView!

    @IBOutlet weak var filterButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!

    @IBOutlet weak var alphabeticalSortRadioButton: NSButton!
    @IBOutlet weak var addedSortRadioButton: NSButton!
    @IBOutlet weak var recordedSortRadioButton: NSButton!

    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var leader: NSButton!
    @IBOutlet weak var recordingYear: NSTextField!
    @IBOutlet weak var recordingDate: NSTextField!
    @IBOutlet weak var penguinRating: NSTextField!
    @IBOutlet weak var label: NSButton!
    @IBOutlet weak var catalog: NSTextField!
    @IBOutlet weak var otherCatalog: NSTextField!
    @IBOutlet weak var notes: NSTextField!
    @IBOutlet weak var dateAdded: NSTextField!
    @IBOutlet weak var source: NSTextField!

    @IBOutlet var creditMenu: NSMenu!
    @IBOutlet weak var getArtistMenuItem: NSMenuItem!
    let getArtistMenuItemTag = 40
    @IBOutlet weak var getCreditMenuItem: NSMenuItem!
    let getCreditMenuItemTag = 41

    @IBOutlet var trackMenu: NSMenu!
    @IBOutlet weak var playTrack: NSMenuItem!
    let playTrackTag = 50
    @IBOutlet weak var getTrackInfo: NSMenuItem!
    let getTrackInfoTag = 51
    @IBOutlet weak var getCompositionInfo: NSMenuItem!
    let getCompositionInfoTag = 52

    @IBOutlet var recordMenu: NSMenu!
    @IBOutlet weak var syncWithITunes: NSMenuItem!
    @IBOutlet weak var editRecord: NSMenuItem!
    let syncWithITunesTag = 60

    @IBOutlet weak var queueLast: NSMenuItem!
    @IBOutlet weak var albumCover: NSImageView!
    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("Starting record view viewDidLoad")
        clearButton.isEnabled = false

        creditTable.target = self
        creditTable.doubleAction = #selector(creditTableDoubleClick(_:))
        trackTable.target = self
        trackTable.doubleAction = #selector(trackTableDoubleClick(_:))
        recordTableView.target = self
        recordTableView.doubleAction = #selector(recordTableViewDoubleClick(_:))

        //getArtistMenuItem.isEnabled = true
        getArtistMenuItem.tag = getArtistMenuItemTag
        getCreditMenuItem.tag = getCreditMenuItemTag

        playTrack.tag = playTrackTag
        getTrackInfo.tag = getTrackInfoTag
        getCompositionInfo.tag = getCompositionInfoTag

        syncWithITunes.tag = syncWithITunesTag

        // refresh the table with the data
        trackTable.tag = trackTableTag
        artists.loadTable()
        labels.loadTable()
        compositions.loadTable()

        creditTable.tag = creditsTableTag
        credits.loadTable()

        recordTableView.tag = recordTableViewTag
        records.loadTable()
        recordTableView.reloadData()

        recordTags.loadTable()
        recordFilter = recordTags.table
        for index in 0..<recordFilter.count {
            recordFilter[index]["include"] = false
        }
        recordFilterTableView.tag = recordFilterTableViewTag
        recordFilterTableView.reloadData()
        recordFilterTableView.action = #selector(onRecordItemClicked)

        let nc = NotificationCenter.default
        nc.addObserver(forName: recordUpdateNotification, object: nil, queue: nil, using: catchRecordNotification)
        nc.addObserver(forName: creditUpdateNotification, object: nil, queue: nil, using: catchCreditNotification)
        nc.addObserver(forName: trackUpdateNotification, object: nil, queue: nil, using: catchTrackNotification)
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()

        if clearFilterRequested == true {
            clearFilter()
            clearFilterRequested = false
        }
        else {
            // If no row selected, select the first one if there is one
            if selectedRecord == -1 {
                if records.table.count > 0 {
                    selectedRecord = 0
                }
            }
            recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
            recordTableView.scrollRowToVisible(selectedRecord)
        }
    }
    //################################################################################################
    override func selectRow(selectionData: [String:Any]) {
        //print("In Record selectRow")
        var index = -1
        if let recordID = selectionData["id"] as? Int {
            if recordFilterActive == true {
                index = filteredRecords.getIndex(foreignKey: recordID)
                if index == -1 {
                    let message = "Remove the filter?"
                    if (dialogOKCancel(question: "Selected entry filtered out.", text: message)) {
                        clearFilterRequested = true
                        index = records.getIndex(foreignKey: recordID)
                    }
                }
            }
            else {
                index = records.getIndex(foreignKey: recordID)
            }
            if index > -1 {
                selectedRecord = index
            }
            recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
            recordTableView.scrollRowToVisible(selectedRecord)
            // todo: finish track selection
            //if let trackID = selectionData["item"] as? Int {}
        }
        else {
            print("RecordViewController:selectRow - Incorrect selection data received.")
            return
        }
    }
    //################################################################################################
    func catchRecordNotification(notification: Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let recordRow = notification.object as? [String: Any]
            else {
            print("No userInfo found in notification")
            return
        }
        //print("record: ", record)
        recordTableView.reloadData()

        if changeType == "add" || changeType == "update" {
            if let key = recordRow["id"] as? Int {
                selectedRecord = (recordFilterActive ? filteredRecords.getIndex(foreignKey: key) :
                    records.getIndex(foreignKey: key))
            }
        }
        if changeType == "delete" {
            // todo: could break with a filter active
            if selectedRecord >= records.table.count {
                selectedRecord -= 1
            }
        }
        recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
        recordTableView.scrollRowToVisible(selectedRecord)
    }
    //################################################################################################
    @objc private func onRecordItemClicked() {
        //print("row \(recordFilterTableView.clickedRow), col \(recordFilterTableView.clickedColumn) clicked")
        let clickedRow = recordFilterTableView.clickedRow
        let clickedColumn = recordFilterTableView.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if recordFilter[clickedRow]["include"] as! Bool == true {
                recordFilter[clickedRow]["include"] = false
            }
            else {
                recordFilter[clickedRow]["include"] = true
            }
            recordFilterTableView.reloadData()
        }
    }
    //################################################################################################
    @IBAction func filterButtonClicked(_ sender: NSButton) {
        //filteredRecords = []
        for record in records.table {
            // metadata are the tags associated with the record
            let metadata = recordMetadata.filterByRecord(id: record["id"] as! Int)
            if metadata.count == 0 { continue }
            for item in metadata {
                for tag in recordFilter {
                    if tag["id"] as! Int == item["record_tag_id"] as! Int && tag["include"] as! Bool == true {
                        filteredRecords.table.append(record)
                        //filteredRecords.append(record)
                    }
                }
            }
        }
        clearButton.isEnabled = true
        recordFilterActive = true
        recordTableView.reloadData()
        if filteredRecords.table.count > 0 {
            if selectedRecord > -1 {
                // filteredRecords is a subset of records so make sure the selected record is still there
                let id = records.table[selectedRecord]["id"] as! Int
                selectedRecord = filteredRecords.getIndex(foreignKey: id)
            }
            else {
                selectedRecord = 0
            }
        }
        else {
            // The filter is empty
            selectedRecord = -1
        }
        if selectedRecord > -1 {
            recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
            recordTableView.scrollRowToVisible(selectedRecord)
        }
    }
    //################################################################################################
    @IBAction func clearButtonClicked(_ sender: NSButton) {
        if selectedRecord > -1 {
            let id = filteredRecords.table[selectedRecord]["id"] as! Int
            selectedRecord = records.getIndex(foreignKey: id)
        }
        clearFilter()
    }
    //################################################################################################
    func clearFilter() {
        recordFilterActive = false
        recordTableView.reloadData()
        for index in 0..<recordFilter.count {
            recordFilter[index]["include"] = false
        }
        recordFilterTableView.reloadData()
        clearButton.isEnabled = false
        recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
        recordTableView.scrollRowToVisible(selectedRecord)
    }
    //################################################################################################
    @IBAction func goToTrackMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            let trackID = tracksFilter[selectedTrack]["id"] as! Int
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.tracks
            selectionData["id"] = trackID
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification, object: selectionData)
        }
    }
    //################################################################################################
    @IBAction func missingAlbumsClicked(_ sender: NSMenuItem) {
        var trackAlbum: String = ""
        var trackArtist: String = ""
        var trackGenre: String = ""
        var reportedAlbums: [String] = []
        var reported: Bool = false
        var found: Bool = false
        for index in 8001...10700 {
            do {
                trackAlbum = try iTunes.tracks[index].album.get()
                trackArtist = try iTunes.tracks[index].artist.get()
                trackGenre = try iTunes.tracks[index].genre.get()
                found = false
                if trackGenre == "Classical" ||
                       trackGenre == "New Age" ||
                       trackGenre == "Blues" ||
                       trackGenre == "Rock & Roll" ||
                       trackGenre == "Rock" {
                    continue
                }
                for record in records.table {
                    if record["name"] as! String == trackAlbum {
                        //print("record name found: ", record["name"] as! String, " iTunes name: ", trackAlbum)
                        found = true
                        break
                    }
                }
                if found == true {
                    continue
                }
                if reportedAlbums.count == 0 {
                    reportedAlbums.append(trackAlbum)
                    print("Missing Album: ", trackAlbum, " Artist: ", trackArtist)
                    continue
                }
                reported = false
                for albumName in reportedAlbums {
                    if albumName == trackAlbum {
                        //print("reported name: ", record["name"] as! String, " iTunes name: ", trackAlbum)
                        reported = true
                        break
                    }
                }
                if reported == false {
                    reportedAlbums.append(trackAlbum)
                    //print("Missing Album: ", record["name"] as! String, " iTunes name: ", trackAlbum)
                    print("Missing Album: ", trackAlbum, " Artist: ", trackArtist)
                }
            }
            catch {
                print("track fetch error")
            }
        }
    }
    //################################################################################################
    @IBAction func radioButtonClicked(_ sender: NSButton) {
        if alphabeticalSortRadioButton.state == NSOnState {
            if recordFilterActive == true {
                filteredRecords.order(by: RecordSort.alphabetical)
            }
            else {
                records.order(by: RecordSort.alphabetical)
            }
        }
        else if addedSortRadioButton.state == NSOnState {
            if recordFilterActive == true {
                filteredRecords.order(by: RecordSort.added)
            }
            else {
                records.order(by: RecordSort.added)
            }
        }
        else {
            if recordFilterActive == true {
                filteredRecords.order(by: RecordSort.recorded)
            }
            else {
                records.order(by: RecordSort.recorded)
            }
        }
        recordTableView.reloadData()
    }
    //################################################################################################
    @IBAction func addRecord(_ sender: NSButton) {
        callRecordDialog(type: RequestType.add)
    }
    //################################################################################################
    @IBAction func removeRecord(_ sender: NSButton) {
        // make sure that an item is selected
        let deleteID = String(describing: records.table[selectedRecord]["id"]!)
        records.deleteRowAndNotify(row: deleteID)
    }
    //################################################################################################
    func recordTableViewDoubleClick(_ sender: AnyObject) {
        callRecordDialog(type: RequestType.update)
    }
    //################################################################################################
    @IBAction func editRecordMenuItemClicked(_ sender: NSMenuItem) {
        callRecordDialog(type: RequestType.update)
    }
    //################################################################################################
    func callRecordDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let recordDialogWindowController = storyboard.instantiateController(withIdentifier: "recordWindowControllerScene")
        as! NSWindowController

        if let recordDialogWindow = recordDialogWindowController.window {
            let recordDialogViewController = recordDialogWindow.contentViewController as! RecordDialogViewController
            requestType = type
            recordDialogViewController.delegate = self
            let application = NSApplication.shared()

            application.runModal(for: recordDialogWindow)

            recordTableView.selectRowIndexes(NSIndexSet(index: selectedRecord) as IndexSet, byExtendingSelection: false)
            self.view.window!.makeKey()
            recordTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func syncWithITunesClicked(_ sender: NSMenuItem) {
        callSyncDialog()
    }
    //################################################################################################
    func callSyncDialog() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let recordSyncDialogWindowController = storyboard.instantiateController(withIdentifier: "recordSyncWindowControllerScene")
        as! NSWindowController

        if let recordSyncDialogWindow = recordSyncDialogWindowController.window {
            let recordSyncDialogController = recordSyncDialogWindow.contentViewController as! RecordSyncDialogController
            recordSyncDialogController.delegate = self
            let application = NSApplication.shared()

            application.runModal(for: recordSyncDialogWindow)

            filterTracks(foreignKey: records.table[selectedRecord]["id"] as! Int)
            trackTable.reloadData()
            self.view.window!.makeKey()
            recordTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func labelButtonClicked(_ sender: Any) {
        var selectionData: [String: Any] = [:]
        selectionData["tab"] = TabType.labels
        selectionData["id"] = records.table[selectedRecord]["label_id"] as! Int
        let nc = NotificationCenter.default
        nc.post(name: tabSelectNotification, object: selectionData)
    }
    //################################################################################################
    @IBAction func getCompositionClicked(_ sender: NSMenuItem) {
        // todo: move this code to the called function
        let foreignKey: Int = tracksFilter[selectedTrack]["composition_id"] as! Int
        selectedComposition = compositions.getIndex(foreignKey: foreignKey)
        callCompositionDialog(type: RequestType.update)
    }
    //################################################################################################
    func callCompositionDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let compositionDialogWindowController = storyboard.instantiateController(withIdentifier: "compositionWindowControllerScene")
        as! NSWindowController

        if let compositionDialogWindow = compositionDialogWindowController.window {
            let compositionDialogViewController = compositionDialogWindow.contentViewController as! CompositionDialogViewController
            requestType = type
            compositionDialogViewController.delegate = self
            let application = NSApplication.shared()

            application.runModal(for: compositionDialogWindow)

            self.view.window!.makeKey()
            recordTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func goToArtistMenuItemClicked(_ sender: NSMenuItem) {
        if selectedCredit > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.artists
            selectionData["id"] = creditsFilter[selectedCredit]["artist_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func leaderButtonClicked(_ sender: NSButton) {
        var selectionData: [String:Any] = [:]
        selectionData["tab"] = TabType.artists
        selectionData["id"] = records.table[selectedRecord]["artist_id"] as! Int
        let nc = NotificationCenter.default
        nc.post(name:tabSelectNotification,
            object: selectionData)
    }
    //################################################################################################
    func callArtistDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let artistDialogWindowController = storyboard.instantiateController(withIdentifier: "artistWindowControllerScene")
        as! NSWindowController

        if let artistDialogWindow = artistDialogWindowController.window {
            let artistDialogViewController = artistDialogWindow.contentViewController as! ArtistDialogViewController
            requestType = type
            artistDialogViewController.delegate = self
            let application = NSApplication.shared()

            application.runModal(for: artistDialogWindow)

            self.view.window!.makeKey()
            recordTableView.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func goToCompositionMenuItemClicked(_ sender: NSMenuItem) {
        if selectedTrack > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.compositions
            selectionData["id"] = tracksFilter[selectedTrack]["composition_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
    }
    //################################################################################################
    func dialogErrorReason(text: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = "Error"
        dialog.informativeText = text
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
    }
}

//####################################################################################################
//####################################################################################################

extension RecordViewController: tableDataDelegate {

    //################################################################################################
    func getRequestType() -> RequestType {
        return requestType
    }
    //################################################################################################
    func verifyInput(field: String, input: Any) -> Bool {
        var result: Bool = true
        switch field {
            case "track":
                // Verify that the input is not a duplicate
                let data = input as! Dictionary<String, Any>
                for trackRow in tracksFilter {
                    if trackRow["disk"] as! Int == data["disk"] as! Int
                           && trackRow["track"] as! Int == data["track"] as! Int {
                        result = false
                        break
                    }
                }
            default:
                print("Invalid input passed in verifyInput")
        }
        return result
    }
    //################################################################################################
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any> {
        //print("selected track: ", selectedTrack)
        var returnData: Dictionary<String, Any> = [:]
        switch entity {
            case DataEntity.artist:
                returnData = artists.table[selectedArtist]
            case DataEntity.record:
                if request == RequestType.update {
                    returnData = (recordFilterActive ? filteredRecords.table[selectedRecord] : records.table[selectedRecord])
                }
            // There is no initial data for an add
            case DataEntity.track:
                if request == RequestType.update {
                    returnData = tracksFilter[selectedTrack]
                }
                else { // It's an add
                    returnData["record_id"] = records.table[selectedRecord]["id"]
                    returnData["disk"] = highestDisk()
                    returnData["track"] = nextTrack(disk: returnData["disk"] as! Int)
                }
            case DataEntity.composition:
                if request == RequestType.update {
                    returnData = compositions.table[selectedComposition]
                }
            case DataEntity.credit:
                if request == RequestType.update {
                    returnData = creditsFilter[selectedCredit]
                }
                else { // It's an add
                    returnData["record_id"] = records.table[selectedRecord]["id"]
                }
            default:
                break
        }
        return returnData
    }
}

//####################################################################################################
//####################################################################################################

extension RecordViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case recordFilterTableViewTag:
                count = recordFilter.count
            case recordTableViewTag:
                count = (recordFilterActive ? filteredRecords.table.count : records.table.count)
            case trackTableTag:
                count = tracksFilter.count
            case creditsTableTag:
                count = creditsFilter.count
            default:
                break
        }
        //print("number of rows: ", count)
        return count
    }
}

//####################################################################################################
//####################################################################################################

extension RecordViewController: NSTableViewDelegate {

    //################################################################################################
    func blankOutField(field: NSTextField) {
        field.stringValue = ""
    }
    //################################################################################################
    func blankOutFields() {
        blankOutField(field: recordingDate)
        blankOutField(field: catalog)
        blankOutField(field: otherCatalog)
        blankOutField(field: notes)
        blankOutField(field: dateAdded)
    }
    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        switch tag {
            case recordFilterTableViewTag:
                selectedRecordTag = selectedRow

            case recordTableViewTag:
                var foreignKey: Int = 0
                var key: Int = 0
                // which row was selected?
                // selectedRow is -1 if you click in the table, but not on a row
                selectedRecord = selectedRow
                //print("selected record: ", records.table[selectedRow])
                if (selectedRow >= 0) {
                    blankOutFields()
                    var record: [String:Any] = [:]
                    record = (recordFilterActive ? filteredRecords.table[selectedRow] : records.table[selectedRow])

                    if let value = record["name"] as? String {
                        name.stringValue = value
                    }

                    foreignKey = (record["artist_id"] as? Int)!
                    key = artists.getIndex(foreignKey: foreignKey)
                    if let value = artists.table[key]["name"] as? String {
                        leader.title = value
                    }

                    if let value = record["recording_year"] as? String {
                        recordingYear.stringValue = value
                    }

                    if let value = record["recording_date"] as? String {
                        recordingDate.stringValue = value
                    }

                    foreignKey = (record["label_id"] as? Int)!
                    key = labels.getIndex(foreignKey: foreignKey)
                    if let value = labels.table[key]["name"] as? String {
                        label.title = value
                    }

                    if let value = record["penguin"] as? String {
                        penguinRating.stringValue = value
                    }

                    if let value = record["catalog"] as? String {
                        catalog.stringValue = value
                    }

                    if let value = record["alternate_catalog"] as? String {
                        otherCatalog.stringValue = value
                    }

                    if let value = record["notes"] as? String {
                        notes.stringValue = value
                    }

                    if let value = record["date_added"] as? String {
                        let ISO8601DateFormatter = DateFormatter()
                        ISO8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        ISO8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        ISO8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                        if let date = ISO8601DateFormatter.date(from: value) {
                            //print("date: ", date)
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US")
                            dateFormatter.dateFormat = "dd MMM yyyy"
                            dateAdded.stringValue = dateFormatter.string(from: date)
                        }
                    }

                    filterTracks(foreignKey: record["id"] as! Int)
                    filterCredits(foreignKey: record["id"] as! Int)
                }
                else {
                    // if a valid row wasn't selected, blank out both fields
                    blankOutFields()
                }

            case trackTableTag:
                selectedTrack = selectedRow

            case creditsTableTag:
                selectedCredit = selectedRow

            default:
                print("Records View table selection did change entered the default")
        }
    }
    //################################################################################################
/*    func tableView(_ tableView: NSTableView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        //print("mouse down in header")
        switch tableView.tag {
            case recordTableViewTag:
                // There's only one column in this table
                if records.currentOrder == "name" {
                    records.orderRows(order: "recent")
                    recordTableView.reloadData()
                    //tableColumn.identifier = "Records by Date Added"
                }
                else {
                    records.isLoaded = false
                    records.loadTable()
                    recordTableView.reloadData()
                    //tableColumn.identifier = "Records by Name"
                }
            default:
                break
        }
    }*/
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let column = tableColumn!.identifier
        // blank it here to avoid multiple settings below
        result.textField?.stringValue = ""

        switch tableView.tag {
            case recordFilterTableViewTag:
                let item = recordFilter[row]
                //print("recordFiler row: ", item)
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
                    default:
                        print("Unknown column in filterTableView: ", column)
                }

                // get the value for this column
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }

            case recordTableViewTag:
                // get the "Item" for the row
                var item: [String:Any] = [:]
                item = (recordFilterActive ? filteredRecords.table[row] : records.table[row])

                switch column {
                    default: // Only one column for now
                        if let val = item[tableColumn!.identifier] as? String {
                            result.textField?.stringValue = val
                        }
                }

            case trackTableTag:
                let item = tracksFilter[row]
                // Only do this once as the image is the same for all tracks
                if row == 0 {
                    if let persistentID = item["persistent_id"] as? String {
                        do {
                            let results = try iTunes.tracks[ITUIts.persistentID == persistentID].artworks.get() as [[ITUItem]]
                            if results.count > 0 {
                                if results.count == 1 {
                                    let artWorks = results[0]
                                    if artWorks.count == 1 {
                                        let artWork = artWorks[0]
                                        //let format = try artWork.format.get()
                                        //print("format: ", format)
                                        let picture = try artWork.data_.get() as NSAppleEventDescriptor
                                        albumCover.image = NSImage(data: picture.data)
                                    }
                                    else {
                                        if artWorks.count == 0 {
                                            print("No artwork returned")
                                        }
                                        else {
                                            print("Multiple artworks found. row: ", row, " count: ", artWorks.count)
                                        }
                                    }
                                }
                                else {
                                    print("Image fetch returned more than one track")
                                }
                            }
                        }
                        catch {
                            print("art work fetch failed")
                        }
                    }
/*                    do {
                        if let persistentID = item["persistent_id"] as? String {
                            let added = try iTunes.tracks[ITUIts.persistentID == persistentID].dateAdded.get() as Date
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US")
                            dateFormatter.dateFormat = "dd MMM yyyy"
                            let stringDateAdded = dateFormatter.string(from: (added))
                            dateAdded.stringValue = stringDateAdded
                        }
                    }
                    catch {
                    }
*/
                }

                switch column {
                    case "track":
                        if let val = item[tableColumn!.identifier] as? Int {
                            result.textField?.integerValue = val
                        }

                    case "rating":
                        if let rating = item["rating"] as? Int {
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
                        if let favorite = item["favorite"] as? Bool {
                            if favorite == true {
                                result.textField?.stringValue = "\u{2665}"
                            }
                            //Unicode: U+2665 U+FE0E, UTF-8: E2 99 A5 EF B8 8E
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

                                let today = Date()
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
                        if let count = item["play_count"] as? Int {
                            result.textField?.integerValue = count
                        }

                    default: // take ...
                        if let val = item[column] as? String {
                            result.textField?.stringValue = val
                        }
                }
            case creditsTableTag:
                let item = creditsFilter[row]

                // get the value for this column
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }
            default:
                print("Records View table column entered the default")
        }
        return result
    }
}

//####################################################################################################
//####################################################################################################

extension RecordViewController: NSMenuDelegate {

    func numberOfItems(in menu: NSMenu) -> Int {
        print("Starting numberOfItems")
        return 2
    }

//####################################################################################################
    func menuNeedsUpdate(_ menu: NSMenu) {
        //print("Starting menuNeedsUpdate selectedCredit: ", selectedCredit)
        if selectedCredit == -1 {
            getArtistMenuItem.isEnabled = false
            getCreditMenuItem.isEnabled = false
        }
        else {
            getArtistMenuItem.isEnabled = true
            getCreditMenuItem.isEnabled = true
        }
    }

}
