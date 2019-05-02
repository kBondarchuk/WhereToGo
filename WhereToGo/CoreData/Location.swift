//
//  Location+CoreDataClass.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 18.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//
//

import Foundation
import CoreData


public class Location: NSManagedObject {

    // Find Or Create
    static func findOrCreate(slug: String, in context: NSManagedObjectContext) -> Location
    {
        // Get Existing
        
        if let existingObject = self.findExisting(slug: slug, in: context){
            BKLog("Existing: <\(self.self)> \(existingObject.slug ?? "n/a")", prefix: "*")
            return existingObject
        }
        
        
        // Create New
        
        let newObject = Location(context: context)
        newObject.slug = slug
        
        BKLog("Created: <\(self.self)> \(newObject.slug ?? "n/a")", prefix: "+")
        
        return newObject
    }
    
    // Find
    static func findExisting(slug: String, in context: NSManagedObjectContext) -> Location?
    {
        // Get Existing
        
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        request.predicate = NSPredicate(format: "slug = %@", slug)
        
        do{
            let matches = try context.fetch(request)
            return matches.first
            
        }catch{
            fatalError(error.localizedDescription)
        }
        
    }
    

}

extension Location {
    
    static func createFromJson(json: JsonObject, in context: NSManagedObjectContext) -> Location?
    {
        guard let slug = json[KGConstants.Keys.slug] as? String else {
            return nil
        }
        
        // Create Object
        
        let city = self.findOrCreate(slug: slug, in: context)
        
        city.name       = json[KGConstants.Keys.name] as? String
        city.timezone   = json[KGConstants.Keys.timezone] as? String
        city.language   = json[KGConstants.Keys.language] as? String
        city.latitude   = json[KGConstants.Keys.coords]?[KGConstants.Keys.latitude] as? Double ?? 0.0
        city.longitude  = json[KGConstants.Keys.coords]?[KGConstants.Keys.longitude] as? Double ?? 0.0
        
        return city
    }
    
}



// Saving / Loding
extension Location {
    
    func saveToDefaults()
    {
        let defaults = UserDefaults.standard
        
        defaults.set(self.objectID.uriRepresentation(), forKey: "selectedLocation")
        defaults.synchronize()
    }
    
    class func loadDefaultObjectID() -> NSManagedObjectID?
    {
        let defaults = UserDefaults.standard
        
        if let uri = defaults.url(forKey: "selectedLocation"){
            return DataController.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri)
        }else{
            return nil
        }
    }
    
    class func findWith(objectID: NSManagedObjectID) throws -> Location?
    {
        // Get Existing
        
        // 1
        let managedContext = DataController.persistentContainer.viewContext
        
        // 2
        do{
            let match = try managedContext.existingObject(with: objectID)
            
            return match as? Location
        }catch{
            throw error
        }
        
    }
    
}


