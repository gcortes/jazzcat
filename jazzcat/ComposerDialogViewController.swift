//
//  ComposerDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 1/3/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa

class ComposerDialogViewController: NSViewController {

    var delegate: tableDataDelegate!

    let composers = Composers.shared
    var composerRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!

    let artists = Artists.shared
    let artistTableTag = 1
    @IBOutlet weak var artist: NSComboBox!

    @IBOutlet weak var role: NSTextField!
    let roleFieldTag = 10
    @IBOutlet weak var notes: NSTextField!
    let notesFieldTag = 11
    @IBOutlet weak var processButton: NSButton!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        //composers.loadTable()

        artists.loadTable()
        artist.tag = artistTableTag
        artist.reloadData()
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()
        if self.delegate == nil {
            print("Delegate not set. Exiting")
            let application = NSApplication.shared()
            application.stopModal()
        }

        role.tag = roleFieldTag
        notes.tag = notesFieldTag

        requestType = delegate.getRequestType()
        initializeDialog()

        let nc = NotificationCenter.default
        nc.addObserver(forName:artistUpdateNotification, object:nil, queue:nil, using:catchArtistNotification)
    }
    //################################################################################################
    func catchArtistNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let artistRow = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", artistRow)
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
    func initializeDialog() {
        // composerRow is from the flat_coreceives view
        composerRow = delegate.getDataSourceRow(entity: DataEntity.composer, request: requestType)
        //print("Starting initializeDialog. composerRow: ", composerRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
        }
        else {
            processButton.title = "Add"
        }

        if let foreignKey = composerRow["artist_id"] as? Int {
            let index = artists.getIndex(foreignKey: foreignKey)
            artist.stringValue = artists.table[index]["name"] as! String
            artist.selectItem(at: index)
        }
        if let value = composerRow["role"] as? String {
            role.stringValue = value
        }
        else {
            role.stringValue = ""
        }
        if let value = composerRow["notes"] as? String {
            notes.stringValue = value
        }
        else {
            notes.stringValue = ""
        }
        // Since no changes have been made, only allow cancel to terminate
        //processButton.isEnabled = false
        // set the state machine
        inputStatus = [:]
        dialogState = DialogState.ready
    }
    //################################################################################################
    @IBAction func processButtonPressed(_ sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        let artistIndex = artist.indexOfSelectedItem as Int
        if artistIndex > -1 {
            tableRow["artist_id"] = artists.table[artistIndex]["id"]
        }
        tableRow["role"] = role.stringValue
        tableRow["notes"] = notes.stringValue

        if requestType == RequestType.add {
            tableRow["composition_id"] = composerRow["composition_id"]
            //print("processButtonPressed for add - composerRow: ", tableRow)
            composers.addRowAndNotify(rowData: tableRow)
        }
        else {
            //print("processButtonPressed - composerRow: ", composerRow)
            let rowID = String(describing: composerRow["id"]!)
            //print("composer update - rowID: ", rowID, "tableRow: ", tableRow)
            composers.updateRowAndNotify(row: rowID, rowData: tableRow)
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
/*    func composerWasAdded(row: [String: Any]?) {
        if row == nil {
            print("recordWasAdded: I'm broken")
        }
        else {
            delegate.putDataSourceRow(entity: DataEntity.composer, row: row!)
            let application = NSApplication.shared()
            application.stopModal()
        }
    }*/
    //################################################################################################
/*    func composerWasUpdated(row: [String: Any]?, roundTrip: Any? = nil) {
        delegate.putDataSourceRow(entity: DataEntity.composer, row: row!)
        let application = NSApplication.shared()
        application.stopModal()
    }*/
    //################################################################################################
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
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
/*    func artistWasAdded(row: Dictionary<String, Any>?) {
        // todo move this logic to composition table class
        var inserted: Bool = false
        var index = 0
        for (rowIndex, tableRow) in artists.table.enumerated() {
            //print("index: ", index)
            if (tableRow["name"] as! String) >= (row?["name"] as! String) {
                artists.table.insert(row!, at: rowIndex)
                inserted = true
                index = rowIndex
                break
            }
        }
        if inserted == false {
            // The name is greater than any row name
            artists.table.append(row!)
            index = artists.table.count - 1
        }
        postEvent(input: "artist", status: InputStatus.valid)
        artist.reloadData()
        artist.selectItem(at: index)
        //NSLog("Ending artistWasAdded. index: ", index)
    }*/
}
//####################################################################################################
//####################################################################################################
extension ComposerDialogViewController: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //NSLog("number of items. comboBox.tag", comboBox.tag)

        var count: Int = 0
        switch comboBox.tag {
            case artistTableTag:
                count = artists.table.count
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

            case roleFieldTag:
                print("role should end value: ", role.stringValue)
                postEvent(input: "role", status: InputStatus.valid)

            case notesFieldTag:
                print("notes should end value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)

            default:
                print("Tag not found in textShouldEndEditing")
        }
        return result
    }
}
//####################################################################################################
//####################################################################################################

extension ComposerDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //NSLog("Starting comboBoxSelectionDidChange - Tag: ", comboBox.tag)
        switch comboBox.tag {
            case artistTableTag:
                postEvent(input: "artist", status: InputStatus.valid)
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
            case artistTableTag:
                break
            case roleFieldTag:
                //print("role field value: ", role.stringValue)
                postEvent(input: "role", status: InputStatus.valid)
            case notesFieldTag:
                //print("notes field value: ", notes.stringValue)
                postEvent(input: "notes", status: InputStatus.valid)
            default:
                break
        }
    }
}

