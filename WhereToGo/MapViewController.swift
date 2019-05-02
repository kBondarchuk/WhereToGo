//
//  MapViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 22.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData
import MapKit

final class MapViewController: UIViewController, ModelControllerDependent {

    typealias ObjectType = Place

    // MARK: - Public Preperties
    // -------------------------
    
    var modelController: ModelController!
    
    
    // MARK: - Outlets
    // ---------------
    
    @IBOutlet weak var mapView: MKMapView!
    

    
    // MARK: - Private Properties
    // --------------------------
    
    fileprivate var resultsController: NSFetchedResultsController<ObjectType>!
    private var didRefresh: Bool = false
    
    
    // MARK: - Private Methods
    // -----------------------

    func initializeFetchedResultsController()
    {
        let request:   NSFetchRequest<ObjectType> = ObjectType.fetchRequest()
        let sort = NSSortDescriptor(key: "title", ascending: true)
        //let modelSort = NSSortDescriptor(key: "model", ascending: true)
        request.sortDescriptors = [sort]
        
        let moc = DataController.persistentContainer.viewContext
        
        resultsController = NSFetchedResultsController<ObjectType>(fetchRequest: request,
                                                                   managedObjectContext: moc,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        
        resultsController.delegate = self

    }
    
    private func performFetch(with city: Location?)
    {
        guard city != nil else {
            return
        }
        
        // Change predicate
        //FIXME: resultsController?.fetchRequest.predicate = NSPredicate(format: "location == %@ AND movieShowings.@count > 0", city!)
        
        resultsController?.fetchRequest.predicate = NSPredicate(format: "location == %@", city!)
        
        do {
            try resultsController?.performFetch()
        } catch {
            fatalError("[!] Failed to initialize FetchedResultsController: \(error)")
        }
        
        BKLog("Fetched objects: \(resultsController.fetchedObjects?.count ?? 0)")
    }
    
    private func updateUI()
    {
        if let city = modelController.filter.currentCity {
            
            // Set predicate
            self.performFetch(with: city)
            reloadAnnotations()

            
            // Change Visible Region
            mapView.setRegion(MKCoordinateRegionMake(CLLocationCoordinate2DMake(city.latitude, city.longitude), MKCoordinateSpanMake(0.25, 0.25)), animated: true)
        }
    }
    
    private func addLocationObserver()
    {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: IBConstants.locationDidChangeNotification),
                                               object: nil, queue: nil) { notification in self.updateUI() }
        
    }
    
    private func reloadAnnotations()
    {
        // Remove Annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add all annotations
        placeAllAnnotations(annotations: resultsController.fetchedObjects)
        
    }
    
    private func placeAllAnnotations(annotations: [ObjectType]?)
    {
        //BKLog("Objects count: \(resultsController.fetchedObjects?.count ?? 0)")
        
        guard annotations != nil else {
            return
        }
        
        mapView.addAnnotations(annotations!)
        
    }
    
    fileprivate func placeAnnotation(_ annotation: ObjectType)
    {
        //BKLog(annotation.title)
        
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func removeAnnotation(_ annotation: ObjectType)
    {
        //BKLog(annotation.title)
        
        mapView.removeAnnotation(annotation)
    }

    
    
    // MARK: - UIViewController
    // ------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
      
        // Init CoreData
        initializeFetchedResultsController()
        
        // Observe Location Change
        addLocationObserver()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !didRefresh {
            // Fetch Core Data
            updateUI()
            didRefresh = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == IBConstants.Segues.placeDetails,
            let destinationVC = segue.destination as? PlaceDetailsTableViewController,
            let place = sender as? ObjectType {
                destinationVC.place = place
                destinationVC.modelController = self.modelController
        }else
        
        if segue.identifier == IBConstants.Segues.mapToShowings,
            let destinationVC = segue.destination as? ShowingsFetchedViewController,
            let place = sender as? ObjectType {
                destinationVC.place = place
                destinationVC.modelController = self.modelController
        }
        
    }
    
    
    
}



// MARK: - MKMapViewDelegate
// -------------------------

extension MapViewController: MKMapViewDelegate
{
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        //UIShared.printDebug(#function, "reuseID: \(view.reuseIdentifier ?? "n/a") |  Annotation:, \(String(describing: view.annotation?.title ?? "no annotation")) ")
        
        if view.rightCalloutAccessoryView == nil {
            BKLog("Adding an (i)")
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        }
        
//        if let view = view as? MKPinAnnotationView {
//            view.pinTintColor = UIColor.green
//
//            // 🎦 🎥
//        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let place = view.annotation as? ObjectType{
                performSegue(withIdentifier: IBConstants.Segues.placeDetails, sender: place)
            }
        }
    }
    
}




// MARK: - NSFetchedResultsController
// ----------------------------------

extension MapViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: NSFetchedResultsControllerDelegate
    // ----------------------------------------
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        BKLog("controller controllerWillChangeContent", prefix: "{", file: nil)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        BKLog("controller controllerDidChangeContent", prefix: "}", file: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        BKLog(type.rawValue, prefix: "!", file: nil)
        
        switch type {
        case .insert:
            BKLog("insert section", prefix: "+")
            
        case .delete:
            BKLog("delete section", prefix: "-")
            
        default:
            break
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            BKLog("insert object", prefix: "+", function: "")
            if let object = anObject as? ObjectType{
                placeAnnotation(object)
            }
            
        case .delete:
            BKLog("delete object", prefix: "-", function: "")
            if let object = anObject as? ObjectType{
                removeAnnotation(object)
            }
            
        case .update:
            BKLog("update object", prefix: "*", function: "")
            
        case .move:
            BKLog("move object", prefix: ">", function: "")
        }
        
        
        
    }
}
