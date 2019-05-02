//
//  KGConstants.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 16.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import Foundation

struct KGConstants {
    
    static let baseURL = "https://kudago.com/public-api/v1.3/"
    
    static let pageSize = 100
    
    // Language
    struct Language {
        static let english = "en"
        static let russian = "en"
    }
    
    // Request Methods
    struct Methods {
        static let placeCategoriesArray = "place-categories"
        static let eventCategoriesArray = "event-categories"
        static let locations = "locations"
        static let search = "search"
        static let events = "events"
        static let eventsOfTheDay = "events-of-the-day"
        static let lists = "lists"
        static let places = "places"
        static let movies = "movies"
        static let movieShowings = "movie-showings"
        static let agents = "agents"
        static let agentRoles = "agent-roles"
    }
    
    // Fields
    struct Keys {
        static let slug = "slug"
        static let name = "name"
        static let timezone = "timezone"
        static let language = "language"
        static let coords = "coords"
        static let latitude = "lat"
        static let longitude = "lon"
        static let title = "title"
        static let id = "id"
        static let location = "location"
        static let siteUrl = "foreign_url"
        static let address = "address"
        static let timeTable = "timetable"
        static let phone = "phone"
        static let images = "images"
        static let description = "description"
        static let subway = "subway"
        static let favoritesCount = "favorites_count"
        static let comments_count = "comments_count"
        static let categories = "categories"
        static let results = "results"
        static let count = "count"
        static let price = "price"
        static let nextPage = "next"
        static let previousPage = "previous"
        
    }
    
}
