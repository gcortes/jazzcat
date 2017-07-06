 //
//  CreditDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 1/2/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa

class CreditDialogViewController: NSViewController {

    var delegate: tableDataDelegate!

    let credits = Credits.shared
    var creditRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!

    let artists = Artists.shared
    let artistTableTag = 1
    @IBOutlet weak var artist: NSComboBox!

    @IBOutlet weak var role: NSTextField!
    let roleFieldTag = 10
    @IBOutlet weak var notes: NSTextField!
    let notesFieldTag = 11

    @IBOutlet weak var processButton: NSButton!
    @IBOutlet weak var processAndReturnButton: NSButton!

    var state = ""
    var inputStatus: Dictionary<String, String> = [:]
    let VALID = "valid"
    let INVALID = "invalid"
    let READY = "ready"

    var repeatAdd: Bool = false

    //################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        artists.loadTable()
        artist.tag = artistTableTag
        artist.reloadData()

        role.tag = roleFieldTag
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
                // todo: change status to enum
                postEvent(input: "artist", status: VALID)
            }
        }
    }
    //################################################################################################
    func initializeDialog() {
        creditRow = delegate.getDataSourceRow(entity: DataEntity.credit, request: requestType)
        //print("initializeDialog creditRow: ", creditRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
            processAndReturnButton.isEnabled = false
        }
        else {
            processButton.title = "Add"
        }

        if let value = creditRow["artist_name"] as? String {
            artist.stringValue = value
            let foreignKey = creditRow["artist_id"] as! Int
            let index = artists.getIndex(foreignKey: foreignKey)
            artist.selectItem(at: index)
        }
        else {
            artist.stringValue = ""
            let index = artist.indexOfSelectedItem
            if index > -1 {
                artist.deselectItem(at: index)
            }
        }
        if let value = creditRow["instrument"] as? String {
            role.stringValue = value
        }
        else {
            role.stringValue = ""
        }
        if let value = creditRow["notes"] as? String {
            notes.stringValue = value
        }
        else {
            notes.stringValue = ""
        }
        artist.becomeFirstResponder()
        // Since no changes have been made, only allow cancel to terminate
        processButton.isEnabled = false
        processAndReturnButton.isEnabled = false
        // set the state machine
        inputStatus = [:]
        state = READY
    }
    //################################################################################
    @IBAction func cancel(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################
    @IBAction func accept(_ sender: NSButton) {
        repeatAdd = false
        processRow()
    }
    //################################################################################
    @IBAction func acceptAndReturn(_ sender: NSButton) {
        repeatAdd = true
        processRow()
    }
    //################################################################################################
    func processRow() {
        var tableRow: [String:Any] = [:]

        let index = artist.indexOfSelectedItem
        tableRow["artist_id"] = artists.table[index]["id"]
        tableRow["instrument"] = role.stringValue
        tableRow["notes"] = notes.stringValue

        if requestType == RequestType.add {
            tableRow["record_id"] = creditRow["record_id"]
            credits.addRowAndNotify(rowData: tableRow)
            if repeatAdd == true {
                initializeDialog()
            }
            else {
                let application = NSApplication.shared()
                application.stopModal()
            }
        }
        else {
            let rowID = String(describing: creditRow["id"]!)
            //print("rowID: ", rowID)
            credits.updateRowAndNotify(row: rowID, rowData: tableRow)
            let application = NSApplication.shared()
            application.stopModal()
        }
    }
    //################################################################################################
    func postEvent(input: String, status: String) {
        //print("in postEvent - input: ", input, " status: ", status)
        inputStatus[input] = status
        switch state {
            case READY:
                if status == INVALID {
                    state = INVALID
                    processButton.isEnabled = false
                    processAndReturnButton.isEnabled = false
                }
                else {
                    state = VALID
                    processButton.isEnabled = true
                    if requestType == RequestType.add {
                        processAndReturnButton.isEnabled = true
                    }
                }

            case VALID:
                if status == INVALID {
                    state = INVALID
                    processButton.isEnabled = false
                    processAndReturnButton.isEnabled = false
                }

            case INVALID:
                if status == VALID {
                    var result = VALID
                    for row in inputStatus {
                        if row.value == INVALID {
                            result = INVALID
                            break
                        }
                    }
                    if result == VALID {
                        state = VALID
                        processButton.isEnabled = true
                        if requestType == RequestType.add {
                            processAndReturnButton.isEnabled = true
                        }
                    }
                }
            default:
                break
        }
    }
    //################################################################################################
    func addArtist(name: Dictionary<String, String>) {
        artists.addRowAndNotify(rowData: name)
    }
    //################################################################################################
    func dialogErrorReason(text: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = "Error"
        dialog.informativeText = text
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //let res = dialog.runModal()
    }
}
//####################################################################################################
//####################################################################################################
extension CreditDialogViewController: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //print("Starting numberOfItems. comboBox.tag", comboBox.tag)

        var count: Int = 0
        count = artists.table.count
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
        let artistRow: Dictionary<String, Any> = artists.table[index]
        if let val = artistRow["name"] as? String {
            entry = val
            //print("entry: ", entry)
        }
        return entry
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        //print("Starting indexOfItemWithStringValue: ", string)
        var index = NSNotFound
        index = findMatch(table: artists.table, string: string)
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
/*    override func controlTextDidBeginEditing(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        print("Starting controlTextDidBeginEditing: ", control.tag)
        switch control.tag {
//            case roleFieldTag:
            default:
                break
        }
    }*/
    //################################################################################################
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        //print("Starting textShouldEndEditing - tag: ", control.tag, "selectedRow: ", artist.indexOfSelectedItem)
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
                        postEvent(input: "artist", status: INVALID)
                    }
                }
                else {
                    postEvent(input: "artist", status: VALID)
                    if role.stringValue == "" {
                        let index = artist.indexOfSelectedItem
                        if index > -1 {
                            if let value = artists.table[index]["primary_instrument"] as? String {
                                role.stringValue = value
                            }
                        }
                    }
                }
            case roleFieldTag:
                //print("role should value: ", time.stringValue)
                postEvent(input: "role", status: VALID)
            case notesFieldTag:
                //print("notes should end value: ", notes.stringValue)
                postEvent(input: "notes", status: VALID)
            default:
                print("Tag not found in textShouldEndEditing")
                break
        }
        return result
    }
}
//####################################################################################################
//####################################################################################################
extension CreditDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    // The only purpose for handling this notification is to record a change in 'select only' comboboxes
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //print("Starting comboBoxSelectionDidChange - Tag: ", comboBox.tag)
        switch comboBox.tag {
            case artistTableTag:
                postEvent(input: "artist", status: VALID)
            default:
                break
        }
    }
    //################################################################################################
    func comboBox(_ aComboBox: NSComboBox, completedString string: String) -> String? {
        //print("completed string starting. Tag: ", aComboBox.tag)
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
        //print("Ending findFirstOccurrence returning: ", returnString)
        return returnString
    }
    //################################################################################################
    override func controlTextDidChange(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        //print("Starting controlTextDidChange: ", control.tag)
        switch control.tag {
            case artistTableTag:
                break
            case roleFieldTag:
                //print("take field value: ", take.stringValue)
                postEvent(input: "role", status: VALID)
            case notesFieldTag:
                //print("notes field value: ", notes.stringValue)
                postEvent(input: "notes", status: VALID)
            default:
                break
        }
    }
}
