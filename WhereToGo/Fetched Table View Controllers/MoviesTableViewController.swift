//
//  MoviesCategoryTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

final class MoviesTableViewController: FetchedTableViewController<Movie, MovieTableViewCell>, ModelControllerDependent {

    typealias ObjectType = Movie
    
    // MARK: - Public Preperties
    // -------------------------
    
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
    
    
    // MARK: - Private Methods
    // -----------------------
    
    private func initializeFetchedResultsController()
    {
        let request: NSFetchRequest = ObjectType.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Movie.id), ascending: false)
        request.sortDescriptors = [sort]
        
        request.fetchBatchSize = 50
        request.returnsObjectsAsFaults = false
        
        resultsController = NSFetchedResultsController<ObjectType>(fetchRequest: request,
                                                                 managedObjectContext: modelController.viewContext,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
        
        resultsController?.delegate = self
        
    }
    
    private func performFetch(with city: Location?)
    {
        guard city != nil else {
            return
        }
        
        let lastSyncTime = Movie.getLastSyncTimestamp(in: resultsController!.managedObjectContext) ?? 0
        BKLog("Movie timestamp: \(lastSyncTime)")
        
        
        // Change predicate
        
        resultsController?.fetchRequest.predicate =  NSPredicate(format: "%K >= %la", #keyPath(Movie.timeStamp), lastSyncTime)
        
        do {
            try resultsController?.performFetch()
        } catch {
            fatalError("[!] Failed to initialize FetchedResultsController: \(error)")
        }
        
        BKLog("Fetched objects: \(resultsController?.fetchedObjects?.count ?? 0)")
    }
    
    func loadImage(for object: Movie)
    {
        if let url = URL(string: object.poster_thumbnails_url ?? ""){

            DispatchQueue.global(qos: .userInitiated).async {

                if let imageData = try? Data(contentsOf: url){
                    // UI
                    DispatchQueue.main.async {
                        BKLog(imageData.debugDescription)
                        object.poster_thumbnail = imageData
                    }

                }

            }
        }
    }
    
    private func locationDidChange()
    {
        updateUI()
        refreshControl?.refresh()
    }
    
    private func updateUI()
    {
        if let city = modelController.filter.currentCity {
            
            // Set the Navigation bar title to city name
            tabBarController?.navigationItem.title = modelController.filter.currentCity?.name
            
            // Change predicate
            self.performFetch(with: city)
            
            tableView.reloadData()
        }
    }
    
    private func configureUI()
    {
        // TableView configuration fot iOS 10
        if #available(iOS 11, *) {

        } else {
            self.tableView.contentInset.bottom = 50
        }
        
        
        // Register Custom Cell
        let nib = UINib(nibName: IBConstants.Cells.movies, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: self.cellReuseIdentifier!)
    }
    
    private func addLocationObserver()
    {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: IBConstants.locationDidChangeNotification),
                                               object: nil, queue: nil) { _ in self.locationDidChange() }
    }
    
    private func loadData()
    {
        guard let city = modelController.filter.currentCity?.slug else {
            return
        }
    
        BKLog("UI: Start Loading Movies...")
        
        // Load Data
        modelController.requestMovies(city: city, placeId: nil) { isOK, errorString in
            DispatchQueue.main.async {
                
                self.refreshControl?.endRefreshing()
                
                if isOK {
                    // UI
                    BKLog("UI: Loading Movies completed successfully!")
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
        
        assert(modelController != nil, "modelController has not been set.")
        
        // FetchedTableViewController's Init Cell
        self.cellReuseIdentifier = IBConstants.Cells.movies
        
        // TableView configuration
        configureUI()
        
        // Init CoreData
        self.initializeFetchedResultsController()
        
        // Fetch Core Data and Update UI
        updateUI()
        
        // Observe Location Change
        addLocationObserver()
        
        
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !didRefresh, modelController.filter.currentCity != nil {
            refreshControl?.refresh()
            didRefresh = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.movieDetails,
            let destinationVC = segue.destination as? MovieDetailsTableViewController,
            let selectedRow = tableView.indexPathForSelectedRow {
            
                destinationVC.movie = resultsController?.object(at: selectedRow )
                destinationVC.modelController = self.modelController
        }
        
    }
    
    
    // MARK: - FetchedTableViewController
    // ----------------------------------
    
    override func configureCell(_ cell: MovieTableViewCell, for object: ObjectType)
    {
        cell.configure(for: object)
    }
    
    
    // MARK: - UITableViewController Delegate
    // --------------------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: IBConstants.Segues.movieDetails, sender: self)

    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if let object = resultsController?.object(at: indexPath), object.poster_thumbnail == nil {
            //BKLog("Need to load image for object: \(object.objectID) at \(indexPath)", prefix: "0")
            loadImage(for: object)
        }
    }
    

}
