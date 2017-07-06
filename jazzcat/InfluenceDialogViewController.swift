//
//  InfluenceDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 9/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa

class InfluenceDialogViewController: NSViewController {

    var delegate: tableDataDelegate!
    var requestType: RequestType!
    var direction: String!

    let artists = Artists.shared
    let influences = Influences.shared

    var artistRow: [String:Any] = [:]
    let artistTableTag = 1
    @IBOutlet weak var artist: NSComboBox!

    @IBOutlet weak var processButton: NSButton!
    @IBOutlet weak var fromLabel: NSTextField!
    @IBOutlet weak var toLabel: NSTextField!
    @IBOutlet weak var notes: NSTextField!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        artists.loadTable()
        artist.tag = artistTableTag
        artist.reloadData()
        let nc = NotificationCenter.default
        nc.addObserver(forName:artistUpdateNotification, object:nil, queue:nil, using:catchArtistNotification)
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
        if delegate.verifyInput(field: "direction", input: "to") == true {
            direction = "to"
        }
        else {
            direction = "from"
        }
        initializeDialog()
    }
    //################################################################################################
    func catchArtistNotification(notification:Notification) -> Void {
        //var selectedArtist = -1

        /*guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let changeRow = notification.object as? [String: Any]
        else {
            print("No userInfo found in notification")
            return
        }*/
        //print("track: ", artist)
        artist.reloadData()
/*        if changeType == "add" {
            if let key = changeRow["id"] as? Int {
                selectedArtist = artists.getIndex(foreignKey: key)
            }
        }*/
/*        if changeType == "delete" {
            if selectedArtist >= artist.count {
                selectedArtist -= 1
            }
        }*/
        //artist.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func initializeDialog() {
        artistRow = delegate.getDataSourceRow(entity: DataEntity.artist, request: RequestType.read)
        //print("Starting initializeDialog. artistRow: ", artistRow)

        if direction == "from" {
            fromLabel.stringValue = ""
            toLabel.stringValue = "influenced " + (artistRow["name"] as! String)
        }
        else {
            fromLabel.stringValue = artistRow["name"] as! String + " was an influence on"
            toLabel.stringValue = ""
        }
        // Only adds now
        processButton.title = "Add"
        inputStatus = [:]
        dialogState = DialogState.ready
    }
    //################################################################################################
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func processButtonClicked(_ sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        let index = artist.indexOfSelectedItem
        let selectedArtistID = artists.table[index]["id"]

        if direction == "from" {
            tableRow["influence_id"] = selectedArtistID
            tableRow["influencee_id"] = artistRow["id"]
        }
        else {
            tableRow["influence_id"] = artistRow["id"]
            tableRow["influencee_id"] = selectedArtistID
        }
        tableRow["notes"] = notes.stringValue

        //print("processButtonPressed for add - artistRow: ", tableRow)
        influences.addRowAndNotify(rowData: tableRow)

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
                    //addAndRepeatButton.isEnabled = false
                }
                else {
                    dialogState = DialogState.valid
                    processButton.isEnabled = true
                    //addAndRepeatButton.isEnabled = true
                }

            case DialogState.valid:
                if status == InputStatus.invalid {
                    dialogState = DialogState.invalid
                    processButton.isEnabled = false
                    //addAndRepeatButton.isEnabled = false
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
                        //addAndRepeatButton.isEnabled = true
                    }
                }
        }
    }
    //################################################################################################
    func addArtist(name: Dictionary<String, String>) {
        artists.addRowAndNotify(rowData: name)
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
        //let res = dialog.runModal()
    }
}
//####################################################################################################
//####################################################################################################
extension InfluenceDialogViewController: NSComboBoxDataSource {

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
                        postEvent(input: "artist", status: InputStatus.invalid)
                    }
                }
                else {
                    postEvent(input: "artist", status: InputStatus.valid)
                    /*if role.stringValue == "" {
                        let index = artist.indexOfSelectedItem
                        if index > -1 {
                            if let value = artists.table[index]["primary_instrument"] as? String {
                                role.stringValue = value
                            }
                        }
                    }*/
                }
            //case notesFieldTag:
                //print("notes should end value: ", notes.stringValue)
              //  postEvent(input: "notes", status: InputStatus.valid)
            default:
                print("Tag not found in textShouldEndEditing")
                break
        }
        return result
    }
}
//####################################################################################################
//####################################################################################################
extension InfluenceDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    // The only purpose for handling this notification is to record a change in 'select only' comboboxes
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let comboBox = (notification.object as AnyObject)
        //print("Starting comboBoxSelectionDidChange - Tag: ", comboBox.tag)
        switch comboBox.tag {
            case artistTableTag:
                postEvent(input: "artist", status: InputStatus.valid)
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
            default:
                break
        }
    }
}
