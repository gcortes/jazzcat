//
//  RecordViewControllerCredits.swift
//  jazzcat
//
//  Created by Curt Rowe on 1/5/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

extension RecordViewController {
    //################################################################################################
    func catchCreditNotification(notification:Notification) -> Void {

        var matchIndex = -1
        guard let userInfo = notification.userInfo,
            let changeType = userInfo["type"] as? String,
            let creditRow = notification.object as? [String: Any]
            else {
                print("No userInfo found in notification")
                return
        }
        //print("record: ", creditRow)
        let changeKey = creditRow["id"] as! Int

        if changeType == "add" || changeType == "update" {
            if records.table[selectedRecord]["id"] as! Int != creditRow["record_id"] as! Int {
                // not on this record, ignore
                return
            }
        }
        if changeType == "delete" {
            // Check to see if it is in the filter table
            for (index, credit) in creditsFilter.enumerated() {
                if credit["id"] as! Int == changeKey {
                    matchIndex = index
                    break
                }
            }
            // Not found, ignore
            if matchIndex == -1 { return }
        }
        filterCredits(foreignKey: records.table[selectedRecord]["id"] as! Int)
        // Set to the first credit in case it isn't found
        selectedCredit = 0
        for (index, credit) in creditsFilter.enumerated() {
            if credit["id"] as! Int == changeKey {
                selectedCredit = index
                break
            }
        }
        creditTable.selectRowIndexes(NSIndexSet(index: selectedCredit) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func filterCredits(foreignKey: Int) {
        creditsFilter = credits.filterCreditsByRecord(id: foreignKey)
        creditTable.reloadData()
    }
    //################################################################################################
    @IBAction func addCredit(_ sender: NSButton) {
        callCreditDialog(type: RequestType.add)
    }
    //################################################################################################
    func creditTableDoubleClick(_ sender: AnyObject) {
        callCreditDialog(type: RequestType.update)
    }
    //################################################################################################
    @IBAction func getCreditInfoClicked(_ sender: NSMenuItem) {
        //print("getCreditInfoClicked - selectedCredit: ", selectedCredit)
        if selectedCredit == -1 {
            return
        }
        callCreditDialog(type: RequestType.update)
    }
    //################################################################################################
    func callCreditDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let creditDialogWindowController = storyboard.instantiateController(withIdentifier: "creditWindowControllerScene")
        as! NSWindowController

        if let creditDialogWindow = creditDialogWindowController.window {
            let creditDialogViewController = creditDialogWindow.contentViewController as! CreditDialogViewController
            requestType = type
            creditDialogViewController.delegate = self
            let application = NSApplication.shared()
            application.runModal(for: creditDialogWindow)

            // And, we're back
            self.view.window!.makeKey()
            creditTable.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func deleteCredit(_ sender: NSButton) {
        if selectedCredit > -1 {
            let deleteID = String(describing: creditsFilter[selectedCredit]["id"]!)
            credits.deleteRowAndNotify(row: deleteID)
        }
        else {
            // todo: handle error
        }
    }
    //################################################################################################
    @IBAction func getArtistInfoClicked(_ sender: NSMenuItem) {
        //print("getArtistInfoClicked - selectedCredit: ", selectedCredit)
        if selectedCredit > -1 {
            let artistKey = creditsFilter[selectedCredit]["artist_id"] as! Int
            selectedArtist = artists.getIndex(foreignKey: artistKey)
            callArtistDialog(type: RequestType.update)
        }
    }
}
