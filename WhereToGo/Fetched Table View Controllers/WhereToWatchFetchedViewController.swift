//
//  WhereToWatchFetchedViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 13.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

final class WhereToWatchFetchedViewController: FetchedTableViewController<MovieShowing, UITableViewCell>, TableViewHeaderDelegate, ModelControllerDependent {
    
    // MARK: - Public Preperties
    // -------------------------
    
    var movie: Movie!
    var modelController: ModelController!
    
    
    
    // MARK: - Actions
    // ---------------
    
    @IBAction func actionRefresh(_ sender: Any)
    {
        BKLog()
        loadData()
    }
    
    
    // MARK: - Private Properties
    // --------------------------
    
    private var didRefresh: Bool = false
    
    
    // MARK: - Private Properties
    // --------------------------
    
    let dateFormat: DateFormatter = {
        let df = DateFormatter()
        //df.dateStyle = .medium
        df.setLocalizedDateFormatFromTemplate("EEEE, j:mm")
        //df.dateFormat = "EEEE, MM"
        df.locale = NSLocale.current
        return df }()
    
        
    

    
    // MARK: - Private Methods
    // -----------------------
    
    func initializeFetchedResultsController()
    {
        let request: NSFetchRequest = MovieShowing.fetchRequest()
        let placeSort = NSSortDescriptor(key: "place.title", ascending: true)
        let timeSort = NSSortDescriptor(key: "dateTime", ascending: true)
        //let modelSort = NSSortDescriptor(key: "model", ascending: true)
        request.sortDescriptors = [placeSort, timeSort]
        
        let moc = DataController.persistentContainer.viewContext
        
        resultsController = NSFetchedResultsController<MovieShowing>(fetchRequest: request,
                                                                     managedObjectContext: moc,
                                                                     sectionNameKeyPath: "place.title",
                                                                     cacheName: nil)
        
        resultsController?.delegate = self
        
    }
    
    private func performFetch(with city: Location?, since: Date, until: Date)
    {
        guard city != nil, movie != nil else {
            return
        }
        
        // Change predicate "movie == %@ AND dateTime >= %@ AND place.location == %@"
        resultsController?.fetchRequest.predicate = NSPredicate(format: "movie == %@ AND dateTime >= %@ AND dateTime <= %@ AND place.location == %@", movie!, since as NSDate, until as NSDate, city!)
        do {
            try resultsController?.performFetch()
        } catch {
            fatalError("[!] Failed to initialize FetchedResultsController: \(error)")
        }
        
        BKLog("Fetched objects: \(resultsController?.fetchedObjects?.count ?? 0)")
    }
    
    override func configureCell(_ cell: UITableViewCell, for object: MovieShowing)
    {
        configureRow(cell, title: dateFormat.string(from: object.dateTime! as Date).capitalized, text: object.price)
    }

    
    
    
    private func configureRow(_ cell: UITableViewCell, title: String, text: String?)
    {
        if let label = cell.viewWithTag(2) as? UILabel {
            label.text = title
        }
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = text
        }
    }
    
    private func configureUI()
    {
        // Movie cell (section header)
        tableView.register(TableViewHeader.self, forHeaderFooterViewReuseIdentifier: IBConstants.Cells.prototypeHeader)
        
        let nib = UINib(nibName: IBConstants.Cells.movieHeader, bundle: nil)
        if let headerCell = nib.instantiate(withOwner: nil, options: nil)[0] as? MovieTableViewHeader {
            tableView.tableHeaderView = headerCell
            
            headerCell.contentView.backgroundColor = UIColor.white
        }
    }
    
    private func updateUI()
    {
        if movie != nil {
            
            // Display Movie details
            if let headerCell = tableView.tableHeaderView as? MovieTableViewHeader {
                headerCell.configure(for: movie!)
            }

            if let city = modelController.filter.currentCity{
            
                // Change title
                navigationItem.title = String.localizedStringWithFormat( IBConstants.LocalizedStrings.whereToWatchTitleFormat, city.name ?? "-")
                
                // Fetch request
                performFetch(with: modelController.filter.currentCity, since: modelController.filter.since, until: modelController.filter.until)
                
                // Reload
                tableView.reloadData()
            }
        }
    }

    private func loadData()
    {
        
        guard let city = modelController.filter.currentCity?.slug else {
            return
        }
        
        BKLog("UI: Start Loading Showings for Movie <\(movie.id)>...")
        
        // Load Data Movies for Place
        modelController.requestShowingsOfMovie(city: city, movieId: Int(movie.id),
                                               since: self.modelController.filter.since,
                                               until: self.modelController.filter.until)
            { isOK, errorString in
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    
                    if isOK {
                        // UI
                        BKLog("UI: Loading Showings for Movie <\(self.movie.id)> successfull!")
                        self.updateUI()
                    }else {
                        // Error
                        showAlert(with: self, title: IBConstants.LocalizedStrings.errorAlertTitle, message: errorString)
                    }
                }

            }
        
    }
    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(modelController != nil, "'modelController' has not been set.")
        assert(movie != nil, "'movie' has not been set.")
        
        // FetchedTableViewController's Init Cell
        self.cellReuseIdentifier = IBConstants.Cells.dualText
        
        // TableView configuration
        configureUI()
        
        // Init CoreData
        self.initializeFetchedResultsController()
        
        // Fetch Core Data and Update UI
        updateUI()
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !didRefresh {
            refreshControl?.refresh()
            didRefresh = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.placeDetails,
            let destinationVC = segue.destination as? PlaceDetailsTableViewController,
            let headerView = sender as? TableViewHeader {
            let selectedSection = headerView.tag
            if let object = resultsController?.sections?[selectedSection].objects?.first as? MovieShowing,
                let place = object.place{
                
                destinationVC.modelController = self.modelController
                destinationVC.place = place
            }
        }
    }
    
    
    
    // MARK: - MovieTableViewHeaderDelegate
    // ------------------------------------
    func headerDidSelect(sender: UITableViewHeaderFooterView)
    {
        performSegue(withIdentifier: IBConstants.Segues.placeDetails, sender: sender)
    }
    
    

    // MARK: - Table view data source
    // ------------------------------
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return resultsController?.sections?[section].name
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        guard let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: IBConstants.Cells.prototypeHeader) as? TableViewHeader else {
            fatalError("Unexpected header cell type at section \(section)")
        }
        
        headerCell.delegate = self
        headerCell.tag = section
        
        return headerCell
    }
    
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
//    {
//        return 60
//    }
}
