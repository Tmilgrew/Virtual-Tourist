//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 1/29/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    func getImagesFromPin(_ parameters: [String: AnyObject], completionHandlerForGetImagesFromPin: @escaping (_ results: [AnyObject]?, _ error: NSError?) -> Void){
        
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(parameters))
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, create NSError and call completion handler
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandlerForGetImagesFromPin(nil, NSError(domain: "getImagesFromPin", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error */
            guard (error == nil) else {
                sendError((error?.localizedDescription)!)
                return
            }
            
            /* GUARD: Did we make a 200 response */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch{
                sendError("Serialization failed")
                return
            }
            
            /* GUARD: Did flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrClient.Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API Returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(FlickrClient.Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photo" key in our result? */
            guard let photos = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as? [AnyObject] else {
                sendError("Cannot find keys '\(FlickrClient.Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            completionHandlerForGetImagesFromPin(photos, nil)
        }
        
        task.resume()
    }
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
