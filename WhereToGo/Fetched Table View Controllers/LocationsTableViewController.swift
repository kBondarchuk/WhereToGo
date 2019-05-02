//
//  LocationsTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 18.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

final class LocationsTableViewController: FetchedTableViewController<Location, UITableViewCell>, ModelControllerDependent {

    // MARK: - Public Preperties
    // -------------------------
    
    var modelController: ModelController!
    
    
    
    // MARK: - Actions
    // ---------------
    
    @IBAction func actionCancel(_ sender: Any)
    {
        presentingViewController?.dismiss(animated: true)
    }
    
    
    
    // MARK: - Private Methods
    // -----------------------
    
    func initializeFetchedResultsController() {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        let sort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sort]
        
        let moc = DataController.persistentContainer.viewContext
        
        resultsController = NSFetchedResultsController<Location>(fetchRequest: request,
                                                                 managedObjectContext: moc,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
        
        resultsController?.delegate = self
        
        do {
            try resultsController?.performFetch()
        } catch {
            fatalError("[!] Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    override func configureCell(_ cell: UITableViewCell, for object: Location)
    {
        cell.textLabel?.text = object.name
    }

    
    
    // MARK: - UIViewController
    // ------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(modelController != nil, "modelController has not been set.")
        
        // Init Cell
        self.cellReuseIdentifier = IBConstants.Cells.location
        
        // Init CoreData
        self.initializeFetchedResultsController()
        
        
        BKLog(self.modelController.name)
        
        
        BKLog("Start Loading Locations...")
        // Load Data
        modelController.requestLocations() { isOK, errorString in
            if isOK {
                BKLog("Loading completed successfully!")
            }else{
                // Error
                DispatchQueue.main.async { showAlert(with: self, title: IBConstants.LocalizedStrings.errorAlertTitle, message: errorString) }
            }
        }
    }


 
    // MARK: - UITableViewDelegate
    // ---------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let city = resultsController?.object(at: indexPath)
        
        modelController.filter = ModelController.Filter(currentCity: city, since: modelController.filter.since)
        
        presentingViewController?.dismiss(animated: true)
    }




}



