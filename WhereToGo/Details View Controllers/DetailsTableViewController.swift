//
//  DetailsTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 25.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

class DetailsTableViewController: UITableViewController {

    // MARK: - Private Properties
    // --------------------------
    
    struct TableRow {
        let reuseIdentifier: String
        let configFunc: (UITableViewCell)->Void
        let selectFunc: ()->Void
    }
    
    var tableRows: [TableRow] = []
    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    
    // MARK: - Table view Delegate
    // ---------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let selectFunc = tableRows[indexPath.row].selectFunc
        selectFunc()
    }
    
    
    // MARK: - Table view data source
    // ------------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableRows[indexPath.row].reuseIdentifier, for: indexPath)
        
        let rowFunc = tableRows[indexPath.row].configFunc
        rowFunc(cell)
        
        return cell
    }
    
}
