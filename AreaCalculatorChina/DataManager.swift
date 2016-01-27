//
//  DataManager.swift
//  TopApps
//
//  Created by Dani Arnaout on 9/2/14.
//  Edited by Eric Cerney on 9/27/14.
//  Copyright (c) 2014 Ray Wenderlich All rights reserved.
//

import Foundation

//var address: ViewController!



class DataManager {

    class func getLocationFromBaidu(address: String, success: ((LocationData: NSData!) -> Void)) {
        let addressURL = "http://api.map.baidu.com/geocoder/v2/?address=" + address + "&output=json&ak=dg6vqwlXGRKITgjxC6c2iQ08"
        //let urlString = addressURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let urlString = addressURL.stringByAddingPercentEncodingWithAllowedCharacters( NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: urlString!)!
        loadDataFromURL(url, completion: { (data, error) -> Void in
            if let urlData = data {
                success(LocationData: urlData)
            }
        })
    }
    
 
  class func loadDataFromURL(url: NSURL, completion:(data: NSData?, error: NSError?) -> Void) {
     let session = NSURLSession.sharedSession()
    
    

    // Use NSURLSession to get data from an NSURL
     let loadDataTask = session.dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
      if let responseError = error {
        print(responseError)
        completion(data: nil, error: responseError)
      } else if let httpResponse = response as? NSHTTPURLResponse {
         if httpResponse.statusCode != 200 {
              let statusError = NSError(domain:"ca.beida", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey : "HTTP status code has unexpected value."])
          completion(data: nil, error: statusError)
        } else {
          completion(data: data, error: nil)
        }
      }
    })
    loadDataTask.resume()
    }
}