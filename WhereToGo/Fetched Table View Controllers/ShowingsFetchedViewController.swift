//
//  ShowingsFetchedViewController
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 28.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

final class ShowingsFetchedViewController: FetchedTableViewController<MovieShowing, UITableViewCell>, TableViewHeaderDelegate, ModelControllerDependent {
    
    // MARK: - Public Preperties
    // -------------------------
    
    var modelController: ModelController!
    var place: Place!
    
    
    
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
    
    let dateFormat: DateFormatter = {
        let df = DateFormatter()
        //df.dateStyle = .medium
        df.setLocalizedDateFormatFromTemplate("EEEE, j:mm")
        //df.dateFormat = "EEEE, MM"
        df.locale = NSLocale.current
        return df }()
    
    
    
    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var theaterTitle: UILabel!
    @IBOutlet weak var theaterAddress: UILabel!
    @IBOutlet weak var theaterPhone: UILabel!
    @IBOutlet weak var theaterTimetable: UILabel!
    
    
    
    // MARK: - Actions
    // ---------------
    
    @IBAction func actionTapHeader(_ sender: Any)
    {
        BKLog("", prefix: "!")
        performSegue(withIdentifier: IBConstants.Segues.placeDetails, sender: self)
    }
    
    
    // MARK: - Private Methods
    // -----------------------
    
    func initializeFetchedResultsController()
    {
        let request: NSFetchRequest = MovieShowing.fetchRequest()
        let movieSort = NSSortDescriptor(key: "movie.title", ascending: true)
        let timeSort = NSSortDescriptor(key: "dateTime", ascending: true)
        //let modelSort = NSSortDescriptor(key: "model", ascending: true)
        request.sortDescriptors = [movieSort, timeSort]
        
        let moc = DataController.persistentContainer.viewContext
        
        resultsController = NSFetchedResultsController<MovieShowing>(fetchRequest: request,
                                                                 managedObjectContext: moc,
                                                                 sectionNameKeyPath: "movie.title",
                                                                 cacheName: nil)
        
        resultsController?.delegate = self

    }
    
    private func performFetch(with city: Location?)
    {
        guard city != nil else {
            return
        }
        
        
        // Change predicate
        resultsController?.fetchRequest.predicate = NSPredicate(format: "location == %@", city!)
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
    
    private func loadData()
    {
        guard let city = modelController.filter.currentCity?.slug else{
            return
        }

        BKLog("UI: Start Loading Movies for Place <\(place.id)>...")
        
        // Load Data Movies for Place
        modelController.requestMovies(city: city, placeId: Int(place.id)) { isOK, errorString in
            if isOK {
                BKLog("UI: Loading Movies for Place <\(self.place.id)> successfull!")
                BKLog("UI: Start Loading Movie Showings for Place <\(self.place.id)>...")
                // Load Data Showings For Place
                self.modelController.requestMovieShowings(city: city, placeId: Int(self.place.id), since: self.modelController.filter.since, until: self.modelController.filter.until) { isOK, errorString in
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                        
                        if isOK {
                            // UI
                            BKLog("UI: Loading Movie Showings for Place completed successfully!")
                            self.updateUI()
                        }else {
                            // Error
                            showAlert(with: self, title: IBConstants.LocalizedStrings.errorAlertTitle, message: errorString)
                        }
                    }
                }
                
                
            }else {
                DispatchQueue.main.async {
                    // Error
                    showAlert(with: self, title: IBConstants.LocalizedStrings.errorAlertTitle, message: errorString)}
            }
        }
        
    }
    
    private func configureUI()
    {
        // Movie cell (section header)
        let nib2 = UINib(nibName: IBConstants.Cells.movieHeader, bundle: nil)
        tableView.register(nib2, forHeaderFooterViewReuseIdentifier: IBConstants.Cells.movieHeader)
    }
    
    private func updateUI()
    {
        if place != nil {
            
            // Set navigation bar title
            navigationItem.title = IBConstants.LocalizedStrings.showingsTitle
            
            // Display Place details
            theaterTitle.text = place.title
            theaterPhone.text = place.phone
            theaterAddress.text = place.address
            theaterTimetable.text = place.timetable

            // Change predicate
            resultsController?.fetchRequest.predicate = NSPredicate(format: "place == %@ AND dateTime >= %@", place, modelController.filter.since as NSDate)
            do {
                try resultsController?.performFetch()
            } catch {
                fatalError("[!] Failed to fetch FetchedResultsController: \(error)")
            }
            
            
            tableView.reloadData()
        }
    }
    
    private func updateTableViewHeaderViewHeight()
    {
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        
        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
            tableView.tableHeaderView = headerView
            tableView.layoutIfNeeded()
        }
    
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
    
    
    // MARK: - MovieTableViewHeaderDelegate
    // ------------------------------------
    func headerDidSelect(sender: UITableViewHeaderFooterView)
    {
        BKLog("Got it: \(sender.tag)", prefix: "!")
        performSegue(withIdentifier: IBConstants.Segues.movieDetails, sender: sender)
    }
    
    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(modelController != nil, "'modelController' has not been set.")
        assert(place != nil, "'place' has not been set.")
        
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
            let destinationVC = segue.destination as? PlaceDetailsTableViewController{
            destinationVC.place = place
            destinationVC.modelController = self.modelController
        }else
        if segue.identifier == IBConstants.Segues.movieDetails,
            let destinationVC = segue.destination as? MovieDetailsTableViewController,
            let headerView = sender as? MovieTableViewHeader {
                let selectedSection = headerView.tag
                if let object = resultsController?.sections?[selectedSection].objects?.first as? MovieShowing,
                    let movie = object.movie{
                    destinationVC.movie = movie
                    destinationVC.modelController = self.modelController
            }
        }
    
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        updateTableViewHeaderViewHeight()
    }
    
    
    
    // MARK: - Table view data source
    // ------------------------------
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        guard let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: IBConstants.Cells.movieHeader) as? MovieTableViewHeader else {
            fatalError("Unexpected header cell type at section \(section)")
        }
        
        if let object = resultsController?.sections?[section].objects?.first as? MovieShowing, let movie = object.movie {
            headerCell.configure(for: movie)
            headerCell.delegate = self
            headerCell.tag = section
            
            // Load poster
            if movie.poster_thumbnail == nil {
                //BKLog("Need to load image for object: \(object.objectID) at \(indexPath)", prefix: "0")
                loadImage(for: movie)
            }
            
        }
        
        return headerCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return MovieTableViewCell.defaultHeight
    }
    
    
      

}
