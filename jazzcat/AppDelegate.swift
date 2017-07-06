//
//  AppDelegate.swift
//  jazzcat
//
//  Created by Curt Rowe on 30 Nov 2016.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

protocol tableDataDelegate {
    func getDataSourceRow(entity: DataEntity, request: RequestType) -> Dictionary<String, Any>
    func getRequestType() -> RequestType
    func verifyInput(field: String, input: Any) -> Bool
}

// global constants

enum RequestType {
    case add
    case read
    case update
    case delete
}
enum DataEntity {
    case artist
    case credit
    case composer
    case composition
    case influence
    case label
    case record
    case track
}
// Used with a state machine in the table add/updata dialogs
enum DialogState {
    case ready
    case valid
    case invalid
}
// Maintained for input fields
enum InputStatus {
    case valid
    case invalid
}

//################################################################################################
func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range)}
    }
    catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}
//################################################################################################
// todo: refactor these three functions into one?
func dialogErrorReason(text: String) {
    let dialog: NSAlert = NSAlert()
    dialog.alertStyle = NSAlertStyle.critical
    dialog.messageText = "Error"
    dialog.informativeText = text
    dialog.addButton(withTitle: "OK")
    dialog.runModal()
}
//################################################################################################
func dialogErrorWarning(text: String) {
    let dialog: NSAlert = NSAlert()
    dialog.alertStyle = NSAlertStyle.warning
    dialog.messageText = "Warning"
    dialog.informativeText = text
    dialog.addButton(withTitle: "OK")
    dialog.runModal()
}
//################################################################################################
func dialogInformation(header: String, text: String) {
    let dialog: NSAlert = NSAlert()
    dialog.alertStyle = NSAlertStyle.informational
    dialog.messageText = header
    dialog.informativeText = text
    dialog.addButton(withTitle: "OK")
    dialog.runModal()
}
//################################################################################################
func dialogOKCancel(question: String, text: String) -> Bool {
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
}

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
  }
}

