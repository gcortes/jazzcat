//
//  ViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 30/11/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

class ArtistViewController: JazzCatViewController {

    var requestType: RequestType!
    var dialogDirection: String!
    var clearFilterRequested: Bool = false

    let records = Records.shared
    let composers = Composers.shared

    let artists = Artists.shared
    var filteredArtists: [[String:Any]] = []
    var artistFilterActive: Bool = false

    let artistTableTag = 1
    var selectedArtist: Int = -1    // -1 means no selection
    var lastChangedArtist: Int!
    @IBOutlet weak var artistTable: NSTableView!

    let credits = Credits.shared

    let creditTableTag = 2
    var selectedCredit: Int = -1    // -1 means no selection
    var creditsFilter: [[String: Any]] = []
    @IBOutlet weak var creditTable: NSTableView!
    @IBOutlet var creditsMenu: NSMenu!

    let compositions = Compositions.shared

    let compositionTableTag = 3
    var selectedComposition: Int = -1   // -1 means no selection
    var compositionsFilter: [[String: Any]] = []
    @IBOutlet weak var compositionTable: NSTableView!

    let influences = Influences.shared

    let influencesTableTag = 4
    var selectedInfluence: Int = -1
    var influencesFilter: [[String: Any]] = []
    @IBOutlet weak var influencesTable: NSTableView!
    @IBOutlet var influencesMenu: NSMenu!

    let influencedTableTag = 5
    var selectedInfluencee: Int = -1
    var influencedFilter: [[String: Any]] = []
    @IBOutlet weak var influencedTable: NSTableView!
    @IBOutlet var influencedMenu: NSMenu!

    @IBOutlet weak var birth_year: NSTextField!
    @IBOutlet weak var death_year: NSTextField!
    @IBOutlet weak var primary_instrument: NSTextField!
    @IBOutlet weak var other_instruments: NSTextField!
    @IBOutlet weak var notes: NSTextField!
    @IBOutlet weak var name: NSTextField!

    @IBOutlet weak var allRadioButton: NSButton!
    @IBOutlet weak var organRadioButton: NSButton!
    @IBOutlet weak var pianoRadioButton: NSButton!
    @IBOutlet weak var saxophoneRadioButton: NSButton!
    @IBOutlet weak var trumpetRadioButton: NSButton!
    @IBOutlet weak var tromboneRadioButton: NSButton!

    @IBOutlet weak var allRoleRadioButton: NSButton!
    @IBOutlet weak var leaderRoleRadioButton: NSButton!
    @IBOutlet weak var composerRoleRadioButton: NSButton!

    @IBOutlet weak var filterButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("ArtistViewController viewDidLoad")
        allRadioButton.state = NSOnState
        allRoleRadioButton.state = NSOnState
        clearButton.isEnabled = false

        artistTable.tag = artistTableTag
        creditTable.tag = creditTableTag
        compositionTable.tag = compositionTableTag
        influencesTable.tag = influencesTableTag
        influencedTable.tag = influencedTableTag

        artists.loadTable()
        artistTable.reloadData()

        influences.loadTable()

        let nc = NotificationCenter.default
        nc.addObserver(forName:artistUpdateNotification, object:nil, queue:nil, using:catchArtistNotification)
        nc.addObserver(forName:influenceUpdateNotification, object:nil, queue:nil, using:catchInfluenceNotification)
        // todo: catch credit changes, compositions too
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
            if selectedArtist == -1 {
                if artists.table.count > 0 {
                    selectedArtist = 0
                }
            }
        }
        artistTable.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
        artistTable.scrollRowToVisible(selectedArtist)
    }
    //################################################################################################
    override func selectRow(selectionData: [String:Any]) {
        //print("In Record selectRow")
        guard let artistID = selectionData["id"] as? Int
            else {
            print("ArtistViewController:selectRow - Incorrect selection data received.")
            return
        }
        var index = -1
        if artistFilterActive == true {
            if let index = filteredArtists.index(where: { (artist) -> Bool in
                artist["id"] as! Int == artistID }) {
                selectedArtist = index
            }
            else {
                let message = "Remove the filter?"
                if (dialogOKCancel(question: "Selected entry filtered out.", text: message)) {
                    clearFilterRequested = true
                    index = artists.getIndex(foreignKey: artistID)
                }
                else {
                    index = -1
                }
            }
        }
        else {
            index = artists.getIndex(foreignKey: artistID)
        }
        if index > -1 {
            selectedArtist = index
        }
        artistTable.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
        artistTable.scrollRowToVisible(selectedArtist)
    }
    //################################################################################################
    func catchArtistNotification(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let artist = notification.object as? [String: Any]? else {
            print("No userInfo found in notification")
            return
        }
        //print("track: ", artist)
        artistTable.reloadData()
        if changeType == "add" {
            if let key = artist?["id"] as? Int {
                selectedArtist = artists.getIndex(foreignKey: key)
            }
        }
        if changeType == "delete" {
            if selectedArtist >= artists.table.count {
                selectedArtist -= 1
            }
        }
        if changeType == "update" {
            selectedArtist = artists.getIndex(foreignKey: artist?["id"] as! Int)
        }
        artistTable.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
    }
    //################################################################################################
    func catchInfluenceNotification(notification:Notification) -> Void {
        var id: Int = 0

        guard let userInfo = notification.userInfo,
              let changeType = userInfo["type"] as? String,
              let changeRow = notification.object as? [String: Any]
        else {
            print("Notification data missing or invalid")
            return
        }
        //print("Notification changeRow: ", changeRow)
        id = changeRow["id"] as! Int

        if changeType == "add" {
            let artistID = artists.table[selectedArtist]["id"] as! Int
            print("artist id: ", artistID, " selectedArtist: ", selectedArtist)
            if artistID == changeRow["influence_id"] as! Int {
                influencedFilter.append(changeRow)
                influencedTable.reloadData()
            }
            else {
                influencesFilter.append(changeRow)
                influencesTable.reloadData()
            }
        }
        if changeType == "delete" {
            var key = -1
            for (index,row) in influencedFilter.enumerated() {
                if row["id"] as! Int == id {
                    key = index
                    break
                }
            }
            if key >= 0 {
                influencedFilter.remove(at: key)
                influencedTable.reloadData()
                if influencedFilter.count == 0 {
                    selectedInfluence = -1
                }
            }
            else {
                for (index, row) in influencesFilter.enumerated() {
                    if row["id"] as! Int == id {
                        key = index
                        break
                    }
                }
                if key >= 0 {
                    influencesFilter.remove(at: key)
                    influencesTable.reloadData()
                    if influencesFilter.count == 0 {
                        selectedInfluencee = -1
                    }
                }
            }
        }
    }
    //################################################################################################
    @IBAction func filterButtonClicked(_ sender: NSButton) {
        filteredArtists = []
        for artist in artists.table {
            var match = false
            if leaderRoleRadioButton.state == NSOnState {
                for record in records.table {
                    if artist["id"] as! Int == record["artist_id"] as! Int {
                        match = true
                        break
                    }
                }
            }
            if composerRoleRadioButton.state == NSOnState {
                for composer in composers.table {
                    if artist["id"] as! Int == composer["artist_id"] as! Int {
                        match = true
                        break
                    }
                }
            }
            if allRoleRadioButton.state == NSOnState {
                match = true
            }
            // And with the following or conditions
            if match == true {
                var selectedInstrument: String = ""
                if pianoRadioButton.state == NSOnState {
                    selectedInstrument = "piano"
/*                    if let instrument = artist["primary_instrument"] as? String {
                        if instrument.range(of: "piano") == nil {
                            match = false
                        }
                    }
                    else {
                        match = false
                    }*/
                }
                if organRadioButton.state == NSOnState {
                    selectedInstrument = "organ"
/*                    if let instrument = artist["primary_instrument"] as? String {
                        if instrument.range(of: "organ") == nil {
                            match = false
                        }
                    }
                    else {
                        match = false
                    }*/
                }
                if saxophoneRadioButton.state == NSOnState {
                    selectedInstrument = "sax"
                }
                if tromboneRadioButton.state == NSOnState {
                    selectedInstrument = "trombone"
                }
                if trumpetRadioButton.state == NSOnState {
                    selectedInstrument = "trumpet"
                }
                if selectedInstrument != "" {
                    if let instrument = artist["primary_instrument"] as? String {
                        if instrument.range(of: selectedInstrument) == nil {
                            match = false
                        }
                    }
                    else {
                        match = false
                    }
                }
            }
            if match == true {
                filteredArtists.append(artist)
            }
        }
        clearButton.isEnabled = true
        artistFilterActive = true
        artistTable.reloadData()
        if filteredArtists.count > 0 {
            if selectedArtist > -1 {
                // filteredArtists is a subset of Artists so make sure the selected artist is still there
                let id = artists.table[selectedArtist]["id"] as! Int
                selectedArtist = 0
                for (index, tableRow) in filteredArtists.enumerated() {
                    if tableRow["id"] as! Int == id {
                        selectedArtist = index
                        break
                    }
                }
            }
            else {
                selectedArtist = 0
            }
        }
        else {
            // The filter is empty
            selectedArtist = -1
        }
        if selectedArtist > -1 {
            artistTable.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
            artistTable.scrollRowToVisible(selectedArtist)
        }
    }
    //################################################################################################
    @IBAction func clearButtonClicked(_ sender: NSButton) {
        if selectedArtist > -1 {
            let id = filteredArtists[selectedArtist]["id"] as! Int
            selectedArtist = artists.getIndex(foreignKey: id)
        }
        clearFilter()
    }
    //################################################################################################
    func clearFilter() {
        allRadioButton.state = NSOnState
        allRoleRadioButton.state = NSOnState
        clearButton.isEnabled = false
        artistFilterActive = false
        artistTable.reloadData()
        artistTable.selectRowIndexes(NSIndexSet(index: selectedArtist) as IndexSet, byExtendingSelection: false)
        artistTable.scrollRowToVisible(selectedArtist)
    }
    //################################################################################################
    @IBAction func roleRadioButtonClicked(_ sender: NSButton) {
    }
    //################################################################################################
    @IBAction func radioButtonClicked(_ sender: NSButton) {

    }
    //################################################################################################
    @IBAction func addArtist(_ sender: NSButton) {
        callArtistDialog(type: RequestType.add)
    }
    //################################################################################################
    @IBAction func editArtistMenuItemClicked(_ sender: NSMenuItem) {
        callArtistDialog(type: RequestType.update)
    }
    //################################################################################################
    func callArtistDialog(type: RequestType) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let artistDialogWindowController = storyboard.instantiateController(withIdentifier: "artistWindowControllerScene")
        as! NSWindowController

        if let artistDialogWindow = artistDialogWindowController.window {
            let artistDialogViewController = artistDialogWindow.contentViewController as! ArtistDialogViewController
            artistDialogViewController.processButton.title = "Update"

            let application = NSApplication.shared()
            requestType = type
            artistDialogViewController.delegate = self
            application.runModal(for: artistDialogWindow)

            //print("Back from Modal")
            self.view.window!.makeKey()
            artistTable.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func removeArtistButtonClicked(_ sender: NSButton) {
        if selectedArtist != -1 {
            let deleteID = String(describing: artists.table[selectedArtist]["id"]!)
            artists.deleteRowAndNotify(row: deleteID)
        }
    }
    //################################################################################################
    @IBAction func addInfluenceClicked(_ sender: NSButton) {
        callInfluenceDialog(type: RequestType.add, direction: "from")
    }
    //################################################################################################
    @IBAction func removeInfluenceClicked(_ sender: NSButton) {
        if selectedInfluence != -1 {
            let deleteID = String(describing: influencesFilter[selectedInfluence]["id"]!)
            influences.deleteRowAndNotify(row: deleteID)
        }
    }
    //################################################################################################
    @IBAction func addInfluenceeClicked(_ sender: NSButton) {
        callInfluenceDialog(type: RequestType.add, direction: "to")
    }
    //################################################################################################
    @IBAction func removeInfluenceeClicked(_ sender: NSButton) {
        if selectedInfluencee != -1 {
            let deleteID = String(describing: influencedFilter[selectedInfluencee]["id"]!)
            //print("removeInfluenceeClicked - deleteID: ", deleteID)
            influences.deleteRowAndNotify(row: deleteID)
        }
    }
    //################################################################################################
    func callInfluenceDialog(type: RequestType, direction: String) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let influenceDialogWindowController = storyboard.instantiateController(withIdentifier: "influenceWindowControllerScene")
        as! NSWindowController

        if let influenceDialogWindow = influenceDialogWindowController.window {
            let influenceDialogViewController = influenceDialogWindow.contentViewController as! InfluenceDialogViewController
            influenceDialogViewController.processButton.title = "Update"

            let application = NSApplication.shared()
            dialogDirection = direction
            requestType = type
            influenceDialogViewController.delegate = self
            application.runModal(for: influenceDialogWindow)

            //print("Back from Modal")
            self.view.window!.makeKey()
            influencesTable.becomeFirstResponder()
        }
    }
    //################################################################################################
    @IBAction func goToInfluenceArtistMenuItemClicked(_ sender: NSMenuItem) {
        if selectedInfluence > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.artists
            selectionData["id"] = influencesFilter[selectedInfluence]["influence_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func goToInfluencedArtistMenuItemClicked(_ sender: NSMenuItem) {
        if selectedInfluencee > -1 {
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.artists
            selectionData["id"] = influencedFilter[selectedInfluencee]["influencee_id"] as! Int
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification,
                object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    @IBAction func goToRecordsMenuItemClicked(_ sender: NSMenuItem) {
        if selectedCredit > -1 {
            let recordID = creditsFilter[selectedCredit]["record_id"] as! Int
            var selectionData: [String: Any] = [:]
            selectionData["tab"] = TabType.records
            selectionData["id"] = recordID
            let nc = NotificationCenter.default
            nc.post(name: tabSelectNotification, object: selectionData)
        }
        else {
            dialogErrorWarning(text: "You must first make a selection")
        }
    }
    //################################################################################################
    func filterCredits(foreignKey: Int) {
        creditsFilter = credits.filterCreditsByArtist(id: foreignKey)
        creditTable.reloadData()
    }
    //################################################################################################
    func filterCompositionsByArtist(id: Int) {
        compositionsFilter = composers.filterCompositionsByArtist(id: id)
        compositionTable.reloadData()
    }
    //################################################################################################
    func filterInfluencesByInfluence(id: Int) {
        influencedFilter = influences.filterByInfluence(id: id)
        influencedTable.reloadData()
    }
    //################################################################################################
    func filterInfluencedByInfluencee(id: Int) {
        influencesFilter = influences.filterByInfluencee(id: id)
        influencesTable.reloadData()
    }
}
//####################################################################################################
//####################################################################################################
extension ArtistViewController: tableDataDelegate {

    //################################################################################################
    func getRequestType() -> RequestType {
        return requestType
    }
    //################################################################################################
    func verifyInput(field: String, input: Any) -> Bool {
        var result: Bool = false
        if field == "direction" {
            if input as! String == dialogDirection {
                result = true
            }
        }
        return result
    }
    //################################################################################################
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any> {
        //print("selected artist: ", selectedArtist)
        var returnData: Dictionary<String, Any> = [:]
        switch entity {
            case DataEntity.artist:
                //print("data entity artist")
                if request == RequestType.update || request == RequestType.read {
                    //print("selectedArtist: ", (selectedArtist as Any), " artist row: ",artists.table[selectedArtist])
                    if artistFilterActive == true {
                        returnData = filteredArtists[selectedArtist]
                    }
                    else {
                        returnData = artists.table[selectedArtist]
                    }
                }
            default:
                break
        }
        return returnData
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, typeSelectStringFor tableColumn: NSTableColumn?, row: Int) -> String? {
        var returnString: String?
        returnString = nil
        //print("last name: ", artists.table[row]["last_name"])
        if tableView.tag == artistTableTag {
            returnString = artists.table[row]["last_name"] as? String
        }
        return returnString
    }
}
//####################################################################################################
//####################################################################################################
extension ArtistViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        //print("table view tag: ", tableView.tag)
        switch tableView.tag {
            case artistTableTag:
                if artistFilterActive == true {
                    count = filteredArtists.count
                }
                else {
                    count = artists.table.count
                }
            case creditTableTag:
                count = creditsFilter.count
            case compositionTableTag:
                count = compositionsFilter.count
            case influencesTableTag:
                count = influencesFilter.count
            case influencedTableTag:
                count = influencedFilter.count
            default:
                break
                //print("ArtistViewController-numberOfRows called with unknown tag: ", tableView.tag)
        }
        return count
    }
}
//####################################################################################################
//####################################################################################################
extension ArtistViewController: NSTableViewDelegate {

    func blankOutField(field: NSTextField) {
        field.stringValue = ""
    }

    func blankOutFields() {
        blankOutField(field: name)
        blankOutField(field: birth_year)
        blankOutField(field: death_year)
        blankOutField(field: primary_instrument)
        blankOutField(field: other_instruments)
        blankOutField(field: notes)
    }
    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        //print("Tag: ", tag)
        switch tag {
            case artistTableTag:
            selectedArtist = selectedRow
            if selectedRow >= 0 {
                blankOutFields()
                var artist: [String:Any] = [:]
                if artistFilterActive == true {
                    artist = filteredArtists[selectedRow]
                }
                else {
                    artist = artists.table[selectedRow]
                }
                if let value = artist["name"] as? String {
                    name.stringValue = value
                }
                if let value = artist["birth_year"] as? String {
                    birth_year.stringValue = value
                }
                if let value = artist["death_year"] as? String {
                    death_year.stringValue = value
                }
                if let value = artist["primary_instrument"] as? String {
                    primary_instrument.stringValue = value
                }
                if let value = artist["other_instruments"] as? String {
                    other_instruments.stringValue = value
                }
                if let value = artist["other_instruments"] as? String {
                    notes.stringValue = value
                }

                filterCredits(foreignKey: artist["id"] as! Int)
                filterCompositionsByArtist(id: artist["id"] as! Int)
                filterInfluencesByInfluence(id: artist["id"] as! Int)
                filterInfluencedByInfluencee(id: artist["id"] as! Int)
            }
            case creditTableTag:
                selectedCredit = selectedRow
            case compositionTableTag:
                selectedComposition = selectedRow
            case influencesTableTag:
                selectedInfluence = selectedRow
            case influencedTableTag:
                selectedInfluencee = selectedRow
            default:
                break
        }
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        // blank it here to avoid multiple settings below
        result.textField?.stringValue = ""

        switch tableView.tag {

            case artistTableTag:
                // get an NSTableCellView with an identifier that is the same as the identifier for the column
                // NOTE: you need to set the identifier of both the Column and the Table Cell View
                // in this case the columns are "firstName" and "lastName"

                // get the "Item" for the row
                var item: [String:Any] = [:]
                if artistFilterActive == true {
                    item = filteredArtists[row]
                }
                else {
                    item = artists.table[row]
                }

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
                //print(result.textField?.stringValue)
            case creditTableTag:
                // get the "Item" for the row
                let item = creditsFilter[row]

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
            case  compositionTableTag:
                // get the "Item" for the row
                let item = compositionsFilter[row]

                // get the value for this column
                if let value = item[tableColumn!.identifier] as? String {
                    result.textField?.stringValue = value
                }
            case  influencesTableTag:
                //print("in influences table tag. row: ", row)
                // get the "Item" for the row
                let item = influencesFilter[row]
                //print("item: ", item)
                let artist = artists.getRow(id: item["influence_id"] as! Int)
                result.textField?.stringValue = artist["name"] as! String
                // get the value for this column
                //if let value = item[tableColumn!.identifier] as? String {
                //    result.textField?.stringValue = value
                //}
            case  influencedTableTag:
                //print("in influenced table tag. row: ", row)
                // get the "Item" for the row
                let item = influencedFilter[row]
                //print("item: ", item)
                let artist = artists.getRow(id: item["influencee_id"] as! Int)
                result.textField?.stringValue = artist["name"] as! String

            default:
                break
        }
    return result
    }
    //################################################################################################
    override func controlTextDidChange(_ obj: Notification) {
        let control = (obj.object as AnyObject)
        //print("text did change: ", control)
        switch control.tag {
            case artistTableTag:
                break
                //print("character entry detected.")
            default:
                break
        }
    }
}
