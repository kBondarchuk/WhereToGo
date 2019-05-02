//
//  Place+CoreDataClass.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//
//

import Foundation
import CoreData


public class Place: NSManagedObject {

    // Find Or Create
    static func findOrCreate(id: Int, in context: NSManagedObjectContext) -> Place
    {
        // Get Existing
        
        if let existingObject = self.findExisting(id: id, in: context){
            BKLog("Existing: <\(self.self)> \(existingObject.id)", prefix: "*")
            return existingObject
        }
        
        
        // Create New
        
        let newObject = Place(context: context)
        newObject.id = Int32(id)
        
        BKLog("Created: <\(self.self)> \(newObject.id)", prefix: "+")
        
        return newObject
    }
    
    // Find
    static func findExisting(id: Int, in context: NSManagedObjectContext) -> Place?
    {
        // Get Existing
        
        let request: NSFetchRequest<Place> = Place.fetchRequest()
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
        request.entity = NSEntityDescription.entity(forEntityName: "Place", in: context)
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
            assertionFailure("Failed to fetch max <Place> timestamp with error = \(error)")
            return nil
        }
        
        return maxTimestamp
    }
    
    // Delete
    static func deleteOutdated(in context: NSManagedObjectContext, syncTime: TimeInterval)
    {
        // Get Existing
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        request.predicate = NSPredicate(format: "%K < %la", #keyPath(Place.timeStamp), syncTime)
        
        do{
            let matches = try context.fetch(request)
            BKLog("Found <\(matches.count)> places to delete. \(syncTime)")

            _ = matches.map({context.delete($0)})
            
        }catch{
            fatalError(error.localizedDescription)
        }
        
    }
    
}

extension Place {
    
    static func createFromJson(json: JsonObject, in context: NSManagedObjectContext, syncTime: TimeInterval) -> Place?
    {
        
        guard let id = json[KGConstants.Keys.id] as? Int else {
            return nil
        }
        
        
        // Find City
        
        guard let city = json[KGConstants.Keys.location] as? String,
            let cityObject = Location.findExisting(slug: city, in: context) else {
                return nil
        }
        
        
        // Create Object
        
        let object = self.findOrCreate(id: id, in: context)
        
        object.timeStamp = syncTime
        
        object.location        = cityObject
        object.title           = (json[KGConstants.Keys.title] as? String)?.firstCharacterUpperCase()
        object.latitude        = json[KGConstants.Keys.coords]?[KGConstants.Keys.latitude] as? Double ?? 0.0
        object.longitude       = json[KGConstants.Keys.coords]?[KGConstants.Keys.longitude] as? Double ?? 0.0
        object.slug            = json[KGConstants.Keys.slug] as? String
        object.address         = json[KGConstants.Keys.address] as? String
        object.phone           = json[KGConstants.Keys.phone] as? String
        object.site_url        = json[KGConstants.Keys.siteUrl] as? String
        object.subway          = json[KGConstants.Keys.subway] as? String
        object.description2    = (json[KGConstants.Keys.description] as? String)?
            .replacingOccurrences(of: "\n", with: "", options: NSString.CompareOptions.literal, range:nil)
        object.timetable       = json[KGConstants.Keys.timeTable] as? String
        object.favorites_count = json[KGConstants.Keys.favoritesCount] as? Int16 ?? 0
        object.comments_count  = json[KGConstants.Keys.comments_count] as? Int16 ?? 0
        
        
        // Images
        if let imageObjects = json["images"] as? [JsonObject]{
            let imageStrings = imageObjects.flatMap({imageObject in imageObject["image"] as? String})
            object.images = imageStrings
            //BKLog("Images: \(object?.images)", prefix: "!")
        }
        
        
        return object
    }
    
}

