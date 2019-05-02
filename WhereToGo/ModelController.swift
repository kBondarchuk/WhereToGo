//
//  ModelController.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 25.11.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import UIKit
import CoreData


protocol ModelControllerDependent: class {
    var modelController: ModelController! {get set}
}


final class ModelController {
   
    struct Filter {
        var currentCity: Location?
        var since: Date
        var until: Date
        
        init(currentCity: Location?, since: Date)
        {
            self.currentCity = currentCity
            self.since = since
            self.until = Calendar.current.date(byAdding: .day, value: 2, to: since) ?? since
            
        }
        
    }
    
    
    
    // MARK: - Public Properties
    // -------------------------
    
    var filter: Filter {
        didSet {
            BKLog("Filter changed to City: <\(self.filter.currentCity?.name ?? "nil")>, Since: \(self.filter.since.debugDescription), Until: \(self.filter.until.debugDescription)")
            locationDidChange()
            postNotification(rawValue: IBConstants.locationDidChangeNotification, object: nil)
        }
    }
    
    var viewContext: NSManagedObjectContext {
        return DataController.persistentContainer.viewContext
    }
    
    var name: String {
        return String("\(self.self) City: <\(self.filter.currentCity?.name ?? "nil")>, Since: \(self.filter.since.debugDescription), Until: \(self.filter.until.debugDescription)")
    }
    
    
    // MARK: - Private Properties
    // --------------------------
    
    private var networkAPI: KGAPI
    
    private lazy var privateContext: NSManagedObjectContext = {
        BKLog("Creating background CoreData context.", prefix: "*")
        let newBackgroundContext = DataController.persistentContainer.newBackgroundContext()
        newBackgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.overwriteMergePolicyType)
        return newBackgroundContext
    }()

    
    // Init
    // ----
    
    init(with networkAPI: KGAPI, filter: Filter = Filter(currentCity: nil, since: Date()) )
    {
        self.networkAPI = networkAPI
        self.filter = filter
        
        // Load
        if let locationID = Location.loadDefaultObjectID(),
            let location = try? Location.findWith(objectID: locationID) {

            self.filter.currentCity = location
        }
        
        
        DataController.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        DataController.persistentContainer.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.overwriteMergePolicyType)
    }

    
    // MARK: - Private Methods
    // -----------------------
    // UI
    
    private func postNotification(rawValue: String, object: Any?)
    {
        let notification = Notification(name: Notification.Name(rawValue: rawValue), object: object)
        NotificationCenter.default.post(notification)
    }
    
    private func locationDidChange()
    {
        networkAPI.cancelAllTasks()
        // Saving
        self.filter.currentCity?.saveToDefaults()
    }
    
    fileprivate func savePrivateContext()
    {
        guard self.privateContext.hasChanges else {
            BKLog("!!!   Nothing to save in context!")
            return
        }
        
        // Try to save context
        do {
            BKLog("!!!   Background context saving...")
            try self.privateContext.save()
        } catch {
            fatalError("!!!   Failure to save context: \(error)")
        }
    }
    
    private func createObjectsInPrivateContext(_ items: [JsonObject], _ itemBlock: (JsonObject, NSManagedObjectContext)->Void)
    {
        self.privateContext.performAndWait() {
            
            BKLog("!!!   2.Thread [performBackgroundTask]: \(Thread.current)")
            
            // Create CoreData Records in private context
            for item in items {
                itemBlock(item, self.privateContext)
            }

        }
    }
    
    
    // MARK: - Public Methods
    // ----------------------
    
    func deleteOutdated()
    {
        let syncTime: TimeInterval = Date.timeIntervalSinceReferenceDate - IBConstants.timeToLive
        
        Place.deleteOutdated(in: self.viewContext, syncTime: syncTime)
        Movie.deleteOutdated(in: self.viewContext, syncTime: syncTime)
        MovieShowing.deleteOutdated(in: self.viewContext, syncTime: syncTime)
        
        DataController.saveContext()
    }
    
    func requestMovieShowings(city: String, placeId: Int, since: Date, until: Date, syncTime: TimeInterval? = nil, nextPage: String? = nil, _ completion: @escaping (Bool, String) -> Void = {_, _ in })
    {
        // Sync TimeStamp
        let syncTimeStamp: TimeInterval = syncTime != nil ? syncTime! : Date.timeIntervalSinceReferenceDate
        
        // Request
        networkAPI.requestMovieShowings(city: city, placeId: placeId, since: since, until: until, nextPage: nextPage) { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "!")
                // Tell UI that we got an error
                completion(false, errorString)
                return
            }
            
            if case let .success(parsedJson) = result {
                //BKLog(parsedJson, prefix: "*")
                
                self.networkAPI.parsePagedResult(parsedJson,
                    // To create Objects:
                    resultItemsBlock: {items in
                        self.createObjectsInPrivateContext(items, {item, bgContext in _ = MovieShowing.createFromJson(json: item, in: bgContext, syncTime: syncTimeStamp)})},
                    
                    // To continue fetching:
                    nextPageBlock: {urlString in self.requestMovieShowings(city: city, placeId: placeId, since: since, until: until, syncTime: syncTimeStamp, nextPage: urlString, completion)},
                    
                    // After finish fetching run:
                    didFinishParsingBlock: {
                        self.savePrivateContext()
                        // Tell UI that were done with loading
                        completion(true, "")
                        
                })
                
                
                
            }
        }
    }
    
    func requestShowingsOfMovie(city: String, movieId: Int, since: Date, until: Date, syncTime: TimeInterval? = nil, nextPage: String? = nil, _ completion: @escaping (Bool, String) -> Void = {_,_  in })
    {
        // Sync TimeStamp
        let syncTimeStamp = syncTime != nil ? syncTime! : Date.timeIntervalSinceReferenceDate
        
        // Request
        networkAPI.requestShowingsOfMovie(city: city, movieId: movieId, since: since, until: until, nextPage: nextPage) { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "!")
                // Tell UI that we got an error
                completion(false, errorString)
                return
            }
            
            if case let .success(parsedJson) = result {
                //BKLog(parsedJson, prefix: "*")
                
                self.networkAPI.parsePagedResult(parsedJson,
                                             
                    // To create Objects:
                    resultItemsBlock: {items in
                        self.createObjectsInPrivateContext(items, {item, bgContext in _ = MovieShowing.createFromJson(json: item, in: bgContext, syncTime: syncTimeStamp)})},
                    
                    // To continue fetching:
                    nextPageBlock: {urlString in self.requestShowingsOfMovie(city: city, movieId: movieId, since: since, until: until, syncTime: syncTimeStamp, nextPage: urlString, completion)},
                    
                    // After finish fetching run:
                    didFinishParsingBlock: {
                        self.savePrivateContext()
                        // Tell UI that were done with loading
                        completion(true, "")
                        
                })
            }
        }
    }
    
    func requestPlaces(city: String, nextPage: String? = nil, syncTime: TimeInterval? = nil, _ completion: @escaping (Bool, String) -> Void = {_,_  in })
    {
        // Sync TimeStamp
        let syncTimeStamp = syncTime != nil ? syncTime! : Date.timeIntervalSinceReferenceDate
        
        // Request
        networkAPI.requestPlaces(city: city, since: self.filter.since, until: self.filter.until, nextPage: nextPage) { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "!")
                // Tell UI that we got an error
                completion(false, errorString)
                return
            }
            
            if case let .success(parsedJson) = result {
                
                self.networkAPI.parsePagedResult(parsedJson,
                    // To create Objects:
                    resultItemsBlock: {items in
                        self.createObjectsInPrivateContext(items, {item, bgContext in _ = Place.createFromJson(json: item, in: bgContext, syncTime: syncTimeStamp)})},
                    
                    // To continue fetching:
                    nextPageBlock: {urlString in self.requestPlaces(city: city, nextPage: urlString, syncTime: syncTimeStamp, completion)},
                    
                    // After finish fetching run:
                    didFinishParsingBlock: {
                        self.savePrivateContext()
                        // Tell UI that we are done with loading
                        completion(true, "")
                        
                })
                
                
            }
        }
    }
    
    func requestMovies(city: String, placeId: Int?, nextPage: String? = nil, _ completion: @escaping (Bool, String) -> Void = {_, _ in })
    {
        // Sync TimeStamp
        let syncTimeStamp: TimeInterval = Date.timeIntervalSinceReferenceDate
        
        // Request
        networkAPI.requestMovies(city: city, since: self.filter.since, until: self.filter.until, placeId: placeId) { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "!")
                // Tell UI that we got an error
                completion(false, errorString)
                return
            }
            
            if case let .success(parsedJson) = result {
                //BKLog(parsedJson, prefix: "*")
                
                self.networkAPI.parsePagedResult(parsedJson,
                    // To create Objects:
                    resultItemsBlock: {items in
                        self.createObjectsInPrivateContext(items, {item, bgContext in _ = Movie.createFromJson(json: item, in: bgContext, syncTime: syncTimeStamp)})},
                    
                    // To continue fetching:
                    nextPageBlock: {_ in },
                    
                    // After finish fetching run:
                    didFinishParsingBlock: {
                        self.savePrivateContext();
                        // Tell UI that were done with loading
                        completion(true, "")
                        
                })

                
            }
        }
    }
    
    func requestLocations(_ completion: @escaping (Bool, String) -> Void = {_, _ in })
    {
        networkAPI.requestLocations { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "X")
                // Tell UI that we got an error
                completion(false, errorString)
                return
            }
            
            if case let .success(parsedJsonArray) = result {
                
                BKLog("!!!   1.Thread [parseResult]: \(Thread.current)")
                
                self.createObjectsInPrivateContext(parsedJsonArray, { (item, bgContext) in
                    _ = Location.createFromJson(json: item, in: bgContext)
                })
                
                self.savePrivateContext()
                
                // Tell UI that were done with loading
                completion(true, "")
                
               
            }
        }
    }

    //
    
    func requestEvents(city: String, since: Date, until: Date, nextPage: String? = nil)
    {
        networkAPI.requestEvents(city: city, since: since, until: until, nextPage: nextPage) { result in
            
            if case let .error(errorString) = result {
                BKLog(errorString, prefix: "!")
                return
            }
            
            if case let .success(parsedJson) = result {
                
                self.networkAPI.parsePagedResult(parsedJson,
                                                 // To create Objects:
                    resultItemsBlock: {items in for item in items { BKLog(item) }},
                    
                    // To continue fetching:
                    nextPageBlock: {urlString in self.requestEvents(city: city, since: since, until: until, nextPage: urlString)},
                    
                    // After finish fetching run:
                    didFinishParsingBlock: { })
                
                
                
            }
        }
    }


}
