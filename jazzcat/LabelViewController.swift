//
//  LabelViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 27/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class LabelViewController: JazzCatViewController {

    var requestType: RequestType!

    let labels = Labels.shared

    let labelTableTag = 1
    var selectedLabel: Int = -1
    @IBOutlet weak var labelTable: NSTableView!
    @IBOutlet var labelTableViewMenu: NSMenu!
    @IBOutlet weak var editLabelMenuItem: NSMenuItem!

    let records = Records.shared

    let recordTableTag = 2
    var selectedRecord: Int = -1    // -1 means no selection
    var recordsFilter: [[String: Any]] = []
    @IBOutlet weak var recordTable: NSTableView!
    @IBOutlet var recordTableMenu: NSMenu!

    @IBOutlet weak var titleOutput: NSTextField!
    @IBOutlet weak var cityOutput: NSTextField!
    @IBOutlet weak var countryOutput: NSTextField!
    @IBOutlet weak var notesOutput: NSTextField!

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        labelTable.tag = labelTableTag
        recordTable.tag = recordTableTag

        // refresh the table with the data
        labels.loadTable()
        labelTable.reloadData()
        labelTable.doubleAction = #selector(labelTableDoubleClick(_:))

        let nc = NotificationCenter.default
        nc.addObserver(forName:labelUpdateNotification, object:nil, queue:nil, using:catchLabelNotification)
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()

        // If no row selected, select the first one if there is one
        if selectedLabel == -1 {
            if labels.table.count > 0 {
                selectedLabel = 0
            }
        }
        labelTable.selectRowIndexes(NSIndexSet(index: selectedLabel) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    override func selectRow(selectionData: [String:Any]) {
        //print("In Label selectRow")
        if let labelID = selectionData["id"] as? Int {
            let index = labels.getIndex(foreignKey: labelID)
            if index > -1 {
                selectedLabel = index
            }
            labelTable.selectRowIndexes(NSIndexSet(index: selectedLabel) as IndexSet, byExtendingSelection: false)
            labelTable.scrollRowToVisible(selectedLabel)
            // todo: finish track selection
            //if let trackID = selectionData["item"] as? Int {}
        }
        else {
            print("LabelViewController:selectRow - Incorrect selection data received.")
            return
        }
    }
    //################################################################################################
    func catchLabelNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let label = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", label)
        labelTable.reloadData()
        if changeType == "add" {
            if let key = label?["id"] as? Int {
                selectedLabel = labels.getIndex(foreignKey: key)
            }
        }
        if changeType == "delete" {
            if selectedLabel >= labels.table.count {
                selectedLabel -= 1
            }
        }
        labelTable.selectRowIndexes(NSIndexSet(index: selectedLabel) as IndexSet, byExtendingSelection: false)
        self.view.window!.makeKey()
        labelTable.becomeFirstResponder()
    }
    //################################################################################################
    @IBAction func goToRecordMenuItemClicked(_ sender: Any) {
        if selectedRecord > -1 {
            //let recordID = recordsFilter[selectedCredit]["record_id"] as! Int
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
    @IBAction func editLabelMenuItemClicked(_ sender: NSMenuItem) {
        callLabelDialog(type: RequestType.update)
    }
    //################################################################################################
    func labelTableDoubleClick(_ sender: AnyObject) {
        callLabelDialog(type: RequestType.update)
    }
    //################################################################################################
    @IBAction func addLabel(_ sender: NSButton) {
        callLabelDialog(type: RequestType.add)
    }
    //################################################################################################
    //@IBAction func update(_ sender: NSButton) {
    //    callLabelDialog(type: RequestType.update)
    //}
    //################################################################################################
    func callLabelDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let labelDialogWindowController = storyboard.instantiateController(withIdentifier: "labelWindowControllerScene")
        as! NSWindowController

        if let labelDialogWindow = labelDialogWindowController.window {
            let labelDialogViewController = labelDialogWindow.contentViewController as! LabelDialogViewController
            labelDialogViewController.processButton.title = "Update"

            let application = NSApplication.shared()
            requestType = type
            labelDialogViewController.delegate = self
            application.runModal(for: labelDialogWindow)

            // And we're back
            self.view.window!.makeKey()
            labelTable.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func removeLabel(_ sender: NSButton) {
        if recordsFilter.count != 0 {
            dialogErrorReason(text: "You can not delete a label with associated records.")
            return
        }
        let deleteID = String(describing: labels.table[selectedLabel] ["id"]!)
        labels.deleteRowAndNotify(row: deleteID)
    }
    //################################################################################################
    func filterRecords(labelID: Int) {
        recordsFilter = records.filterRecordsByLabel(id: labelID)
        recordTable.reloadData()
    }
}
//####################################################################################################
//####################################################################################################
extension LabelViewController: tableDataDelegate {

    //################################################################################################
/*    func putDataSourceRow(entity: DataEntity, row: Dictionary<String, Any>) {
        switch entity {
            default:
                break
        }
    }*/
    //################################################################################################
    func getRequestType() -> RequestType {
        return requestType
    }
    //################################################################################################
    func verifyInput(field: String, input: Any) -> Bool {
        let result: Bool = true
        // no verifications needed
        return result
    }
    //################################################################################################
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any> {
        //print("selected track: ", selectedTrack)
        var returnData: Dictionary<String, Any> = [:]
        switch entity {
            case DataEntity.label:
                if requestType == RequestType.update {
                    returnData = labels.table[selectedLabel]
                }
            default:
                break
        }
        return returnData
    }
}
//################################################################################################
//################################################################################################
extension LabelViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        if tableView.tag == labelTableTag {
            count = labels.table.count
        }
        else if tableView.tag == recordTableTag {
            count = recordsFilter.count
        }
        return count
    }
}

//################################################################################################
//################################################################################################
extension LabelViewController: NSTableViewDelegate {

    func blankOutField(field: NSTextField) {
        field.stringValue = ""
    }

    func blankOutFields() {
        blankOutField(field: titleOutput)
        blankOutField(field: cityOutput)
        blankOutField(field: countryOutput)
        blankOutField(field: notesOutput)
    }
    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        // which row was selected?
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        if tag == labelTableTag {
            // selectedRow is -1 if you click in the table, but not on a row
            selectedLabel = selectedRow
            if (selectedRow >= 0) {
                // get the "Label" for the row
                blankOutFields()

                if let value = labels.table[selectedRow]["name"] as? String {
                    titleOutput.stringValue = value
                }
                if let value = labels.table[selectedRow]["city"] as? String {
                    cityOutput.stringValue = value
                }
                if let value = labels.table[selectedRow]["country"] as? String {
                    countryOutput.stringValue = value
                }
                if let value = labels.table[selectedRow]["notes"] as? String {
                    notesOutput.stringValue = value
                }
                filterRecords(labelID: labels.table[selectedRow]["id"] as! Int)
                selectedRecord = -1
            }
        }
        else if tag == recordTableTag {
            selectedRecord = selectedRow
        }
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView

        if tableView.tag == labelTableTag {
            // get the "Item" for the row
            let item = labels.table[row]

            // get the value for this column
            if let val = item[tableColumn!.identifier] as? String {
                result.textField?.stringValue = val
            }
            else {
                result.textField?.stringValue = ""
            }
            //print(result.textField?.stringValue)
        }
        else if tableView.tag == recordTableTag {
            let item = recordsFilter[row]
            if let value = item[tableColumn!.identifier] as? String {
                result.textField?.stringValue = value
            }
            else {
                result.textField?.stringValue = ""
            }
        }
        return result
    }

}
