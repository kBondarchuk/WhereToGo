//
//  PlaceCategory+CoreDataClass.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 21.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//
//

import Foundation
import CoreData


public class PlaceCategory: NSManagedObject {
    
    static func createFromJson(json: JsonObject, in context: NSManagedObjectContext) -> PlaceCategory?
    {
        let slug = json[KGConstants.Keys.slug] as! String
        let name = json[KGConstants.Keys.name] as! String
        
        let object = try? self.createIfNeeded(slug: slug,
                                              name: name,
                                              in: context)
        
        return object
    }
    
    
    static func createWith(slug: String, name: String, in context: NSManagedObjectContext) -> PlaceCategory
    {
        let object = PlaceCategory(context: context)
        object.slug = slug
        object.name = name
        
        BKLog("Created: \(object)", prefix: "+")
        
        return object
    }
    
    
    
    static func createIfNeeded(slug: String, name: String, in context: NSManagedObjectContext) throws -> PlaceCategory
    {
        // Get Existing
        
        let request: NSFetchRequest<PlaceCategory> = PlaceCategory.fetchRequest()
        request.predicate = NSPredicate(format: "slug = %@", slug)
        
        do{
            let matches = try context.fetch(request)
            if matches.count>0 {
                assert(matches.count==1, "PlaceCategory —— database inconsistance")
                let object = matches[0]
                BKLog("Existing: \(object.slug ?? "n/a")")
                //photo.annotation = annotation
                return object
            }
            
        }catch{
            throw error
        }
        
        
        // Create New
        
        return self.createWith(slug: slug, name: name, in: context)
        
    }

}
