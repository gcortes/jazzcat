//
//  RailsData.swift
//  An imitation of Core Data. Data is obtained from a Rails API application.
//
//  Created by Curt Rowe on 13/1/17.
//  Copyright © 2017 Curt Rowe. All rights reserved.
//

import Cocoa

class RailsData {
    let domain = "http://catbox.loc/"
    var dispatchGroup = DispatchGroup() // Create a dispatch group
    var table: [[String:Any]] = []  // the longer form: [Dictionary<String, Any>] = []
    var isLoaded: Bool = false

    //################################################################################################
    func loadRailsTable(rest: String) {
        let url = domain + rest
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared

        dispatchGroup.enter()
        session.dataTask(with: request) { data, response, err in
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                do {
                    self.table = []     // empty the table
                    self.table = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [[String: Any]]
                }
                catch {
                    print(error)
                }
                self.isLoaded = true
                self.dispatchGroup.leave()
            }.resume()
    }
    //################################################################################################
    func filterRailsTable(rest: String, completionHandler: @escaping ([[String: Any]]?) -> Void) {
        let url = domain + rest
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared

        dispatchGroup.enter()
        session.dataTask(with: request) { data, response, err in
                var filter: [[String: Any]] = []
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                do {
                    filter = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [[String: Any]]
                }
                catch {
                    print(error)
                }
                DispatchQueue.main.async(execute: { completionHandler(filter) })
                self.dispatchGroup.leave()
            }.resume()
    }
    //################################################################################################
    func addRailsRow(rest: String, rowData: Dictionary<String, Any>, completionHandler: @escaping ([String: Any]?) -> Void) {
        let url = domain + rest
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        var newRowData: [String:Any]? = nil

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: rowData)
        }
        catch {
            print(error)
        }

        dispatchGroup.enter()
        session.dataTask(with: request) { data, response, err in
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                do {
                    newRowData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
                    //print("Response: ", newRowData)
                }
                catch {
                    print(error)
                }
            DispatchQueue.main.async(execute: { completionHandler(newRowData) })
                self.dispatchGroup.leave()
            }.resume()
    }
    //################################################################################################
    func updateRailsRow(rest: String, rowData: Dictionary<String, Any>, roundTrip: Any? = nil,
                        completionHandler: @escaping ([String: Any]?, Any?) -> Void) {
        let url = domain + rest
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        var newRowData: [String:Any]? = nil

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: rowData)
        }
        catch {
            print(error)
        }

        dispatchGroup.enter()
        session.dataTask(with: request) { data, response, err in
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                do {
                    newRowData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
                    //print("Response: ", newRowData)
                }
                catch {
                    print(error)
                }
                DispatchQueue.main.async(execute: { completionHandler(newRowData, roundTrip) })
                self.dispatchGroup.leave()
            }.resume()
    }
    //################################################################################################
    func deleteRailsRow(rest: String, completionHandler: @escaping (Any) -> Void, roundTrip: Any) {
        let url = domain + rest
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared

        dispatchGroup.enter()
        session.dataTask(with: request) { data, response, err in
                if err != nil {
                    print(err!.localizedDescription)
                    return
                }
                DispatchQueue.main.async(execute: { completionHandler(roundTrip) })
                self.dispatchGroup.leave()
            }.resume()
    }
    //################################################################################################
    // All tables have a primary key named id. All id columns start at 1
    func getRow(id: Int) -> [String:Any] {
        var foundRow: [String:Any] = [:]
        for row in table {
            if row["id"] as? Int == id {
                foundRow = row
                return foundRow
            }
        }
        dialogErrorReason(text: "RailsData getRow: Database Corruption. ID \(id)")
        return foundRow
    }
    //################################################################################################
    // All tables have a primary key named id. All id columns start at 1
    func getIndex(foreignKey: Int) -> Int {
        var key: Int = -1
        for (index, tableRow) in table.enumerated() {
            if tableRow["id"] as! Int == foreignKey {
                key = index
                break
            }
        }
        return key
    }
}


