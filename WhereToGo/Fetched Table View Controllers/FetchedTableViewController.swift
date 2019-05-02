//
//  FetchedTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 20.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

class FetchedTableViewController<T:NSFetchRequestResult, C:UITableViewCell>: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Public Properties
    // -------------------------
    
    var resultsController: NSFetchedResultsController<T>?
    var cellReuseIdentifier: String?
    
    
    
    // MARK: - Private Methods
    // -----------------------
    
    func configureCell(_ cell: C, for object: T)
    {
            BKLog("You have to override configureCell()", prefix: "!")
    }
    

    
    // MARK: - Table view data source
    // ------------------------------
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return resultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let section = resultsController?.sections?[section] {
            return section.numberOfObjects
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier!, for: indexPath) as? C else {
            fatalError("Unexpected cell type at \(indexPath)")
        }
        
        if let object = resultsController?.object(at: indexPath) {
            configureCell(cell, for: object)
        }
        
        return cell
    }


    // MARK: NSFetchedResultsControllerDelegate
    // ----------------------------------------

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        //BKLog("", prefix: "{")
        tableView.beginUpdates()
        
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        //BKLog("controller controllerDidChangeContent", prefix: "}")
        tableView.endUpdates()
        
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {

        //BKLog("controller didChange SectionInfo: \(type.rawValue)")

        switch type {

        case .insert:
            //BKLog("    - insert Section")
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)

        case .delete:
            //BKLog("    - delete Section")
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)

        case .move:
            BKLog("    - move Section")

        case .update:
            BKLog("    - update Section")

        }

    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        //BKLog("", prefix: "*")
        switch type {

        case .insert:
            //BKLog("    - insert object")
            tableView.insertRows(at: [newIndexPath!], with: .fade)

        case .delete:
            //BKLog("    - delete object")
            tableView.deleteRows(at: [indexPath!], with: .fade)

        case .move:
            //BKLog("    - move object")
            tableView.moveRow(at: indexPath!, to: newIndexPath!)

        case .update:
            //let object = anObject as! NSManagedObject
            //BKLog("    - update object id: \(object.objectID) at \(String(describing: indexPath)), new:  \(String(describing: newIndexPath))", prefix: "1")
                //tableView.reloadRows(at: [indexPath!], with: .none)
            if let cell = tableView.cellForRow(at: indexPath!) as? C {
                configureCell(cell, for: anObject as! T)
            }

        }
    }
    
    
    
}


