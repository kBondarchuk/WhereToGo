//
//  PlacesTableViewController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData

final class PlacesTableViewController: FetchedTableViewController<Place, UITableViewCell>, ModelControllerDependent {

	// MARK: - Public Preperties
	// -------------------------

	var modelController: ModelController!


	// MARK: - Actions
	// ---------------

	@IBAction func actionRefresh(_ sender: Any)
	{
		//BKLog()
		loadData()
	}


	// MARK: - Private Properties
	// --------------------------

	private var didRefresh: Bool = false


	// MARK: - Private Methods
	// -----------------------

	func initializeFetchedResultsController()
	{
		let request: NSFetchRequest<Place> = Place.fetchRequest()
		let sort = NSSortDescriptor(key: "id", ascending: true)
		request.sortDescriptors = [sort]

		resultsController = NSFetchedResultsController<Place>(fetchRequest: request,
		                                                      managedObjectContext: modelController.viewContext,
		                                                      sectionNameKeyPath: nil,
		                                                      cacheName: nil)

		resultsController?.delegate = self
	}

	func performFetch(with city: Location?)
	{
		guard city != nil else {
			return
		}

		let lastSyncTime = Place.getLastSyncTimestamp(in: resultsController!.managedObjectContext) ?? 0

		BKLog("Place timestamp: \(lastSyncTime)")

		//resultsController?.fetchRequest.predicate = NSPredicate(format: "location == %@ AND ", city!)
		resultsController?.fetchRequest.predicate =  NSPredicate(format: "location == %@ AND %K == %la", city!, #keyPath(Place.timeStamp), lastSyncTime)

		do {
			try resultsController?.performFetch()
		} catch {
			fatalError("[!] Failed to initialize FetchedResultsController: \(error)")
		}

		BKLog("Fetched objects: \(resultsController?.fetchedObjects?.count ?? 0)")
	}

	override func configureCell(_ cell: UITableViewCell, for object: Place)
	{
		cell.textLabel?.text = object.title
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
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.contentInset.top = 44
		if #available(iOS 11, *) {
		} else {
			self.tableView.contentInset.bottom = 50
		}
	}

	private func addLocationObserver()
	{
		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: IBConstants.locationDidChangeNotification),
		                                       object: nil, queue: nil) { notification in self.locationDidChange() }
	}

	private func loadData()
	{

		if let city = modelController.filter.currentCity?.slug {
			BKLog("UI: Start Loading Places...")

			// Load Data
			modelController.requestPlaces(city: city) { isOK, errorString in
				DispatchQueue.main.async {
					self.refreshControl?.endRefreshing()

					if isOK {
						// UI
						BKLog("UI: Loading Places completed successfully!")
						self.updateUI()
					}else {
						// Error
						showAlert(with: self, title: IBConstants.LocalizedStrings.errorAlertTitle, message: errorString)
					}
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


		// TableView configuration
		configureUI()

		// Init Cell
		self.cellReuseIdentifier = IBConstants.Cells.place

		// Init CoreData
		self.initializeFetchedResultsController()

		// Fetch Core Data
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
		if segue.identifier == IBConstants.Segues.placeDetails,
			let destinationVC = segue.destination as? PlaceDetailsTableViewController,
			let selectedRow = tableView.indexPathForSelectedRow {

			destinationVC.place = resultsController?.object(at: selectedRow )
			destinationVC.modelController = self.modelController


		}
	}



}
