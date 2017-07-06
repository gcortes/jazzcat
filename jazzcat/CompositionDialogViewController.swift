//
//  CompositionDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 30/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class CompositionDialogViewController: NSViewController {

    var delegate: tableDataDelegate!
    let nc = NotificationCenter.default

    let compositions = Compositions.shared
    var compositionRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!
    var compositionObserver: NSObjectProtocol!

    let styles = Styles()
    let styleTableTag = -1

    let compositionMetadata = CompositionMetadata.shared

    let metadataTableViewTag = 1
    var selectedMetadata = -1
    var compositionMetadataFilter: [[String:Any]] = []
    @IBOutlet weak var metadataTableView: NSTableView!

    let compositionTags = CompositionTags.shared
    var augmentedCompositionTags: [[String:Any]] = []

    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var yearWritten: NSTextField!
    @IBOutlet weak var yearPublished: NSTextField!
    @IBOutlet weak var style: NSComboBox!
    @IBOutlet weak var notes: NSTextField!

    @IBOutlet weak var processButton: NSButton!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    //################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        styles.loadTable()
        style.tag = styleTableTag
        style.reloadData()

        compositionMetadata.loadTable()
        metadataTableView.tag = metadataTableViewTag

        compositionTags.loadTable()
        augmentedCompositionTags = compositionTags.table
        compositionMetadataFilter = []
        for index in 0..<augmentedCompositionTags.count {
            augmentedCompositionTags[index]["selected"] = false
            augmentedCompositionTags[index]["metadata_id"] = 0
        }
        metadataTableView.reloadData()
        metadataTableView.action = #selector(onItemClicked)

        compositionObserver = nc.addObserver(forName:compositionUpdateNotification,
            object:nil,
            queue:nil,
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
        requestType = delegate.getRequestType()
        initializeDialog()
    }
    //################################################################################################
    override func viewWillDisappear() {
        super.viewWillDisappear()
        nc.removeObserver(compositionObserver)
    }
    //################################################################################################
    // The last step after the add/update button it press is to add/update the record table. In the case
    // of the add, the row id is not available until to Rails API call is complete. With it, any metadata
    // can be added.
    func catchCompositionNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let changeRow = notification.object as? [String: Any]
            else {
            print("No userInfo found in notification")
            let application = NSApplication.shared()
            application.stopModal()
            return
        }
        //print("catchCompositionNotification - changeRow: ", changeRow)
        if changeType == "add" || changeType == "update" {
            for index in 0..<augmentedCompositionTags.count {
                if (augmentedCompositionTags[index]["selected"] as! Bool == true) &&
                       (augmentedCompositionTags[index]["metadata_id"] as! Int == 0) {
                    var newMetadata: [String:Any] = [:]
                    newMetadata["composition_id"] = changeRow["id"] as! Int
                    newMetadata["composition_tag_id"] = augmentedCompositionTags[index]["id"]
                    compositionMetadata.addRowAndNotify(rowData: newMetadata)
                    continue
                }
                if (augmentedCompositionTags[index]["selected"] as! Bool == false) &&
                       (augmentedCompositionTags[index]["metadata_id"] as! Int != 0) {
                    let rowID = String(describing: augmentedCompositionTags[index]["metadata_id"]!)
                    compositionMetadata.deleteRowAndNotify(row: rowID)
                    continue
                }
            }
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    func initializeDialog() {
        compositionRow = delegate.getDataSourceRow(entity: DataEntity.composition, request: requestType)
        //print("Starting initializeDialog. compositionRow: ", compositionRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
        }
        else {
            processButton.title = "Add"
        }

        if let value = compositionRow["name"] as? String {
            name.stringValue = value
        }
        if let value = compositionRow["year_written"] as? Int {
            if value > 0 {
                yearWritten.integerValue = value
            }
            else {
                yearWritten.stringValue = ""
            }
        }
        if let value = compositionRow["year_published"] as? Int {
            if value > 0 {
                yearPublished.integerValue = value
            }
            else {
                yearPublished.stringValue = ""
            }
        }
        if let foreignKey = compositionRow["style_id"] as? Int {
            let index = styles.getIndex(foreignKey: foreignKey)
            style.stringValue = styles.table[index]["name"] as! String
            style.selectItem(at: index)
        }
        if let value = compositionRow["notes"] as? String {
            notes.stringValue = value
        }

        if requestType == RequestType.update {
            compositionMetadataFilter = compositionMetadata.filterByComposition(id: compositionRow["id"] as! Int)
            //print("compositionMetadataFilter count: ", compositionMetadataFilter.count)
            for metadatum in compositionMetadataFilter {
                //print("metadatum: ", metadatum)
                for index in 0..<augmentedCompositionTags.count {
                    if metadatum["composition_tag_id"] as! Int == augmentedCompositionTags[index]["id"] as! Int {
                        augmentedCompositionTags[index]["selected"] = true
                        augmentedCompositionTags[index]["metadata_id"] = metadatum["id"] as! Int
                    }
                }
            }
            metadataTableView.reloadData()
        }
        // Since no changes have been made, only allow cancel to terminate
        //processButton.isEnabled = false
        // set the state machine
        inputStatus = [:]
        dialogState = DialogState.ready
    }
    //################################################################################
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################
    @IBAction func processButtonPressed(_ sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        tableRow["name"] = name.stringValue

        let written = yearWritten.integerValue
        if written > 0 {
            tableRow["year_written"] = written
        }
        else {
            tableRow["year_written"] = ""
        }

        let published = yearPublished.integerValue
        if published > 0 {
            tableRow["year_published"] = published
        }
        else {
            tableRow["year_published"] = ""
        }

        let styleIndex = style.indexOfSelectedItem as Int
        if styleIndex > -1 {
            tableRow["style_id"] = styles.table[styleIndex]["id"]
        }
        tableRow["notes"] = notes.stringValue

        if requestType == RequestType.add {
            compositions.addRowAndNotify(rowData: tableRow)
        }
        else {
            let rowID = String(describing: compositionRow["id"]!)
            //print("composition update - rowID: ", rowID, "tableRow: ", tableRow)
            compositions.updateRowAndNotify(row: rowID, rowData: tableRow)
        }
        //let application = NSApplication.shared()
        //application.stopModal()
    }
    //################################################################################################
    @objc private func onItemClicked() {
        //print("row \(metadata.clickedRow), col \(metadata.clickedColumn) clicked")
        let clickedRow = metadataTableView.clickedRow
        let clickedColumn = metadataTableView.clickedColumn
        if clickedRow == -1 || clickedColumn == -1 {
            return
        }
        if clickedColumn == 0 {
            if augmentedCompositionTags[clickedRow]["selected"] as! Bool == true {
                augmentedCompositionTags[clickedRow]["selected"] = false
            }
            else {
                augmentedCompositionTags[clickedRow]["selected"] = true
            }
            //postEvent(input: "metadata", status: InputStatus.valid)
            metadataTableView.reloadData()
        }
    }
}
//####################################################################################################
//####################################################################################################
extension CompositionDialogViewController: NSComboBoxDataSource {

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        //print("number of items. comboBox.tag", comboBox.tag)
        //print("returning count: ", artistTable.count)

        return styles.table.count
    }
    //################################################################################################
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        //print("value from index: ", index)
        var entry: String = "object not found"
        //print("label tag")
        let style: Dictionary<String, Any> = styles.table[index]
        entry = (style["name"] as? String)!
        return entry
    }
    //################################################################################################
    func comboBox(aComboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        print("index of item with string value")
        return 0
        //return self.filteredDataArray.indexOfObject(string)
    }
}
//####################################################################################################
//####################################################################################################
extension CompositionDialogViewController: NSComboBoxDelegate {

    //################################################################################################
    func comboBoxSelectionDidChange(_ notification: Notification) {
//        print("comboBoxSelectionDidChange: starting")
    }
}
//####################################################################################################
//####################################################################################################
extension CompositionDialogViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case metadataTableViewTag:
                count = augmentedCompositionTags.count
            default:
                count = 0
        }
        return count
    }
}
//####################################################################################################
//####################################################################################################

extension CompositionDialogViewController: NSTableViewDelegate {

    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        // which row was selected?
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        switch tag {
            case metadataTableViewTag:
                // selectedRow is -1 if you click in the table, but not on a row
                selectedMetadata = selectedRow
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
            case metadataTableViewTag:
                // get the "Item" for the row
                let item = augmentedCompositionTags[row]

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
