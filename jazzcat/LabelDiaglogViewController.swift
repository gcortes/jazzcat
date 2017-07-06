//
//  LabelDiaglogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 27/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class LabelDialogViewController: NSViewController {

    var delegate: tableDataDelegate!
    var labelRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!

    let labels = Labels.shared

    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var city: NSTextField!
    @IBOutlet weak var country: NSTextField!
    @IBOutlet weak var notes: NSTextField!

    @IBOutlet weak var processButton: NSButton!
    var returnCode = "Cancel"

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()
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
    func initializeDialog() {
        labelRow = delegate.getDataSourceRow(entity: DataEntity.label, request: requestType)
        //print("Starting initializeDialog. artistRow: ", artistRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
        }
        else {
            processButton.title = "Add"
        }

        if let value = labelRow["name"] as? String {
            name.stringValue = value
        }
        else {
            name.stringValue = ""
        }
        if let value = labelRow["city"] as? String {
            city.stringValue = value
        }
        else {
            city.stringValue = ""
        }
        if let value = labelRow["country"] as? String {
            country.stringValue = value
        }
        else {
            country.stringValue = ""
        }
        if let value = labelRow["notes"] as? String {
            notes.stringValue = value
        }
        else {
            notes.stringValue = ""
        }
        // Since no changes have been made, only allow cancel to terminate
        //processButton.isEnabled = false
        // set the state machine
        //inputStatus = [:]
        //dialogState = DialogState.ready
    }
    //################################################################################################
    @IBAction func dismissLabelDialogController(sender: NSButton) {
        //returnCode = "Cancel"
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func dismissLabelDialogControllerAccept(sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        tableRow["name"] = name.stringValue
        tableRow["city"] = city.stringValue
        tableRow["country"] = country.stringValue
        tableRow["notes"] = notes.stringValue

        if requestType == RequestType.add {
            //print("processButtonPressed for add - artistRow: ", tableRow)
            labels.addRowAndNotify(rowData: tableRow)
        }
        else {
            //print("processButtonPressed - artistRow: ", tableRow)
            let rowID = String(describing: labelRow["id"]!)
            //print("artist update - rowID: ", rowID, "tableRow: ", tableRow)
            labels.updateRowAndNotify(row: rowID, rowData: tableRow)
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
}
