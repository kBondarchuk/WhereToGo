//
//  KGAPI.swift
//  WhereToGo
//
//  Created by Konstantin Bondarchuk on 17.10.17.
//  Copyright © 2017 Konstantin Bondarchuk. All rights reserved.
//

import Foundation

typealias JsonObject = [String:AnyObject]

class KGAPI {
    
    
    // Result Enum
    enum RequestResult<T> {
        case success(T)
        case error(String)
    }
    
    
    // MARK: - Private Properties
    // --------------------------
    
    private var session: URLSession? = KGAPI.newSession()
    
    
    // MARK: - Private Methods
    // -----------------------
    
    static func newSession() -> URLSession
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }
    
    private func jsonObject<T>(from data: Data) -> T?
    {
        let jsonData: T?
        do {
            jsonData = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? T
        } catch {
            BKLog("Error parsing JSON from Data.", prefix: "!")
            return nil
        }
        
        return jsonData
    }
    
    private func checkHTTPResponse(with: Data?, _ response: HTTPURLResponse) -> RequestResult<Bool>
    {
        let statusCode = response.statusCode
        BKLog("[HTTP Response] Status code: \(statusCode)", function: "")
        
        if statusCode>=400 || statusCode<200{
            return .error("Response error \(statusCode)")
        }
        
        return .success(true)
    }
    
    private func checkForErrors(with data: Data?, _ response: URLResponse?, _ error: Error?) -> RequestResult<Data>
    {
        // Check error
        if error != nil {
            return .error("Network error! \n\(error?.localizedDescription ?? "Unknown error."))")
        }
        
        // Check HTTP response
        if case let .error(errorString) = self.checkHTTPResponse(with: data, response as! HTTPURLResponse) {
            return .error(errorString)
        }
        
        // Check data
        guard let newData = data else {
            return (.error("Error: No data received."))
        }

        
        // Return parsed data
        return .success(newData)
    }
    
    private func prepareUrlWith(methods: [String], query: [String:String] = [:]) -> URL?
    {
        // Query Items
        var components = URLComponents(string: KGConstants.baseURL)
        components?.path.append( methods.joined(separator: "/") )
        components?.queryItems = [URLQueryItem(name: "lang", value: KGConstants.Language.russian)]
        
        for item in query {
            components?.queryItems?.append(URLQueryItem(name: item.key, value: item.value))
        }
        
        BKLog("URL: \(components?.description ?? "n/a")", prefix: ">", function: "")
        
        return components?.url
    }
    
    // MARK: Generic Page Request
    private func requestObjects<T>(requestUrl: URL?, completionHandler: @escaping (RequestResult<T>) -> Void)
    {
        
        // Create URL
        guard requestUrl != nil else {
            //DispatchQueue.main.async { completionHandler(.error("Can't construct URL.")) }
            completionHandler(.error("Can't construct URL."))
            return
        }
        
        // Create Request
        let request = URLRequest(url: requestUrl!)
        
        BKLog("!!!   -1.Thread [requestObjects<T>]: \(Thread.current)")
        
        // Task
        let task = session?.dataTask(with: request) { data, response, error in
            
            BKLog("!!!   0.Thread [session.dataTask]: \(Thread.current)")
            // Check for error and prepare Json object
            switch self.checkForErrors(with: data, response, error){
                
            case let .success(newData):
                // Data -> JSON
                if let parsedJson: T = self.jsonObject(from: newData){
                    //DispatchQueue.main.async { completionHandler( .success(parsedJson)) }
                    completionHandler( .success(parsedJson))
                    
                } else {
                    //DispatchQueue.main.async { completionHandler( .error("Error parsing data!") ) }
                    completionHandler( .error("Error parsing data!") )
                }
                
            case let .error(errorString):
                //DispatchQueue.main.async { completionHandler(.error(errorString)) }
                completionHandler(.error(errorString))
                
            }
            
        }
        task?.resume()
    }

    private func genericPagedRequest(methods: [String], query: [String:String], nextPage: String?, _ completionHandler: @escaping (KGAPI.RequestResult<JsonObject>) -> Void)
    {
        let url: URL?
        if nextPage != nil {
            url = URL(string: nextPage!)
        }else {
            url = prepareUrlWith(methods: methods, query: query)
        }
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    func parsePagedResult(_ jsonObject: JsonObject,
                                  resultItemsBlock: ([JsonObject])->Void,
                                  nextPageBlock: (String)->Void,
                                  didFinishParsingBlock: ()->Void)
    {
        let count    = jsonObject[KGConstants.Keys.count] as? Int
        let result   = jsonObject[KGConstants.Keys.results] as? [JsonObject]
        let next     = jsonObject[KGConstants.Keys.nextPage] as? String
        //let previous = jsonObject[KGConstants.Keys.previousPage] as? String
        
        BKLog("Result: count \(count ?? -1) items, array parsed \(result?.count ?? -1), next: \(next ?? "<nil>")")
        
        
        guard result != nil else {
            BKLog("No result.", prefix: "!")
            return
        }
        
        
        // resultBlock
        BKLog("!!!   1.Thread [parseResult]: \(Thread.current)")
        resultItemsBlock(result!)
        
        
        if next != nil {
            BKLog("Continue parsing items...")
            nextPageBlock(next!)
        }else{
            BKLog("Did Finish parsing \(count ?? -1) items.")
            BKLog("---------------------------------")
            didFinishParsingBlock()
        }
    }


    
    // MARK: - Public
    // -------------------------
    
    func cancelAllTasks()
    {
        BKLog("Canceling all tasks.")
        session?.invalidateAndCancel()
        session = KGAPI.newSession()
    }
    

    // MARK: List of Cities
    func requestLocations(completionHandler: @escaping (RequestResult<[JsonObject]>) -> Void)
    {
        let query = ["fields":"slug,name,timezone,coords,language"]
        
        // Create URL
        let url = prepareUrlWith(methods: [KGConstants.Methods.locations], query: query)
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    // MARK: Event Categories List
    func requestEventCategories(completionHandler: @escaping (RequestResult<[JsonObject]>) -> Void)
    {
        // Create URL
        let url = prepareUrlWith(methods: [KGConstants.Methods.eventCategoriesArray])
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    // MARK: Place Categories List
    func requestPlaceCategories(completionHandler: @escaping (RequestResult<[JsonObject]>) -> Void)
    {
        // Create URL
        let url = prepareUrlWith(methods: [KGConstants.Methods.placeCategoriesArray])
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    
    
    // MARK: City Details
    func requestLocationDetails(slug: String, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        // Create URL
        let url = prepareUrlWith(methods: [KGConstants.Methods.locations, slug])
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    // MARK: List of Events
    func requestEvents(city: String, since sinceDate: Date, until untilDate: Date, nextPage: String? = nil, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        let query = ["location":city, "expand":"place", "actual_since":"\(sinceDate.timeIntervalSince1970)", "actual_until":"\(untilDate.timeIntervalSince1970)",
        "fields":"id,title,short_title,tagline,dates,place,price,categories,description,is_free"]
        
        //requestObjects(requestUrl: url, completionHandler: completionHandler)
        genericPagedRequest(methods: [KGConstants.Methods.events], query: query, nextPage: nextPage, completionHandler)
    }

    // MARK: List of Places
    func requestPlaces(city: String, since sinceDate: Date, until untilDate: Date, nextPage: String? = nil, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        let query = ["location":city,
                     "categories":"cinema",
                     "has_showings":"movie",
                     "showing_since":"\(sinceDate.timeIntervalSince1970)",
            "showing_until":"\(untilDate.timeIntervalSince1970)",
            "page_size":"\(KGConstants.pageSize)",
            "text_format":"plain",
            "fields":"id,title,description,address,coords,images,phone,location,timetable,favorites_count,comments_count,foreign_url"]
        
        genericPagedRequest(methods: [KGConstants.Methods.places], query: query, nextPage: nextPage, completionHandler)
    }
    
    // MARK: List of Movies
    func requestMovies(city: String, since sinceDate: Date, until untilDate: Date, placeId: Int?, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        var query = ["location":city, "page_size":"\(KGConstants.pageSize)", "actual_since":"\(sinceDate.timeIntervalSince1970)", "actual_until":"\(untilDate.timeIntervalSince1970)",
            "text_format":"plain",
"fields":"title,director,country,year,poster,images,id,description,stars,genres,body_text,running_time,age_restriction,writer,imdb_rating,imdb_url", "expand":"poster"]
        
        if let placeId = placeId {
           query["place_id"] = "\(placeId)"
        }
        
        // Create URL
        let url = prepareUrlWith(methods: [KGConstants.Methods.movies], query: query)
        
        requestObjects(requestUrl: url, completionHandler: completionHandler)
    }
    
    // MARK: List of Movie Showings
    func requestMovieShowings(city: String, placeId: Int, since sinceDate: Date, until untilDate: Date, nextPage: String? = nil, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        let query = ["location":city, "place_id":"\(placeId)", "page_size":"\(KGConstants.pageSize)", "actual_since":"\(sinceDate.timeIntervalSince1970)", "actual_until":"\(untilDate.timeIntervalSince1970)"]

        genericPagedRequest(methods: [KGConstants.Methods.movieShowings], query: query, nextPage: nextPage, completionHandler)
        
    }
    
    // MARK: List of Showings of THE movie
    func requestShowingsOfMovie(city: String, movieId: Int, since sinceDate: Date, until untilDate: Date, nextPage: String? = nil, completionHandler: @escaping (RequestResult<JsonObject>) -> Void)
    {
        let query = ["location":city, "page_size":"\(KGConstants.pageSize)", "actual_since":"\(sinceDate.timeIntervalSince1970)", "actual_until":"\(untilDate.timeIntervalSince1970)", "expand":"movie,place","fields":"movie,place,price,id,datetime,three_d,imax,four_dx,original_language"]
        
        genericPagedRequest(methods: [KGConstants.Methods.movies, "\(movieId)", "showings"], query: query, nextPage: nextPage, completionHandler)
        
    }
    

    
}
