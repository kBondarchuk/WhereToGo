//
//  PlaceDetailsTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit

final class PlaceDetailsTableViewController: DetailsTableViewController, ModelControllerDependent {
    
    // MARK: - Public Preperties
    // -------------------------
    
    var place: Place!
    var modelController: ModelController!
    
    
    // MARK: - Private Methods
    // -----------------------
    
    private func openURL(urlString: String?)
    {
        guard urlString != nil else {
            return
        }
        
        BKLog(urlString)
        
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
    
    fileprivate func configureUI()
    {
        // Construct table
        
        tableRows = []
        
        // Images
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.images, configFunc: {_ in}, selectFunc: {}))
        
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                  configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.address, text: self.place.address)},
                                  selectFunc: {}))
        
        if self.place.timetable != nil, self.place.timetable != "" {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                  configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.timeTable, text: self.place.timetable)},
                                  selectFunc: {}))
        }
        
        // Phone
        if self.place.phone != nil, self.place.phone != "" {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                  configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.phone, text: self.place.phone, tintColor: IBConstants.defaultTintColor)},
                                  selectFunc: {self.openURL(urlString: "tel:"+(self.place.phone?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "") ?? ""
                                    ) ); self.deselectRow()}))
        }
        
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.action,
                                  configFunc: {cell in self.configureRow(cell, title: "", text: IBConstants.LocalizedStrings.showings)},
                                  selectFunc: {self.performSegue(withIdentifier: IBConstants.Segues.placeDetailsToShowingsSegue, sender: self)}))
        
        if self.place.description2 != nil, self.place.description2 != "" {
        tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.fullText,
                                  configFunc: {cell in self.configureRow(cell, title: IBConstants.LocalizedStrings.description, text: self.place.description2)},
                                  selectFunc: {}))
        }
        
        if self.place.site_url != nil, self.place.site_url != "" {
            tableRows.append(TableRow(reuseIdentifier: IBConstants.Cells.button,
                                  configFunc: {cell in self.configureRow(cell, title: "", text: IBConstants.LocalizedStrings.openSite)},
                                  selectFunc: {self.openURL(urlString: self.place.site_url); self.deselectRow()}))
        }
        
    }
    
    fileprivate func updateUI()
    {
        navigationItem.title = place.title
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(modelController != nil, "ModelController did not set!")
        assert(place != nil, "'place' has not been set.")
        
        place.fetchedImages = [:]
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.showImage,
            let destinationVC = segue.destination as? KBImageViewController,
            let collectionView = sender as? UICollectionView,
            let indexPath = collectionView.indexPathsForSelectedItems?[0]{
            
            if let imageString = place.images?[indexPath.item],
                let image = place.fetchedImages?[imageString] as? UIImage{
                
                destinationVC.image = image
                
                // Setup Transition
                let cell = collectionView.cellForItem(at: indexPath)
                destinationVC.transitioningDelegate = destinationVC.transition
                destinationVC.transition.transitionSourceFrame = cell!.convert(cell!.bounds, to: nil)
            }
        }else
            if segue.identifier == IBConstants.Segues.placeDetailsToShowingsSegue,
                let destinationVC = segue.destination as? ShowingsFetchedViewController {
                
                    destinationVC.place = self.place
                    destinationVC.modelController = self.modelController
                }
    }
}


// For Images Collection View
extension PlaceDetailsTableViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func configure(cell: ImageCollectionViewCell, for place: Place, photoNumber number: Int)
    {
        
        //1
        guard let urlString = place.images?[number] else {
            return
        }
        
        //2
        if let image = place.fetchedImages?[urlString] as? UIImage {
            cell.configure(with: image)
            return
        }
        
        // Proceed download
        guard let url = URL(string: place.images?[number] ?? "") else {
            return
        }
            
        //BKLog(url)
        
        BKLog("Run download thread...", prefix: ">")
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let imageData = try? Data(contentsOf: url){
                // UI
                DispatchQueue.main.async {
                    BKLog(imageData.debugDescription)
                    if let image = UIImage(data: imageData) {
                        
                        // Set image
                        cell.configure(with: image)
                        
                        // Cache
                        place.fetchedImages?.setValue(image, forKey: urlString)
                    }
                    
                    
                }
                
            }
            
        }
    }
    
    fileprivate func configureCell(cell: UICollectionViewCell, numberOfPhoto number: Int)
    {
        if let cell = cell as? ImageCollectionViewCell {
            self.configure(cell: cell, for: place, photoNumber: number)
        }
        
    }
    
    
    // MARK: - UICollectionViewDataSource
    // --------------------------------
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        BKLog("place.images?.count = \(place.images?.count ?? 0)", prefix: "*")
        return place.images?.count ?? 0
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
