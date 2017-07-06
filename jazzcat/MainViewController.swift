//
//  MainViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 18/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa
import SwiftAutomation
import MacOSGlues

class MainViewController: NSViewController {

    let nc = NotificationCenter.default

    let tracks = Tracks.shared
    let compositions = Compositions.shared
    let records = Records.shared
    let artists = Artists.shared

    let iTunes = ITunes()
    var jazzCatState: ITUSymbol!
    var timer = Timer()

    var lastPersistentID: String!
    var lastTotalTime: Int!
    var lastTrackName: String!

    let musicQueue = MusicQueue.shared

    let musicQueueTableViewTag = 2
    var selectedMusicQueueItem = -1
    @IBOutlet weak var musicQueueTableView: NSTableView!
    var musicQueueObserver: NSObjectProtocol!

    let performances = Performances.shared

    let performancesTableViewTag = 3
    var selectedPerformance = -1
    @IBOutlet weak var performancesTableView: NSTableView!
    var performanceObserver: NSObjectProtocol!

    @IBOutlet weak var elapsedTimeTextField: NSTextField!
    @IBOutlet weak var remainingTimeTextField: NSTextField!
    @IBOutlet weak var trackTitleTextField: NSTextField!
    @IBOutlet weak var playPauseButton: NSButton!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var scrubBarSlider: NSSlider!
    @IBOutlet weak var clearSelectionButton: NSButton!
    @IBOutlet weak var clearAllButton: NSButton!
    @IBOutlet var peformanceMenu: NSMenu!

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()

        tracks.loadTable()
        compositions.loadTable()
        records.loadTable()
        artists.loadTable()

        musicQueueTableView.tag = musicQueueTableViewTag
        // table is empty on initial load

        performancesTableView.tag = performancesTableViewTag
        performances.loadTable()
        performancesTableView.reloadData()

        if iTunes.isRunning == false {
            do {
                try iTunes.launch()
            }
            catch {
                print("iTunes launch failed. Error: ", error.localizedDescription)
            }
        }

        initializeJazzCatState()

        musicQueueObserver = nc.addObserver(forName:musicQueueUpdateNotification, object:nil, queue:nil,
            using:catchMusicQueueNotification)
        performanceObserver = nc.addObserver(forName:performanceUpdateNotification, object:nil, queue:nil,
            using:catchPerformanceNotification)

        timer = Timer.scheduledTimer(timeInterval: 0.5 , target: self, selector: #selector(self.statusCheck),
            userInfo: nil, repeats: true)
    }
    //################################################################################################
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //print("viewWillDisappear called")
        nc.removeObserver(musicQueueObserver)
        nc.removeObserver(performanceObserver)
    }
    //################################################################################################
    func catchMusicQueueNotification(notification:Notification) -> Void {
        musicQueueTableView.reloadData()
    }
    //################################################################################################
    func catchPerformanceNotification(notification:Notification) -> Void {
        performancesTableView.reloadData()
    }
    //################################################################################################
    @IBAction func goToRecordMenuItemClicked(_ sender: NSMenuItem) {
        let trackID = performances.table[selectedPerformance]["track_id"] as! Int
        let track = tracks.getRow(id: trackID)
        let recordID = track["record_id"] as! Int
        //print("goToRecord: ",recordID as Any)
        var selectionData: [String:Any] = [:]
        selectionData["tab"] = TabType.records
        selectionData["id"] = recordID
        selectionData["item"] = trackID
        let nc = NotificationCenter.default
        nc.post(name:tabSelectNotification,
            object: selectionData)
            //userInfo:["tab": 3])
    }
    //################################################################################################
    @IBAction func trackInformationMenuItemClicked(_ sender: NSMenuItem) {
        var stringDate = ""
        if selectedPerformance > -1 {
            let trackID = performances.table[selectedPerformance]["track_id"] as! Int
            let performanceDate = performances.table[selectedPerformance]["performed"] as! String
            let track = tracks.getRow(id: trackID)
            let compositionID = track["composition_id"] as! Int
            let composition = compositions.getRow(id: compositionID)
            let header = composition["name"] as! String
            let recordID = track["record_id"] as! Int
            let record = records.getRow(id: recordID)
            let recordName = record["name"] as! String
            let artistID = record["artist_id"] as! Int
            let artist = artists.getRow(id: artistID)
            let artistName = artist["name"] as! String

            let ISO8601DateFormatter = DateFormatter()
            ISO8601DateFormatter.locale = Locale(identifier: "en_US_POSIX")
            ISO8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ISO8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = ISO8601DateFormatter.date(from: performanceDate) {
                //print("date: ", date)
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
                stringDate = dateFormatter.string(from: date)
            }
            let text = "Record: \(recordName)\r\nLeader: \(artistName)\r\nDate: \(stringDate)"
            dialogInformation(header: header, text: text)
        }
    }
    //################################################################################################
    @IBAction func volumeSliderMoved(_ sender: NSSlider) {
        //print("volume:", volumeSlider.integerValue)
        let sliderVolume = volumeSlider.integerValue as Int
        do {
            try iTunes.soundVolume.set(to: sliderVolume)
        }
        catch {
            print("Error setting iTunes volume")
        }
    }
    //################################################################################################
    @IBAction func playPauseButtonClicked(_ sender: NSButton) {
        do {
            try iTunes.playpause()
            processEvent()
        }
        catch {
            print("Play/Pause failed")
        }
    }
    //################################################################################################
    @IBAction func clearAllButtonClicked(_ sender: NSButton) {
        musicQueue.clear()
    }
    //################################################################################################
    @IBAction func clearSelectionButtonClicked(_ sender: NSButton) {
        if selectedMusicQueueItem > -1 {
            musicQueue.remove(at: selectedMusicQueueItem)
        }
    }
    //################################################################################################
    func statusCheck(timer: Timer) {
        processEvent()
    }
    //################################################################################################
    func processEvent() {
        var iTunesState: ITUSymbol!
        var iTunesPersistentID: String!

        do {
            iTunesState = try iTunes.playerState.get() as ITUSymbol
        }
        catch {
            print("playerState call failed.")
            return
        }

        // Volume can be changed in any state.
        setVolume()

        switch jazzCatState {
            case ITU.stopped:
                switch iTunesState {
                    case ITU.stopped:
                        break
                    case ITU.paused:
                        setTrackTitle()
                        setElapsedTime()
                    case ITU.playing:
                        playPauseButton.title = "Pause"
                        setTrackTitle()
                        setElapsedTime()
                    default:
                        break
                }
            case ITU.paused:
                //iTunesPersistentID = getPersistentID()
                switch iTunesState {
                    case ITU.stopped:
                        break
                    case ITU.paused:
                        break
                    case ITU.playing:
                        playPauseButton.title = "Pause"
                    default:
                        break
                }
            case ITU.playing:
                switch iTunesState {
                    case ITU.stopped:
                        playPauseButton.title = "Play"
                        clearTrackTitle()
                        clearElapsedTime()
                        updateTrackHistory()
                        processMusicQueue()
                    case ITU.paused:
                        playPauseButton.title = "Play"
                    case ITU.playing:
                        // Either the same track is playing or a new started without the old one finishing
                        iTunesPersistentID = getPersistentID()
                        if iTunesPersistentID != lastPersistentID {
                            setTrackTitle()
                        }
                        setElapsedTime()
                    default:
                        break
                }
                lastPersistentID = iTunesPersistentID
            default:
                break
        }
        jazzCatState = iTunesState
    }
    //################################################################################################
    func getPersistentID() -> String {
        do {
            return try iTunes.currentTrack.persistentID.get() as String
        }
        catch {
            print("persistent ID call failed.")
            return ""
        }
    }
    //################################################################################################
    //playerState (ITU.stopped/‌ITU.playing/‌ITU.paused/‌ITU.fastForwarding/‌ITU.rewinding, r/o) :
    // is iTunes stopped, paused, or playing?
    func initializeJazzCatState() {
        var iTunesState: ITUSymbol!

        lastTotalTime = 0
        lastTrackName = ""

        do {
            iTunesState = try iTunes.playerState.get() as ITUSymbol
        }
        catch {
            print("playerState call failed.")
            return
        }
        switch iTunesState {
            case ITU.stopped:
                playPauseButton.title = "Play"
                clearTrackTitle()
                clearElapsedTime()
            case ITU.paused:
                playPauseButton.title = "Play"
                setTrackTitle()
                setElapsedTime()
            case ITU.playing:
                playPauseButton.title = "Pause"
                setTrackTitle()
                setElapsedTime()
            default:
                print("Not supporting this player state.")
        }
        jazzCatState = iTunesState
    }
    //################################################################################################
    func processMusicQueue() {
        if musicQueue.count() > 0 {
        //if playList.count > 0 {
            let trackId = musicQueue.dequeue()
            let row = tracks.getIndex(foreignKey: trackId)
            //print("play list row id: ", row)
            let persistentId = tracks.table[row]["persistent_id"] as! String
            //print("track persistent_id: ", persistentId)
            do {
                try iTunes.tracks[ITUIts.persistentID == persistentId].play()
            }
            catch {
                print("Play from playlist failed.")
            }
            musicQueueTableView.reloadData()
        }
    }
    //################################################################################################
    func setTrackTitle() {
        do {
            let currentTrackName = try iTunes.currentTrack.name.get() as String
            // Avoid unnecessarily updating a display variable
            if currentTrackName != lastTrackName {
                //if currentTrackName != "" {
                trackTitleTextField.stringValue = currentTrackName
                //}
            }
            lastTrackName = currentTrackName
        }
        catch {
            print("Track name fetch failed.")
        }
    }
    //################################################################################################
    func clearTrackTitle() {
        trackTitleTextField.stringValue = ""
    }
    //################################################################################################
    func updateTrackHistory() {
        var updateRow: [String: Any] = [:]
        var performanceRow: [String:Any] = [:]
        var playCount = 0
        var playedDate: Date?

        do {
            playCount = try iTunes.tracks[ITUIts.persistentID == lastPersistentID].playedCount.get() as Int
            updateRow["play_count"] = playCount
        }
        catch {
            print("MainViewController: failed to retrieve playedCount from iTunes")
        }

        do {
            playedDate = try iTunes.tracks[ITUIts.persistentID == lastPersistentID].playedDate.get()
            //print("playedDate set: ", playedDate)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            let iLastPlayedDate = dateFormatter.string(from: (playedDate!))
            updateRow["last_played"] = iLastPlayedDate

            if let currentRow = tracks.getPersistentID(persistentID: lastPersistentID) {
                let rowID = String(describing: currentRow["id"]!)
                tracks.updateRowAndNotify(row: rowID, rowData: updateRow)

                performanceRow["track_id"] = currentRow["id"]! as! Int
                performanceRow["performed"] = iLastPlayedDate
                performances.addRowAndNotify(rowData: performanceRow)
            }
        }
        catch {
            print("MainViewController: failed to retrieve playedData from iTunes")
        }
    }
    //################################################################################################
    // Synchronize volume changes between this app and iTunes.
    func setVolume() {
        let sliderVolume = volumeSlider.integerValue as Int
        var iTunesVolume = 0
        do {
            iTunesVolume = try iTunes.soundVolume.get() as Int
        }
        catch {
            print("Couldn't get volume from iTunes")
        }

        if iTunesVolume != sliderVolume {
            volumeSlider.integerValue = iTunesVolume
        }
    }
    //################################################################################################
    func clearElapsedTime() {
        elapsedTimeTextField.stringValue = ""
        remainingTimeTextField.stringValue = ""
        scrubBarSlider.isHidden = true
    }
    //################################################################################################
    func setElapsedTime()
    {
        var totalTime = 0

        scrubBarSlider.isHidden = false

        do {
            let trackName = try iTunes.currentTrack.name.get() as String
            if trackName == "KCSM" {
                clearElapsedTime()
                return
            }
            let trackTime = try iTunes.currentTrack.time.get() as String
            let parts = matches(for: "[0-9]+", in: trackTime)
            totalTime = Int(parts[0])! * 60 + Int(parts[1])!
        }
        catch {
            // let totalTime indicate nothing returned.
        }
        if totalTime > 0 {
            do {
                let elapsed = try iTunes.playerPosition.get() as Int
                elapsedTimeTextField.stringValue = stringTime(time: elapsed)
                remainingTimeTextField.stringValue = stringTime(time: totalTime - elapsed)
                if lastTotalTime != totalTime {
                    scrubBarSlider.maxValue = Double(totalTime)
                    lastTotalTime = totalTime
                }
                scrubBarSlider.integerValue = elapsed
            }
            catch {
                print("Error getting playerPosition")
            }
        }
        else {
            elapsedTimeTextField.stringValue = ""
        }
    }
    //################################################################################################
    func stringTime(time: Int) -> String {
        var textTime = ""
        let minutes = time/60
        let seconds = time % 60
        if seconds > 9 {
            textTime = "\(minutes):\(seconds)"
        }
        else {
            textTime = "\(minutes):0\(seconds)"
        }
        return textTime
    }
}
//####################################################################################################
//####################################################################################################
extension MainViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        switch tableView.tag {
            case musicQueueTableViewTag:
                count = musicQueue.count()
            case performancesTableViewTag:
                count = performances.table.count
            default:
                count = 0
        }
        return count
    }
}
//####################################################################################################
//####################################################################################################
extension MainViewController: NSTableViewDelegate {

    //################################################################################################
    func tableViewSelectionDidChange(_ notification: Notification) {
        //print("tableViewSelectionDidChange: starting")
        // which row was selected?
        // selectedRow is -1 if you click in the table, but not on a row
        guard let tag = (notification.object as AnyObject).tag,
              let selectedRow = (notification.object as AnyObject).selectedRow else {
            return
        }
        switch tag {
            case musicQueueTableViewTag:
                selectedMusicQueueItem = selectedRow
            case performancesTableViewTag:
                selectedPerformance = selectedRow
            default :
                print("MasterViewController-selectionDidChange: entered the default")
        }
    }
    //################################################################################################
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // get an NSTableCellView with an identifier that is the same as the identifier for the column
        // NOTE: you need to set the identifier of both the Column and the Table Cell View
        // in this case the columns are "firstName" and "lastName"
        let result = tableView.make(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        //let column = tableColumn!.identifier
        //print("column: ", column)
        // blank it here to avoid multiple settings below
        result.textField?.stringValue = ""

        switch tableView.tag {
            case musicQueueTableViewTag:
                let trackId = musicQueue.table[row]
                let track = tracks.getRow(id: trackId)
                let composition = compositions.getRow(id: track["composition_id"] as! Int)
                result.textField?.stringValue = composition["name"] as! String
            case performancesTableViewTag:
                let item = performances.table[row]
                let track = tracks.getRow(id: item["track_id"] as! Int)
                let composition = compositions.getRow(id: track["composition_id"] as! Int)
                result.textField?.stringValue = composition["name"] as! String
            default:
                print("Filter table column entered the default")
        }
        return result
    }
}
