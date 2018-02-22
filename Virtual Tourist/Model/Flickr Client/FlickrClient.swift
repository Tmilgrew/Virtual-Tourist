//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 1/29/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation

class FlickrClient : NSObject {
    
    
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
