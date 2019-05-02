//
//  IBConstants.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 19.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import Foundation
import UIKit

struct IBConstants {
    
    static let locationDidChangeNotification = "locationDidChangeNotification"
    
    static let timeToLive: Double = 60*60*24*3
    
    static let defaultTintColor: UIColor = UIColor(red: 0.0, green: 0.480, blue: 1.0, alpha: 1.0)
    
    struct Cells {
        static let location = "CityCell"
        static let placeCategory = "PlaceCategoryCell"
        static let eventCategory = "EventCategoryCell"
        static let place = "PlaceCell"
        static let movies = "MovieTableViewCell"
        static let movieShowing = "ShowingTableViewCell"
        static let fullText = "FullTextCell"
        static let dualText = "DualCell"
        static let button = "ButtonCell"
        static let movieHeader = "MovieTableViewHeader"
        static let prototypeHeader = "PrototypeHeaderCell"
        static let action = "ActionCell"
        static let images = "ImagesCell"
        static let imageCollection = "ImageCollectionCell"
        
    }
    
    
    struct Segues {
        static let placeDetails = "PlaceDetailsSegue"
        static let movieDetails = "MovieDetailsSegue"
        static let selectCity = "SelectCitySegue"
        //static let mapToPlaceDetails = "MapToPlaceDetailsSegue"
        static let mapToShowings = "MapToShowingsSegue"
        static let placeDetailsToShowingsSegue = "PlaceDetailsToShowingsSegue"
        static let whereToWatch = "MovieWhereToWatchSegue"
        static let showImage = "ShowImageSegue"
        static let showPosterImage = "ShowPosterImageSegue"
    }
    
    struct LocalizedStrings {
        static let writer = NSLocalizedString("Writer", comment: "Writer")
        static let stars = NSLocalizedString("Stars", comment: "Stars")
        static let runtime = NSLocalizedString("Runtime", comment: "Runtime")
        static let storyline = NSLocalizedString("Storyline", comment: "Storyline")
        
        static let address = NSLocalizedString("Address", comment: "Address")
        static let timeTable = NSLocalizedString("Time table", comment: "Time table")
        static let phone = NSLocalizedString("Phone number", comment: "Phone number")
        static let showings = NSLocalizedString("Screenings", comment: "Movie showings")
        static let description = NSLocalizedString("Description", comment: "Description")
        static let openSite = NSLocalizedString("Open Site", comment: "Open Site")
        
        // Showigs VC
        static let showingsTitle = NSLocalizedString("Screenings", comment: "Screenings in movie theatre")
        
        // WhereToWatchVC
        static let whereToWatchTitleFormat = NSLocalizedString("Movie in %@", comment: "Movie in city")
        
        // Network Error Alert
        static let errorAlertTitle = NSLocalizedString("Error", comment: "Network Error Alert Title")
    }
    
    
    
}
