//
//  MovieShowingsDay.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 08.01.18.
//  Copyright © 2018 Konstantin Bondarchuk. All rights reserved.
//

import Foundation
import CoreData


public class MovieShowingsDay: NSManagedObject {
    
    // Find Or Create
    static func findOrCreate(place: Place, movie: Movie, in context: NSManagedObjectContext) -> MovieShowingsDay
    {
        // Get Existing
        
        if let existingObject = self.findExisting(place: place, movie: movie, in: context){
            BKLog("Existing: <\(self.self)>", prefix: "*")
            return existingObject
        }
        
        
        // Create New
        
        let newObject = MovieShowingsDay(context: context)
        newObject.movie = movie
        newObject.place = place
        
        BKLog("Created: <\(self.self)>", prefix: "+")
        
        return newObject
    }
    
    // Find
    static func findExisting(place: Place, movie: Movie, in context: NSManagedObjectContext) -> MovieShowingsDay?
    {
        // Get Existing
        
        let request: NSFetchRequest<MovieShowingsDay> = MovieShowingsDay.fetchRequest()
        request.predicate = NSPredicate(format: "place == %@ AND movie == %@", place, movie)
        
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
        request.entity = NSEntityDescription.entity(forEntityName: "MovieShowingsDay", in: context)
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
            assertionFailure("Failed to fetch max <MovieShowingsDay> timestamp with error = \(error)")
            return nil
        }
        
        return maxTimestamp
    }
    
}

//extension MovieShowingsDay {
//
//    class func createFromJson(json: JsonObject, in context: NSManagedObjectContext, syncTime: TimeInterval) -> MovieShowingsDay?
//    {
//
//        // Parse Place
//        guard let placeJson = json["place"] as? JsonObject, let placeId = placeJson["id"] as? Int else {
//            BKLog("Can't parse Place!", prefix: "X")
//            return nil
//        }
//
//        // Try to Find Place in DB
//        var existingPlace: Place? = nil
//
//        existingPlace = Place.findExisting(id: placeId, in: context)
//
//        if existingPlace == nil {
//            // or Create Place
//            guard let newPlace = Place.createFromJson(json: placeJson, in: context, syncTime: 0) else { // FIXME: syncTime: 0
//                BKLog("Can't create Place!", prefix: "X")
//                return nil
//            }
//
//            existingPlace = newPlace
//        }
//
//
//
//        // Find Movie
//        guard let movieId = json["movie"]?["id"] as? Int, let movie = Movie.findExisting(id: movieId, in: context) else {
//            BKLog("Can't find existing Movie!", prefix: "X")
//            return nil
//        }
//
//
//
//        // Create Object
//        let object = self.findOrCreate(place: existingPlace!, movie: movie, in: context)
//
//        object.timeStamp = syncTime
//
//
//        if let time = json["datetime"] as? Double {
//            object.dateTime = Date(timeIntervalSince1970: time)
//        }
//
//        object.price           = json[KGConstants.Keys.price] as? String
//
//        object.three_d         = json["three_d"] as? Bool ?? false
//        object.imax            = json["imax"] as? Bool ?? false
//        object.four_dx         = json["four_dx"] as? Bool ?? false
//        object.original_language = json["original_language"] as? Bool ?? false
//
//
//        return object
//    }
//
//
//}

