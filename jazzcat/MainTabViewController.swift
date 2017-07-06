//
//  MainTabViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 18/12/16.
//  Copyright © 2016 Curt Rowe. All rights reserved.
//

import Cocoa

enum TabType: Int {
    case artists = 0
    case compositions = 1
    case labels = 2
    case records = 3
    case tracks = 4
}

let tabSelectNotification = Notification.Name(rawValue: "com.zetcho.tabSelection")

class MainTabViewController: NSTabViewController {

    //################################################################################################
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("MainTabViewController - viewDidLoad")
        let nc = NotificationCenter.default
        nc.addObserver(forName: tabSelectNotification, object: nil, queue: nil, using: catchTabSelectionNotification)
    }
    //################################################################################################
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    //################################################################################################
    func catchTabSelectionNotification(notification: Notification) -> Void {
        //print("In catchTabSelectionNotification")
        guard //let userInfo = notification.userInfo,
              //let tab = userInfo["tab"] as? Int,
              let selectionData = notification.object as? [String:Any]
        else {
            print("No userInfo found in catchTabSelectNotification")
            return
        }

        let tab = selectionData["tab"] as! TabType
        let controller = tabViewItems[tab.rawValue].viewController as! JazzCatViewController
        controller.selectRow(selectionData: selectionData)

        Timer.scheduledTimer(timeInterval: 0.2, target: self,
            selector: #selector(switchToTab),
            userInfo: selectionData, repeats: false)
    }
    //################################################################################################
    func switchToTab(timer: Timer) {
        if let selectionData = timer.userInfo as? [String: Any] {
            let tab = selectionData["tab"] as! TabType
            self.selectedTabViewItemIndex = tab.rawValue
            //let controller = tabViewItems[tab.rawValue].viewController as! JazzCatViewController
            //controller.selectRow(selectionData: selectionData)
        }
    }
}
