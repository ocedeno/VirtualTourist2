//
//  FlickrClient.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import Foundation

class FlickrClient
{
    static let sharedClient: FlickrClient = FlickrClient()
    fileprivate var session = URLSession.shared
    
    struct flickrConstants
    {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        static let ApiMethod = "flickr.photos.search"
        static let APIKey = "8f254826530527a1a83d8e8bdf2568a7"
        static let SafeSearch = 1
        static let extras = "url_m,date_taken"
        static let format = "json"
        static let nojsoncallback = 1
        static let SearchBBOXHalfWidth:Float = 0.01
        static let SearchBBOXHalfHeight:Float = 0.01
        static let SearchLatRange:(Float, Float) = (-90.0, 90.0)
        static let SearchLonRange:(Float, Float) = (-180.0, 180.0)
    }
    
    struct UIConstants
    {
        static let MaxPhotoCount = 21
        static let MaxPageCount = 15
        static let MaxItemsPerPage = 16
    }
    
    fileprivate func errorCheck(_ data: NSData?, response: URLResponse?, error: NSError?) -> NSError?
    {
        func sendError(_ error: String) -> NSError
        {
            print(error)
            let userInfo = [NSLocalizedDescriptionKey: error]
            return NSError(domain: "taskForGetMethod", code: -1, userInfo: userInfo)
        }
        
        //was there an error
        guard (error == nil) else
        {
            return sendError("There was an error with your request \(error)")
        }
        
        //did we get a successful response from the API?
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else
        {
            return sendError("There was an error with your request.  Status code is \((response as? HTTPURLResponse)?.statusCode)")
        }
        
        //guard was there any data returned
        guard let _ = data else
        {
            return sendError("Data was not found")
        }
        
        return nil
    }
    
    fileprivate func urlFromParameters(_ parameters: [String:AnyObject]?, query: String?, replaceQueryString: Bool) -> NSMutableURLRequest?
    {
        var components = URLComponents()
        components.scheme = flickrConstants.ApiScheme
        components.host = flickrConstants.ApiHost
        components.path = flickrConstants.APIPath
        
        if let query = query
        {
            components.query = query
        }
        
        if let parameters = parameters
        {
            var queryItems = [URLQueryItem]()
            
            for (key,value) in parameters
            {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                queryItems.append(queryItem)
            }
            
            components.queryItems = queryItems
        }
        
        if let url = components.url
        {
            return NSMutableURLRequest(url: url)
        }else
        {
            return nil
        }
    }
    
    
}
