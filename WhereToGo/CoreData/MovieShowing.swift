//
//  MovieShowing+CoreDataClass.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 24.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//
//

import Foundation
import CoreData


public class MovieShowing: NSManagedObject {

    // Find Or Create
    static func findOrCreate(id: Int, in context: NSManagedObjectContext) -> MovieShowing
    {
        // Get Existing
        
        if let existingObject = self.findExisting(id: id, in: context){
            BKLog("Existing: <\(self.self)> \(existingObject.id)", prefix: "*")
            return existingObject
        }
        
        
        // Create New
        
        let newObject = MovieShowing(context: context)
        newObject.id = Int32(id)
        
        BKLog("Created: <\(self.self)> \(newObject.id)", prefix: "+")
        
        return newObject
    }
    
    // Find
    static func findExisting(id: Int, in context: NSManagedObjectContext) -> MovieShowing?
    {
        // Get Existing
        
        let request: NSFetchRequest<MovieShowing> = MovieShowing.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        do{
            let matches = try context.fetch(request)
            return matches.first
            
        }catch{
            fatalError(error.localizedDescription)
        }
        
    }

    // Sync Time Stamp
    static func getLastSyncTimestamp(in context: NSManagedObjectContext) -> Double?
    {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        request.entity = NSEntityDescription.entity(forEntityName: "MovieShowing", in: context)
        request.resultType = NSFetchRequestResultType.dictionaryResultType
        
        let keypathExpression = NSExpression(forKeyPath: "timeStamp")
        let maxExpression = NSExpression(forFunction: "max:", arguments: [keypathExpression])
        
        let key = "maxTimeStamp"
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = key
        expressionDescription.expression = maxExpression
        expressionDescription.expressionResultType = .doubleAttributeType
        
        request.propertiesToFetch = [expressionDescription]
        
        var maxTimestamp: Double? = nil
        
        do {
            
            if let result = try context.fetch(request) as? [[String: Double]], let dict = result.first {
                maxTimestamp = dict[key]
            }
            
        } catch {
            assertionFailure("Failed to fetch max <MovieShowing> timestamp with error = \(error)")
            return nil
        }
        
        return maxTimestamp
    }
    
    // Delete
    static func deleteOutdated(in context: NSManagedObjectContext, syncTime: TimeInterval)
    {
        // Get Existing
        let request: NSFetchRequest<MovieShowing> = MovieShowing.fetchRequest()
        request.predicate = NSPredicate(format: "%K < %la", #keyPath(MovieShowing.timeStamp), syncTime)
        
        do{
            let matches = try context.fetch(request)
            BKLog("Found <\(matches.count)> MovieShowings to delete. \(syncTime)")
            
            _ = matches.map({context.delete($0)})
            
        }catch{
            fatalError(error.localizedDescription)
        }
        
    }
    
}

extension MovieShowing {
    
    class func createFromJson(json: JsonObject, in context: NSManagedObjectContext, syncTime: TimeInterval) -> MovieShowing?
    {
        
        guard let id = json[KGConstants.Keys.id] as? Int else {
            return nil
        }
        
        
//        guard let placeId = json["place"]?["id"] as? Int, let place = Place.findExisting(id: placeId, in: context) else {
//                BKLog("Can't find existing Place!", prefix: "X")
//                return nil
//        }
        
        guard let placeJson = json["place"] as? JsonObject, let placeId = placeJson["id"] as? Int else {
                BKLog("Can't parse Place!", prefix: "X")
                return nil
        }

        
        
        // Try to Find Place
        var existingPlace: Place? = nil
        
        existingPlace = Place.findExisting(id: placeId, in: context)
            
        if existingPlace == nil {
            // or Create Place
            guard let newPlace = Place.createFromJson(json: placeJson, in: context, syncTime: 0) else { // FIXME: syncTime: 0
                BKLog("Can't create Place!", prefix: "X")
                return nil
            }
            
            existingPlace = newPlace
        }
        
        
        
        // Find Movie
        guard let movieId = json["movie"]?["id"] as? Int, let movie = Movie.findExisting(id: movieId, in: context) else {
            BKLog("Can't find existing Movie!", prefix: "X")
            return nil
        }
        
        
        
        // Create Object
        let object = self.findOrCreate(id: id, in: context)
        
        object.timeStamp = syncTime
        
        object.place = existingPlace!
        object.movie = movie
        
        if let time = json["datetime"] as? Double {
            object.dateTime = Date(timeIntervalSince1970: time)
        }
        
        object.price           = json[KGConstants.Keys.price] as? String
        
        object.three_d         = json["three_d"] as? Bool ?? false
        object.imax            = json["imax"] as? Bool ?? false
        object.four_dx         = json["four_dx"] as? Bool ?? false
        object.original_language = json["original_language"] as? Bool ?? false
        
        
        return object
    }

    
}
