//
//  MovieDetailsTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 05.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

final class MovieDetailsTableViewController: DetailsTableViewController, ModelControllerDependent {
   
    // MARK: - Public Preperties
    // -------------------------
    
    var movie: Movie!
    var modelController: ModelController!
    
    
    
    // MARK: - Private Methods
    // -----------------------
    
    private func openURL(urlString: String?)
    {
        guard urlString != nil else {
            return
        }
        if let url = URL(string: urlString!){
            UIApplication.shared.open(url, options: [:])
        }
        
    }
    
    private func configureRow(_ cell: UITableViewCell, title: String, text: String?, tintColor: UIColor? = nil)
    {
        if let label = cell.viewWithTag(2) as? UILabel {
            label.text = title
            
            // Tint Color
            if tintColor != nil {
                label.textColor = tintColor
            }
        }
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = text
        }
    }
    
    private func configureUI()
    {
        // Register Movie Cell
        let nib = UINib(nibName: IBConstants.Cells.movies, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: IBConstants.Cells.movies)
        
        // Construct table
        tableRows = []
        
        // Setup rows
        
        // Movie Title Cell
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.movies,
                                  configFunc: {cell in
                                    if let cell = cell as? MovieTableViewCell {cell.configure(for: self.movie)}},
                                  selectFunc: {BKLog("Tap"); self.performSegue(withIdentifier: IBConstants.Segues.showPosterImage, sender: self) }))
        
        // Writer
        if movie.writer != nil, movie?.writer != "" {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                      configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.writer, text: self.movie.writer)},
                                      selectFunc: {}))
        }
        
        if movie.stars != nil, movie?.stars != "" {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                      configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.stars, text: self.movie.stars)},
                                      selectFunc: {}))
        }
        
        // IMDB
        if movie.imdb_rating != 0.0 {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.dualText,
                                      configFunc: {cell in self.configureRow(cell, title: "IMDB", text: "\(self.movie.imdb_rating)", tintColor: IBConstants.defaultTintColor)},
                                      selectFunc: {self.openURL(urlString: self.movie.imdb_url); self.deselectRow()}))
        }
        
        if movie.running_time != 0 {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.dualText,
                                      configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.runtime,
                                                                             text: "\(self.movie.running_time/60):\(self.movie.running_time-(self.movie!.running_time/60*60))")},
                                      selectFunc: {}))
        }
        
        
        // Images
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.images, configFunc: {_ in}, selectFunc: {}))
        
        // Button
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.action, configFunc: {_ in}, selectFunc: {}))
        
        // Description
        if movie.filmdescription != nil {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                      configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.description, text: self.movie.filmdescription)},
                                      selectFunc: {}))
        }
    }
    
    fileprivate func updateUI()
    {
        navigationItem.title = movie.title
    }

    private func deselectRow()
    {
        if let selectedRow = tableView.indexPathForSelectedRow {
            BKLog(selectedRow)
            tableView.deselectRow(at: selectedRow , animated: true)
        }
    }
    
    
    // MARK: - UIViewController
    // ------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(modelController != nil, "modelController has not been set.")
        assert(movie != nil, "movie has not been set.")
        
        movie?.fetchedImages = [:]
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.whereToWatch,
            let destinationVC = segue.destination as? WhereToWatchFetchedViewController{
            
                destinationVC.movie = self.movie
                destinationVC.modelController = self.modelController
            
        }else
            if segue.identifier == IBConstants.Segues.showImage,
                let destinationVC = segue.destination as? KBImageViewController,
                let collectionView = sender as? UICollectionView,
                let indexPath = collectionView.indexPathsForSelectedItems?[0]{
                
                if let imageString = movie?.images?[indexPath.item],
                    let image = movie?.fetchedImages?[imageString] as? UIImage{
                    
                    // Setup Image VC
                    destinationVC.image = image
                    
                    // Calculate starting point
                    let cell = collectionView.cellForItem(at: indexPath)
                    //let point = cell!.superview!.convert(cell!.center, to: nil)
                    //let frame = cell!.frame
                    //print("Selected Cell Center -------: ", point, " frame: ", frame)
                    
                    // Setup Transitioning
                    destinationVC.transitioningDelegate = destinationVC.transition
                    destinationVC.transition.transitionSourceFrame = cell!.convert(cell!.bounds, to: nil)
            }
        }else
                if segue.identifier == IBConstants.Segues.showPosterImage,
                    let destinationVC = segue.destination as? KBImageViewController {
                    
                    BKLog()
                    
                    deselectRow()
                    // Setup Image VC
                    //destinationVC.image = UIImage(data: self.movie.poster_thumbnail!)
                    destinationVC.imageURL = URL(string: self.movie.poster_image_url ?? "")
                    
                    // Setup Transitioning
                    //destinationVC.transitioningDelegate = destinationVC.transition
                    //destinationVC.transition.transitionSourceFrame = cell!.convert(cell!.bounds, to: nil)
        }

    }

    

}
    
extension MovieDetailsTableViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    
    fileprivate func configureCell(cell: UICollectionViewCell, numberOfPhoto number: Int)
    {
        if let cell = cell as? ImageCollectionViewCell, movie != nil {
            cell.configure(for: movie!, photoNumber: number)
        }
        
    }
    
    
    
    // MARK: - UICollectionViewDataSource
    // --------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        BKLog("movie?.images?.count = \(movie?.images?.count ?? 0)", prefix: "*")
        return movie?.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        // 1
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IBConstants.Cells.imageCollection, for: indexPath)
        
        // Configure the cell
        configureCell(cell: cell, numberOfPhoto: indexPath.item)
        
        return cell
    }
    
    
    
    // MARK: - UICollectionViewDelegate
    // --------------------------------
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        BKLog("", prefix: "_")
        
        performSegue(withIdentifier: IBConstants.Segues.showImage, sender: collectionView)
    }

    
}
    
    
    


