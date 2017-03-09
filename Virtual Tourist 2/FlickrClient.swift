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
    
    struct FlickrConstants
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
        static let SearchBBOXHalfWidth: Double = 0.01
        static let SearchBBOXHalfHeight: Double = 0.01
        static let SearchLatRange:(Double, Double) = (-90.0, 90.0)
        static let SearchLonRange:(Double, Double) = (-180.0, 180.0)
    }
    
    struct UIConstants
    {
        static let MaxPhotoCount = 21
        static let MaxPageCount = 15
        static let MaxItemsPerPage = 16
    }
    
    fileprivate func errorCheck(_ data: Data?, response: URLResponse?, error: NSError?) -> NSError?
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
        components.scheme = FlickrConstants.ApiScheme
        components.host = FlickrConstants.ApiHost
        components.path = FlickrConstants.APIPath
        
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
    
    fileprivate func createBBox(_ latitude:Double, longitude:Double) -> String {
        let minLon = max(longitude - FlickrConstants.SearchBBOXHalfWidth, FlickrConstants.SearchLonRange.0)
        let maxLon = min(longitude + FlickrConstants.SearchBBOXHalfWidth, FlickrConstants.SearchLonRange.1)
        let minLat = max(latitude - FlickrConstants.SearchBBOXHalfHeight, FlickrConstants.SearchLatRange.0)
        let maxLat = min(latitude + FlickrConstants.SearchBBOXHalfHeight, FlickrConstants.SearchLatRange.1)
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    fileprivate func getPhotoPageNumber(withParameters parameters:[String:AnyObject], pin:PinAnnotation, completionHandler handler: @escaping (_ page: Int?, _ error: NSError?)-> Void)
    {
        guard let request = urlFromParameters(parameters, query: nil, replaceQueryString: false) else
        {
            let userInfo = [NSLocalizedDescriptionKey : "Could not generate request"]
            handler(nil, NSError(domain: "getPhotoPageNumber", code: -1, userInfo: userInfo))
            return
        }
        
        let task = session.dataTask(with: request as URLRequest)
        { (data, response, error) in
            if let error = self.errorCheck(data as Data?, response: response, error: error as NSError?)
            {
                handler(nil, error)
            } else
            {
                var parsedResult: AnyObject!
                
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
                } catch {
                    let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
                    handler(nil, NSError(domain: "getPhotoPageNumber", code: -1, userInfo: userInfo))
                }
                
                if let photos = parsedResult
                {
                    if let photosDict = photos["photos"] as? [String:AnyObject]
                    {
                        if let pageNumber = photosDict["pages"] as? Int
                        {
                            handler(pageNumber, nil)
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func getPhotosByLocation(using pin:PinAnnotation, completionHandler handler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void)
    {
        var parameters = [String:AnyObject]()
        
        //setup parameters for query
        parameters["bbox"] = createBBox(pin.latitude, longitude: pin.longitude) as AnyObject?
        parameters["safe_search"] = FlickrConstants.SafeSearch as AnyObject?
        parameters["extras"] = FlickrConstants.extras as AnyObject?
        parameters["api_key"] = FlickrConstants.APIKey as AnyObject?
        parameters["method"] = FlickrConstants.ApiMethod as AnyObject?
        parameters["format"] = FlickrConstants.format as AnyObject?
        parameters["nojsoncallback"] = FlickrConstants.nojsoncallback as AnyObject?
        parameters["per_page"] = UIConstants.MaxPhotoCount as AnyObject?
        
        getPhotoPageNumber(withParameters: parameters, pin: pin)
        { (pages, error) in
            
            guard error == nil else
            {
                handler(nil, error)
                return
            }
            
            if let pageCount = pages
            {
                let limit = min(pageCount, UIConstants.MaxItemsPerPage)
                let randomPage = Int(arc4random_uniform(UInt32(limit))) + 1
                parameters["page"] = min(randomPage, UIConstants.MaxPageCount) as AnyObject?
                
                guard let request = self.urlFromParameters(parameters, query: nil, replaceQueryString: false) else
                {
                    let userInfo = [NSLocalizedDescriptionKey : "Could not generate request"]
                    return handler(nil, NSError(domain: "createNSURLMutableRequest", code: -1, userInfo: userInfo))
                }
                
                let task = self.session.dataTask(with: request as URLRequest)
                { (data, response, error) in
                    if let error = self.errorCheck(data, response: response, error: error as NSError?)
                    {
                        handler(nil, error)
                    }else
                    {
                        var parsedResult: AnyObject!
                        
                        do
                        {
                            parsedResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as AnyObject
                        }catch
                        {
                            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as json"]
                            handler(nil, NSError(domain: "convertDataWithCompletionHandler", code: -1, userInfo: userInfo))
                        }
                        
                        handler(parsedResult, nil)
                    }
                }
                
                task.resume()
            }
        }

    }
}
