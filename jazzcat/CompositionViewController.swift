//
//  CompositionViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 30/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class CompositionViewController: JazzCatViewController {

    var requestType: RequestType!

    let compositions = Compositions.shared

    var filteredCompositions: [[String:Any]] = []
    var compositionFilterActive: Bool = false
    let compositionTableViewTag = 1
    // -1 means no selection
    var selectedComposition: Int = -1

    @IBOutlet weak var compositionTableView: NSTableView!
    @IBOutlet var compositionTableViewMenu: NSMenu!

    let composers = Composers.shared

    let composerTableTag = 2
    var selectedComposer: Int = -1
    // -1 means no selection
    var composersFilter: [[String: Any]] = []
    @IBOutlet weak var composerTable: NSTableView!
    @IBOutlet var composerTableViewMenu: NSMenu!

    //let records = Records.shared
    let tracks = Tracks.shared

    let recordTableTag = 3
    var selectedRecord: Int = -1
    var recordsFilter: [[String: Any]] = []
    @IBOutlet weak var recordTable: NSTableView!
    @IBOutlet var recordTableViewMenu: NSMenu!

    let styles = Styles()

    let compositionMetadata = CompositionMetadata.shared

    let compositionTags = CompositionTags.shared

    var compositionFilter: [[String:Any]] = []
    let compositionFilterTableViewTag = 4
    var selectedCompositionTag: Int = -1
    var clearFilterRequested: Bool = false
    @IBOutlet weak var compositionFilterTableView: NSTableView!

    @IBOutlet weak var filterButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!

    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var year_written: NSTextField!
    @IBOutlet weak var year_published: NSTextField!
    @IBOutlet weak var style_name: NSTextField!
    @IBOutlet weak var notes: NSTextField!
    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        clearButton.isEnabled = false

        composerTable.tag = composerTableTag
        composerTable.doubleAction = #selector(composerTableDoubleClick(_:))

        recordTable.tag = recordTableTag

        styles.loadTable()

        compositionTableView.tag = compositionTableViewTag
        compositions.loadTable()
        compositionTableView.reloadData()
        compositionTableView.doubleAction = #selector(compositionTableViewDoubleClick(_:))

        compositionTags.loadTable()
        compositionFilter = compositionTags.table
        for index in 0..<compositionFilter.count {
            compositionFilter[index]["include"] = false
            //compositionFilter[index]["exclude"] = false
        }
        compositionFilterTableView.tag = compositionFilterTableViewTag
        compositionFilterTableView.reloadData()
        compositionFilterTableView.action = #selector(onCompositionItemClicked)

        let nc = NotificationCenter.default
        nc.addObserver(forName:composerUpdateNotification, object:nil, queue:nil, using:catchComposerNotification)
        nc.addObserver(forName:compositionUpdateNotification, object:nil, queue:nil, using:catchCompositionNotification)
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
            if selectedComposition == -1 {
                if compositions.table.count > 0 {
                    selectedComposition = 0
                }
            }
            compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
            compositionTableView.scrollRowToVisible(selectedComposition)
        }
    }
    //################################################################################################
    override func selectRow(selectionData: [String:Any]) {
        //print("In Composition selectRow")
        var index = -1
        if let compositionID = selectionData["id"] as? Int {
            if compositionFilterActive == true {
                if let index = filteredCompositions.index(where: { (composition) -> Bool in
                        composition["id"] as! Int == compositionID }) {
                    selectedComposition = index
                }
                else {
                    let message = "Remove the filter?"
                    if (dialogOKCancel(question: "Selected entry filtered out.", text: message)) {
                        clearFilterRequested = true
                        index = compositions.getIndex(foreignKey: compositionID)
                    }
                    else {
                        index = -1
                    }
                }
            }
            else {
                 index = compositions.getIndex(foreignKey: compositionID)
            }
            if index > -1 {
                selectedComposition = index
            }
            compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
            compositionTableView.scrollRowToVisible(selectedComposition)
        }
        else {
            print("CompositionViewController:selectRow - Incorrect selection data received.")
            return
        }
    }
    //################################################################################################
    func catchComposerNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let composer = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", artist)
        let id = compositions.table[selectedComposition]["id"] as! Int
        //print("composition id: ", id)
        composersFilter = composers.filterArtistsByComposition(id: id)
        //print("composersFilter: ", composersFilter)

        if changeType == "add" || changeType == "update" {
            if let key = composer?["id"] as? Int {
                for (index, row) in composersFilter.enumerated() {
                    if row["id"] as! Int == key {
                        selectedComposer = index
                    }
                }
            }
        }
        if changeType == "delete" {
            if composersFilter.count == 0 {
                selectedComposer = -1
            }
            else {
                if selectedComposer >= composersFilter.count {
                    selectedComposer -= 1
                }
            }
        }
        composerTable.reloadData()
        composerTable.selectRowIndexes(NSIndexSet(index: selectedComposer) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func catchCompositionNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let composition = notification.object as? [String: Any]?
        else {
            print("CompositionViewController: no userInfo found in notification")
            return
        }
        //print("track: ", composition)
        compositionTableView.reloadData()
        if changeType == "add" {
            if let key = composition?["id"] as? Int {
                selectedComposition = compositions.getIndex(foreignKey: key)
            }
        }
        if changeType == "delete" {
            if selectedComposition >= compositions.table.count {
                selectedComposition -= 1
            }
        }
        if changeType == "update" {
            selectedComposition = compositions.getIndex(foreignKey: composition?["id"] as! Int)
        }
        compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
        compositionTableView.scrollRowToVisible(selectedRecord)
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
        /*if clickedColumn == 2 {
            if compositionFilter[clickedRow]["exclude"] as! Bool == true {
                compositionFilter[clickedRow]["exclude"] = false
            }
            else {
                compositionFilter[clickedRow]["exclude"] = true
            }
            compositionFilterTableView.reloadData()
        }*/
    }
    //################################################################################################
    @IBAction func filterButtonClicked(_ sender: NSButton) {
        filteredCompositions = []
        for composition in compositions.table {
            // metadata are the tags assoicated with the composition
            let metadata = compositionMetadata.filterByComposition(id: composition["id"] as! Int)
            if metadata.count == 0 { continue }
            for item in metadata {
                for tag in compositionFilter {
                    if tag["id"] as! Int == item["composition_tag_id"] as! Int && tag["include"] as! Bool == true {
                        filteredCompositions.append(composition)
                    }
                }
            }
        }
        clearButton.isEnabled = true
        compositionFilterActive = true
        compositionTableView.reloadData()
        if filteredCompositions.count > 0 {
            if selectedComposition > -1 {
                // filteredCompositions is a subset of compositions so make sure the selected composition is still there
                let id = compositions.table[selectedComposition]["id"] as! Int
                selectedComposition = 0
                for (index, tableRow) in filteredCompositions.enumerated() {
                    if tableRow["id"] as! Int == id {
                        selectedComposition = index
                        break
                    }
                }
            }
            else {
                selectedComposition = 0
            }
        }
        else {
            // The filter is empty
            selectedComposition = -1
        }
        if selectedComposition > -1 {
            compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
            compositionTableView.scrollRowToVisible(selectedComposition)
        }
    }
    //################################################################################################
    @IBAction func clearButtonClicked(_ sender: NSButton) {
        if selectedComposition > -1 {
            let id = filteredCompositions[selectedComposition]["id"] as! Int
            selectedComposition = compositions.getIndex(foreignKey: id)
        }
        clearFilter()
    }
    //################################################################################################
    func clearFilter() {
        compositionFilterActive = false
        compositionTableView.reloadData()
        for index in 0..<compositionFilter.count {
            compositionFilter[index]["include"] = false
        }
        compositionFilterTableView.reloadData()
        clearButton.isEnabled = false
        compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
        compositionTableView.scrollRowToVisible(selectedComposition)
    }
    //################################################################################################
    @IBAction func addComposition(_ sender: NSButton) {
        callCompositionDialog(type: RequestType.add)
    }
    //################################################################################################
    @IBAction func editCompositionMenuItemClicked(_ sender: NSMenuItem) {
        callCompositionDialog(type: RequestType.update)
    }
    //################################################################################################
    func compositionTableViewDoubleClick(_ sender: AnyObject) {
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

            compositionTableView.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
            self.view.window!.makeKey()
            compositionTableView.becomeFirstResponder()
        }
    }
    //################################################################################
    @IBAction func deleteComposition(_ sender: NSButton) {
        let deleteID = String(describing: compositions.table[selectedComposition]["id"]!)
        compositions.deleteRowAndNotify(row: deleteID)
    }
    //################################################################################################
    @IBAction func goToArtistMenuItemClicked(_ sender: NSMenuItem) {
        if selectedComposer > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.artists
            selectionData["id"] = composersFilter[selectedComposer]["artist_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func goToRecordMenuItem(_ sender: NSMenuItem) {
        if selectedRecord > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.records
            selectionData["id"] = recordsFilter[selectedRecord]["id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification, object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    func filterComposers(foreignKey: Int) {
        composersFilter = composers.filterArtistsByComposition(id: foreignKey)
        composerTable.reloadData()
    }
    //################################################################################################
    func filterRecords(compositionID: Int) {
        recordsFilter = tracks.filterTracksByComposition(id: compositionID)
        recordTable.reloadData()
    }
    //################################################################################################
    @IBAction func addComposer(_ sender: Any) {
        callComposerDialog(type: RequestType.add)
    }
    //################################################################################################
    func composerTableDoubleClick(_ sender: AnyObject) {
        callComposerDialog(type: RequestType.update)
    }
    //################################################################################################
    func callComposerDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let composerDialogWindowController = storyboard.instantiateController(withIdentifier: "composerWindowControllerScene")
        as! NSWindowController

        if let composerDialogWindow = composerDialogWindowController.window {
            let composerDialogViewController = composerDialogWindow.contentViewController as! ComposerDialogViewController
            requestType = type
            composerDialogViewController.delegate = self
            let application = NSApplication.shared()

            application.runModal(for: composerDialogWindow)
            //composerTable.selectRowIndexes(NSIndexSet(index: selectedComposition) as IndexSet, byExtendingSelection: false)
            self.view.window!.makeKey()
            composerTable.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func deleteComposer(_ sender: NSButton) {
        if selectedComposer == -1 {
            return
        }
        let deleteID = String(describing: composersFilter[selectedComposer]["id"]!)
        composers.deleteRowAndNotify(row: deleteID)
    }
}
//####################################################################################################
//####################################################################################################
extension CompositionViewController: tableDataDelegate {

    //################################################################################################
/*    func putDataSourceRow(entity: DataEntity, row: Dictionary<String, Any>) {
        switch entity {
            case DataEntity.composer:
                filterComposers(foreignKey: compositions.table[selectedComposition]["id"] as! Int)
                composerTable.reloadData()

            case DataEntity.composition:
                compositions.isLoaded = false   // force reload
                compositions.loadTable()
                compositionTableView.reloadData()

            default:
                break
        }
    }*/
    //############################################################################################
    func getRequestType() -> RequestType {
        return requestType
    }
    //############################################################################################
    func verifyInput(field: String, input: Any) -> Bool {
        let result: Bool = true
        switch field {
            case "composition":
                break
            default:
                print("Invalid input passed in verifyInput")
        }
        return result
    }
    //############################################################################################
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any> {
        //print("selected track: ", selectedTrack)
        var returnData: Dictionary<String, Any> = [:]
        switch entity {
            case DataEntity.composer:
                if request == RequestType.update {
                    //print("getData - selectedComposer: ", selectedComposer)
                    returnData = composersFilter[selectedComposer]
                }
                else {
                    returnData["composition_id"] = compositions.table[selectedComposition]["id"]
                }
            case DataEntity.composition:
                if request == RequestType.update {
                    if compositionFilterActive == true {
                        returnData = filteredCompositions[selectedComposition]
                    }
                    else {
                        returnData = compositions.table[selectedComposition]
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
extension CompositionViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case compositionFilterTableViewTag:
                count = compositionFilter.count
            case compositionTableViewTag:
                if compositionFilterActive == true {
                    count = filteredCompositions.count
                }
                else {
                    count = compositions.table.count
                }
            case composerTableTag:
                count = composersFilter.count
            case recordTableTag:
                count = recordsFilter.count
                default:
                break
        }
        return count
    }
}
//################################################################################################
//################################################################################################
extension CompositionViewController: NSTableViewDelegate {

    func blankOutField(field: NSTextField) {
        field.stringValue = ""
    }
    //############################################################################################
    func blankOutFields() {
        blankOutField(field: name)
        blankOutField(field: year_published)
        blankOutField(field: year_written)
        blankOutField(field: notes)
    }
    //############################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        // which row was selected?
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        switch tag {
            case compositionFilterTableViewTag:
                selectedCompositionTag = selectedRow

            case compositionTableViewTag:
                selectedComposition = selectedRow
                if selectedRow >= 0 {
                    blankOutFields()
                    var composition: [String:Any] = [:]

                    if compositionFilterActive == true {
                        composition = filteredCompositions[selectedRow]
                    }
                    else {
                        composition = compositions.table[selectedRow]
                    }

                    if let value = composition["name"] as? String {
                        name.stringValue = value
                    }
                    if let value = composition["year_written"] as? Int {
                        year_written.integerValue = value
                    }
                    if let value = composition["year_published"] as? Int {
                        year_published.integerValue = value
                    }
                    if let style_id = composition["style_id"] as? Int {
                        let index =  styles.getIndex(foreignKey: style_id) as Int
                        if let value = styles.table[index]["name"] as? String {
                            style_name.stringValue = value
                        }
                    }
                    if let value = composition["notes"] as? String {
                        notes.stringValue = value
                    }
                    filterComposers(foreignKey: composition["id"] as! Int)
                    filterRecords(compositionID: composition["id"] as! Int)
                }

            case composerTableTag:
                selectedComposer = selectedRow

            case recordTableTag:
                selectedRecord = selectedRow

            default:
                print("tableViewSelectionDidChange - tag not found", tag)
        }
    }
    //############################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let column = tableColumn!.identifier
        // blank here once instead of in multiple places in the case statement
        result.textField?.stringValue = ""

        switch tableView.tag {
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
                    default:
                        print("Unknown column in filterTableView: ", column)
                }

                // get the value for this column
                if let val = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = val
                }

            case compositionTableViewTag:
                // get the "Item" for the row
                var item: [String:Any] = [:]
                if compositionFilterActive == true {
                    item = filteredCompositions[row]
                }
                else {
                    item = compositions.table[row]
                }

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
                else {
                    // if the attribute's value is missing enter a blank string
                    result.textField?.stringValue = ""
                }

            case composerTableTag:
                // get the "Item" for the row
                let item = composersFilter[row]

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
                else {
                    // if the attribute's value is missing enter a blank string
                    result.textField?.stringValue = ""
                }

            case recordTableTag:
                // get the "Item" for the row
                let item = recordsFilter[row]

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
                else {
                    // if the attribute's value is missing enter a blank string
                    result.textField?.stringValue = ""
                }
            default:
                print("tableView - tag not found")
        }
        return result
    }

}

