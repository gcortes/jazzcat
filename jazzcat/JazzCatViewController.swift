//
//  JazzCatViewController.swift
//  jazzcat
//
//  Created by Curt Rowe on 21/6/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa

class JazzCatViewController: NSViewController {

    func selectRow(selectionData: [String:Any]) {
        // This is an abstract function and must be overridden by any child class
        // Do not call super.selectRow from the overridding function
        print("JazzCatViewController:selectRow - This function should not be called")
    }
}