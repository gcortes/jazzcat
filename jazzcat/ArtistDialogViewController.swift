//
//  ArtistDialogViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 22/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class ArtistDialogViewController: NSViewController {

    var delegate: tableDataDelegate!
    var artistRow: Dictionary<String, Any> = [:]
    var requestType: RequestType!

    let artists = Artists.shared

    @IBOutlet weak var firstName: NSTextField!
    @IBOutlet weak var lastName: NSTextField!
    @IBOutlet weak var yearBorn: NSTextField!
    @IBOutlet weak var yearDied: NSTextField!
    @IBOutlet weak var primaryRole: NSTextField!
    @IBOutlet weak var otherRoles: NSTextField!
    @IBOutlet weak var notes: NSTextField!

    @IBOutlet weak var processButton: NSButton!

    var dialogState: DialogState = DialogState.ready
    var inputStatus: Dictionary<String, InputStatus> = [:]

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
        artistRow = delegate.getDataSourceRow(entity: DataEntity.artist, request: requestType)
        //print("Starting initializeDialog. artistRow: ", artistRow)

        if requestType == RequestType.update {
            processButton.title = "Update"
        }
        else {
            processButton.title = "Add"
        }

        if let value = artistRow["first_name"] as? String {
            firstName.stringValue = value
        }
        else {
            firstName.stringValue = ""
        }
        if let value = artistRow["last_name"] as? String {
            lastName.stringValue = value
        }
        else {
            lastName.stringValue = ""
        }
        if let value = artistRow["birth_year"] as? String {
            yearBorn.stringValue = value
        }
        else {
            yearBorn.stringValue = ""
        }
        if let value = artistRow["death_year"] as? String {
            yearDied.stringValue = value
        }
        else {
            yearDied.stringValue = ""
        }
        if let value = artistRow["primary_instrument"] as? String {
            primaryRole.stringValue = value
        }
        else {
            primaryRole.stringValue = ""
        }
        if let value = artistRow["other_instruments"] as? String {
            otherRoles.stringValue = value
        }
        else {
            otherRoles.stringValue = ""
        }
        if let value = artistRow["notes"] as? String {
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
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        let application = NSApplication.shared()
        application.stopModal()
    }
    //################################################################################################
    @IBAction func processButtonPressed(_ sender: NSButton) {
        var tableRow: Dictionary<String, Any> = [:]

        tableRow["first_name"] = firstName.stringValue
        tableRow["last_name"] = lastName.stringValue
        tableRow["birth_year"] = yearBorn.stringValue
        tableRow["death_year"] = yearDied.stringValue
        tableRow["primary_instrument"] = primaryRole.stringValue
        tableRow["other_instruments"] = otherRoles.stringValue
        tableRow["notes"] = notes.stringValue

        if requestType == RequestType.add {
            //print("processButtonPressed for add - artistRow: ", tableRow)
            artists.addRowAndNotify(rowData: tableRow)
        }
        else {
            //print("processButtonPressed - artistRow: ", tableRow)
            let rowID = String(describing: artistRow["id"]!)
            //print("artist update - rowID: ", rowID, "tableRow: ", tableRow)
            artists.updateRowAndNotify(row: rowID, rowData: tableRow)
        }
        let application = NSApplication.shared()
        application.stopModal()
    }
}
