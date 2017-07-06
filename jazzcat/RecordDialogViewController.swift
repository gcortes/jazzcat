//
//  RecordDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 28/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class RecordDialogViewController: NSViewController {

    var delegate: tableDataDelegate!

    let records = Records.shared
    var recordRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!

    let artists = Artists.shared
    let artistTableTag = 1
    @IBOutlet weak var artist: NSComboBox!

    let labels = Labels.shared
    let labelTableTag = 2
    @IBOutlet weak var label: NSComboBox!

    let styles = Styles()
    let styleTableTag = 3
    @IBOutlet weak var style: NSComboBox!

    let recordMetadata = RecordMetadata.shared

    let metadataTableTag = 4
    var selectedMetadata = -1
    var recordMetadataFilter: [[String:Any]] = []
    @IBOutlet weak var metadata: NSTableView!

    let recordTags = RecordTags.shared
    var augmentedRecordTags: [[String:Any]] = []

    @IBOutlet weak var name: NSTextField!
    let nameFieldTag = 10
    @IBOutlet weak var recordingYear: NSTextField!
    let recordingYearFieldTag = 16
    @IBOutlet weak var recordingDate: NSTextField!
    let recordingDateFieldTag = 11
    @IBOutlet weak var penguinRating: NSTextField!
    let penguinRatingFieldTag = 12
    @IBOutlet weak var catalog: NSTextField!
    let catalogFieldTag = 13
    @IBOutlet weak var otherCatalog: NSTextField!
    let otherCatalogFieldTag = 14
    @IBOutlet weak var notes: NSTextField!
    let notesFieldTag = 15

    @IBOutlet weak var source: NSTextField!
    @IBOutlet weak var processButton: NSButton!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    var repeatAdd: Bool = false

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        artists.loadTable()
        artist.tag = artistTableTag
        artist.reloadData()

        labels.loadTable()
        label.tag = labelTableTag
        label.reloadData()

        styles.loadTable()
        style.tag = styleTableTag
        style.reloadData()

        recordMetadata.loadTable()
        metadata.tag = metadataTableTag

        recordTags.loadTable()
        augmentedRecordTags = recordTags.table
        recordMetadataFilter = []
        for index in 0..<augmentedRecordTags.count {
            augmentedRecordTags[index]["selected"] = false
            augmentedRecordTags[index]["metadata_id"] = 0
        }
        metadata.reloadData()
        metadata.action = #selector(onItemClicked)

        name.tag =  nameFieldTag
        recordingYear.tag = recordingYearFieldTag
        recordingDate.tag = recordingDateFieldTag
        penguinRating.tag = penguinRatingFieldTag
        catalog.tag = catalogFieldTag
        otherCatalog.tag = otherCatalogFieldTag
        notes.tag = notesFieldTag
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
        nc.addObserver(forName:artistUpdateNotification, object:nil, queue:nil, using:catchArtistNotification)
        nc.addObserver(forName:labelUpdateNotification, object:nil, queue:nil, using:catchLabelNotification)
        nc.addObserver(forName:recordUpdateNotification, object:nil, queue:nil, using:catchRecordNotification)
    }
    //################################################################################################
    func catchArtistNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let artistRow = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", artist)
        artist.reloadData()
        if changeType == "add" {
            if let key = artistRow?["id"] as? Int {
                let index = artists.getIndex(foreignKey: key)
                artist.selectItem(at: index)
                // todo: the post may be set for some external event.
                postEvent(input: "artist", status: InputStatus.valid)
            }
        }
    }
    //################################################################################################
    func catchLabelNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let labelRow = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", label)
        label.reloadData()
        if changeType == "add" {
            if let key = labelRow?["id"] as? Int {
                let index = labels.getIndex(foreignKey: key)
                label.selectItem(at: index)
                postEvent(input: "label", status: InputStatus.valid)
            }
        }
    }
    //################################################################################################
    // The last step after the add/update button it press is to add/update the record table. In the case
    // of the add, the row id is not available until to Rails API call is complete. With it, any metadata
    // can be added.
    func catchRecordNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let changeRow = notification.object as? [String: Any]
        else {
            print("No userInfo found in notification")
            let application = NSApplication.shared()
            application.stopModal()
            return
        }
        //print("catchRecordNotification - changeRow: ", changeRow)
        if changeType == "add" || changeType == "update" {
            for index in 0..<augmentedRecordTags.count {
                //print("augmentedRecordTags row: ", augmentedRecordTags[index])
                if (augmentedRecordTags[index]["selected"] as! Bool == true) &&
                       (augmentedRecordTags[index]["metadata_id"] as! Int == 0) {
                    var newMetadata: [String:Any] = [:]
                    newMetadata["record_id"] = changeRow["id"] as! Int
                    newMetadata["record_tag_id"] = augmentedRecordTags[index]["id"]
                    //print("add metadata: ", newMetadata)
                    recordMetadata.addRowAndNotify(rowData: newMetadata)
                    continue
                }
                if (augmentedRecordTags[index]["selected"] as! Bool == false) &&
                       (augmentedRecordTags[index]["metadata_id"] as! Int != 0) {
                    let rowID = String(describing: augmentedRecordTags[index]["metadata_id"]!)
                    //print("delete metadata id: ", rowID)
                    recordMetadata.deleteRowAndNotify(row: rowID)
                    continue
                }
            }
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    func initializeDialog() {
        recordRow = delegate.getDataSourceRow(entity: DataEntity.record, request: requestType)

        if requestType == RequestType.update {
            processButton.title = "Update"
        }
        else {
            processButton.title = "Add"
        }

        if let value = recordRow["name"] as? String {
            name.stringValue = value
        }
        if let foreignKey = recordRow["artist_id"] as? Int {
            let index = artists.getIndex(foreignKey: foreignKey)
            artist.stringValue = artists.table[index]["name"] as! String
            artist.selectItem(at: index)
        }
        if let value = recordRow["recording_year"] as? String {
            recordingYear.stringValue = value
        }
        if let value = recordRow["recording_date"] as? String {
            recordingDate.stringValue = value
        }
        if let value = recordRow["penguin"] as? String {
            penguinRating.stringValue = value
        }
        if let foreignKey = recordRow["label_id"] as? Int {
            let index = labels.getIndex(foreignKey: foreignKey)
            label.stringValue = labels.table[index]["name"] as! String
            label.selectItem(at: index)
        }
        if let value = recordRow["catalog"] as? String {
            catalog.stringValue = value
        }
        if let value = recordRow["alternate_catalog"] as? String {
            otherCatalog.stringValue = value
        }
        if let value = recordRow["notes"] as? String {
            notes.stringValue = value
        }
        else {
            notes.stringValue = ""
        }
        if let foreignKey = recordRow["style_id"] as? Int {
            let index = styles.getIndex(foreignKey: foreignKey)
            style.stringValue = styles.table[index]["name"] as! String
            style.selectItem(at: index)
        }
        else {
            let index = styles.getIndex(foreignKey: 61)
            style.stringValue = styles.table[index]["name"] as! String
            style.selectItem(at: index)
        }

        if requestType == RequestType.update {
            recordMetadataFilter = recordMetadata.filterByRecord(id: recordRow["id"] as! Int)
            //print("recordMetadataFilter count: ", recordMetadataFilter.count)
            for metadatum in recordMetadataFilter {
                //print("metadatum: ", metadatum)
                for index in 0..<augmentedRecordTags.count {
                    if metadatum["record_tag_id"] as! Int == augmentedRecordTags[index]["id"] as! Int {
                        augmentedRecordTags[index]["selected"] = true
                        augmentedRecordTags[index]["metadata_id"] = metadatum["id"] as! Int
                    }
                }
            }
            metadata.reloadData()
        }
        // Since no changes have been made, only allow cancel to terminate
        //processButton.isEnabled = false
        // set the state machine
        inputStatus = [:]
        dialogState = DialogState.ready
    }
    //################################################################################################
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func processButtonPressed(_ sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        tableRow["name"] = name.stringValue

        let artistIndex = artist.indexOfSelectedItem as Int
        if artistIndex > -1 {
            tableRow["artist_id"] = artists.table[artistIndex]["id"]
        }

        tableRow["recording_year"] = recordingYear.stringValue
        tableRow["recording_date"] = recordingDate.stringValue
        tableRow["penguin"] = penguinRating.stringValue

        let labelIndex = label.indexOfSelectedItem as Int
        if labelIndex > -1 {
            tableRow["label_id"] = labels.table[labelIndex]["id"]
        }

        tableRow["catalog"] = catalog.stringValue
        tableRow["alternate_catalog"] = otherCatalog.stringValue
        tableRow["notes"] = notes.stringValue

        let styleIndex = style.indexOfSelectedItem as Int
        if styleIndex > -1 {
            tableRow["style_id"] = styles.table[styleIndex]["id"]
        }

        if requestType == RequestType.add {
            records.addRowAndNotify(rowData: tableRow)
        }
        else {
            let rowID = String(describing: recordRow["id"]!)
            records.updateRowAndNotify(row: rowID, rowData: tableRow)
        }
    }
    //################################################################################################
    func postEvent(input: String, status: InputStatus){
        //print("in postEvent - input: ", input, " status: ", status)
        inputStatus[input] = status
        switch dialogState {
            case DialogState.ready:
                if status == InputStatus.invalid {
                    dialogState = DialogState.invalid
                    processButton.isEnabled = false
                }
                else {
                    dialogState = DialogState.valid
                    processButton.isEnabled = true
                }

            case DialogState.valid:
                if status == InputStatus.invalid {
                    dialogState = DialogState.invalid
                    processButton.isEnabled = false
                }

            case DialogState.invalid:
                if status == InputStatus.valid {
                    var result: InputStatus = InputStatus.valid
                    for row in inputStatus {
                        if row.value == InputStatus.invalid {
                            result = InputStatus.invalid
                            break
                        }
                    }
                    if result == InputStatus.invalid {
                        dialogState = DialogState.valid
                        processButton.isEnabled = true
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
    func dialogErrorReason(text: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = "Error"
        dialog.informativeText = text
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
    }
    //################################################################################################
    func addArtist(name: Dictionary<String, String>) {
        artists.addRowAndNotify(rowData: name)
    }
    //################################################################################################
    func addLabel(name: String) {
        var data: Dictionary<String, Any> = [:]
        data["name"] = name
        labels.addRowAndNotify(rowData: data)
    }
    //################################################################################################
    @objc private func onItemClicked() {
        //print("row \(metadata.clickedRow), col \(metadata.clickedColumn) clicked")
        let clickedRow = metadata.clickedRow
        let clickedColumn = metadata.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if augmentedRecordTags[clickedRow]["selected"] as! Bool == true {
                augmentedRecordTags[clickedRow]["selected"] = false
            }
            else {
                augmentedRecordTags[clickedRow]["selected"] = true
            }
            postEvent(input: "metadata", status: InputStatus.valid)
            metadata.reloadData()
        }
    }
}
//####################################################################################################
//####################################################################################################
// todo: add edits for records_date length, label selection, etc.
extension RecordDialogViewController: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //NSLog("number of items. comboBox.tag", comboBox.tag)

        var count: Int = 0
        switch comboBox.tag {
            case artistTableTag:
                count = artists.table.count
            case labelTableTag:
                count = labels.table.count
            case styleTableTag:
                count = styles.table.count
            default:
                print("numberOfItems invalid combobox tag: ", comboBox.tag)
        }
        return count
    }
    //################################################################################################
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        //NSLog("value from index: ", index)
        var entry: String = "object not found"
        switch comboBox.tag {
            case artistTableTag:
                entry = artists.table[index]["name"] as! String
            case labelTableTag:
                entry = labels.table[index]["name"] as! String
            case styleTableTag:
                entry = styles.table[index]["name"] as! String
            default:
                print("objectValueForItemAt Invalid combobox tag: ", comboBox.tag)
        }
        return entry
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        //NSLog("Starting indexOfItemWithStringValue: ", string)
        var index = NSNotFound
        switch aComboBox.tag {
            case artistTableTag:
                index = findMatch(table: artists.table, string: string)
            case labelTableTag:
                index = findMatch(table: labels.table, string: string)
            case styleTableTag:
                index = findMatch(table: styles.table, string: string)
            default:
                break
        }
        //NSLog("ending indexOfItemWithStringValue - index: ", index)
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
        //NSLog("Starting textShouldEndEditing - tag: ", control.tag, "selectedRow: ", artist.indexOfSelectedItem)
        var result: Bool = true
        switch control.tag {
            case nameFieldTag:
                //print("name should end value: ", name.stringValue)
                postEvent(input: "name", status: InputStatus.valid)
            case artistTableTag:
                if artist.indexOfSelectedItem == -1 {
                    let parsedName = artists.parseName(fullName: artist.stringValue)
                    let messageName = "first name: " + parsedName["first_name"]! +
                        " last name: " + parsedName["last_name"]!
                    let message = "Name not found. Do you wish to add " + messageName + " ?"
                    if (dialogOKCancel(question: "Entry not found.", text: message)) {
                        addArtist(name: parsedName)
                        result = true     // add a new artist
                    }
                    else {
                        result = false    // remain in the field
                        postEvent(input: "artist", status: InputStatus.invalid)
                    }
                }
                else {
                    postEvent(input: "artist", status: InputStatus.valid)
                }
            case recordingYearFieldTag:
                //print("recordingData should end value: ", recordingYear.stringValue)
                postEvent(input: "recordingYear", status: InputStatus.valid)
            case recordingDateFieldTag:
                //print("recordingData should end value: ", recordingDate.stringValue)
                postEvent(input: "recordingDate", status: InputStatus.valid)
            case penguinRatingFieldTag:
                //print("penguinRating should end value: ", penguinRating.stringValue)
                postEvent(input: "penguinRating", status: InputStatus.valid)
            case labelTableTag:
                //print("label should end value: ", label.stringValue)
                if label.indexOfSelectedItem == -1 {
                    let name = label.stringValue
                    let message = "Label not found, Do you wish to add " + name + "?"
                    if (dialogOKCancel(question: "Entry not fount", text: message)) {
                        addLabel(name: name)
                        result = true
                    }
                    else {
                        result = false
                        postEvent(input: "label", status: InputStatus.invalid)
                    }
                }
                else {
                    postEvent(input: "label", status: InputStatus.valid)
                }
            case catalogFieldTag:
                //print("catalog should end value: ", catalog.stringValue)
                postEvent(input: "catalog", status: InputStatus.valid)
            case otherCatalogFieldTag:
                //print("otherCatalog should value: ", otherCatalog.stringValue)
                postEvent(input: "otherCatalog", status: InputStatus.valid)
            case notesFieldTag:
                //print("notes should end value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)
            default:
                print("Tag not found in textShouldEndEditing")
        }
        return result
    }
}

//####################################################################################################
//####################################################################################################
extension RecordDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //NSLog("Starting comboBoxSelectionDidChange - Tag: ", comboBox.tag)
        switch comboBox.tag {
            case artistTableTag:
                postEvent(input: "artist", status: InputStatus.valid)
            case labelTableTag:
                postEvent(input: "label", status: InputStatus.valid)
            case styleTableTag:
                postEvent(input: "style", status: InputStatus.valid)
            default:
                break
        }
        //NSLog("Ending comboBoxSelectionDidChange: starting")
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, completedString string: String) -> String? {
        //NSLog("completed string starting. Tag: ", aComboBox.tag)
        var returnString = ""
        switch aComboBox.tag {
            case artistTableTag:
                returnString = findFirstOccurrence(table: artists.table, string: string)
            case labelTableTag:
                returnString = findFirstOccurrence(table: labels.table, string: string)
            case styleTableTag:
                break
                //print ("style tag")
            default:
                break
        }
        return returnString
    }
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
    override func controlTextDidChange(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        //NSLog("Starting controlTextDidChange: ", control.tag)
        switch control.tag {
            case nameFieldTag:
                //print("name field value: ", name.stringValue)
                postEvent(input: "name", status: InputStatus.valid)
            case artistTableTag:
                break
            case recordingYearFieldTag:
                //print("recordingYear field value: ", recordingYear.stringValue)
                postEvent(input: "recordingYear", status: InputStatus.valid)
            case recordingDateFieldTag:
                //print("recordingDate field value: ", recordingDate.stringValue)
                postEvent(input: "recordingDate", status: InputStatus.valid)
            case penguinRatingFieldTag:
                //print("name field value: ", penguinRating.stringValue)
                postEvent(input: "panguinRating", status: InputStatus.valid)
            case catalogFieldTag:
                //print("catalog field value: ", catalog.stringValue)
                postEvent(input: "catalog", status: InputStatus.valid)
            case otherCatalogFieldTag:
                //print("otherCatalog field value: ", otherCatalog.stringValue)
                postEvent(input: "otherCatalog", status: InputStatus.valid)
            case notesFieldTag:
                //print("notes field value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)
            case styleTableTag:
                break
            default:
                break
        }
    }
}
//####################################################################################################
//####################################################################################################
extension RecordDialogViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case metadataTableTag:
                count = augmentedRecordTags.count
            default:
                count = 0
        }
        return count
    }
}
//####################################################################################################
//####################################################################################################

extension RecordDialogViewController: NSTableViewDelegate {

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
                let item = augmentedRecordTags[row]

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
