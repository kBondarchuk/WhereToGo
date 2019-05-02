//
//  Movie+CoreDataClass.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 22.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//
//

import Foundation
import CoreData


public class Movie: NSManagedObject {
    
    // Find Or Create
    static func findOrCreate(id: Int, in context: NSManagedObjectContext) -> Movie
    {
        // Get Existing
        
        if let existingObject = self.findExisting(id: id, in: context){
            BKLog("Existing: <\(self.self)> \(existingObject.id)", prefix: "*")
            return existingObject
        }
        
        
        // Create New
        
        let newObject = Movie(context: context)
        newObject.id = Int32(id)
        
        BKLog("Created: <\(self.self)> \(newObject.id)", prefix: "+")
        
        return newObject
    }
    
    // Find
    static func findExisting(id: Int, in context: NSManagedObjectContext) -> Movie?
    {
        // Get Existing
        
        let request: NSFetchRequest<Movie> = Movie.fetchRequest()
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
        request.entity = NSEntityDescription.entity(forEntityName: "Movie", in: context)
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
            assertionFailure("Failed to fetch max <Movie> timestamp with error = \(error)")
            return nil
        }
        
        return maxTimestamp
    }
    
    // Delete
    static func deleteOutdated(in context: NSManagedObjectContext, syncTime: TimeInterval)
    {
        // Get Existing
        let request: NSFetchRequest<Movie> = Movie.fetchRequest()
        request.predicate = NSPredicate(format: "%K < %la", #keyPath(Movie.timeStamp), syncTime)
        
        do{
            let matches = try context.fetch(request)
            BKLog("Found <\(matches.count)> movies to delete. \(syncTime)")
            
            _ = matches.map({context.delete($0)})
            
        }catch{
            fatalError(error.localizedDescription)
        }
        
    }

    
}

// MARK: - Init with JSON

extension Movie {
    
    static func createFromJson(json: JsonObject, in context: NSManagedObjectContext, syncTime: TimeInterval) -> Movie?
    {
        
        guard let id = json[KGConstants.Keys.id] as? Int else {
            return nil
        }
        
        
        // Create Object
        
        let object = self.findOrCreate(id: id, in: context)
        
        object.timeStamp = syncTime
        
        object.title           = json[KGConstants.Keys.title] as? String
        object.filmdescription = json["body_text"] as? String
        object.original_title  = json["original_title"] as? String
        object.running_time    = json["running_time"] as? Int16 ?? 0
        object.age_restriction = json["age_restriction"] as? String
        object.url             = json["url"] as? String
        object.country         = json["country"] as? String
        object.stars           = json["stars"] as? String
        object.director        = json["director"] as? String
        object.writer          = json["writer"] as? String
        object.imdb_rating     = json["imdb_rating"] as? Double ?? 0.0
        object.imdb_url        = json["imdb_url"] as? String
        object.year            = json["year"] as? Int16 ?? 0
        
        // Poster URLs
        object.poster_image_url = json["poster"]?["image"] as? String
        
        // Poster thumbnails
        if let urls = json["poster"]?["thumbnails"] as? JsonObject{
            object.poster_thumbnails_url = urls["144x96"] as? String
        }
        
        // Genres
        
        if let genres = json["genres"] as? [JsonObject]{
            let ganresStrings = genres.flatMap({genre in (genre["name"] as? String)?.capitalized})
            object.genres = ganresStrings.joined(separator: ", ")
            //BKLog("Genres: \(object?.genres)")
        }
        
        // Images
        
        if let imageObjects = json["images"] as? [JsonObject]{
            let imageStrings = imageObjects.flatMap({imageObject in imageObject["image"] as? String})
            object.images = imageStrings
            //BKLog("Images: \(object?.images)", prefix: "!")
        }
        
        
        return object
    }

    
}
