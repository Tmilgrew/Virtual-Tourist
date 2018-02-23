//
//  PinDetailViewController.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/19/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PinDetailViewController: UIViewController {
    
    // MARK: Properties
    var location:Location! 
    var dataController:DataController!
    var photos: [Photo] = []
    
    //MARK: Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    //let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
    //var photoPredicate = NSPredicate()
    
    override func viewDidLoad() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
//        let photoPredicate = NSPredicate(format: "location == %@", location)
//        photoFetchRequest.predicate = photoPredicate
//
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
//
//        if let result = try? dataController.viewContext.fetch(photoFetchRequest){
//            photos = result
//        }
        
        if photos.count == 0 {
            getPhotosFromPin(location!)
        }
        print("photos from pinDetail \(photos)")
    }
    
    func getPhotosFromPin(_ location: Location){
        
        // Need to make a string from Longitude and Latitude
        let bboxString = makeBboxString(CLLocationCoordinate2DMake((CLLocationDegrees(location.latitude)), (CLLocationDegrees(location.longitude))))
        
        let parameters = [
            FlickrClient.Constants.FlickrParameterKeys.Method: FlickrClient.Constants.FlickrParameterValues.SearchMethod,
            FlickrClient.Constants.FlickrParameterKeys.APIKey: FlickrClient.Constants.FlickrParameterValues.APIKey,
            FlickrClient.Constants.FlickrParameterKeys.BoundingBox: bboxString,
            FlickrClient.Constants.FlickrParameterKeys.Extras: FlickrClient.Constants.FlickrParameterValues.MediumURL,
            FlickrClient.Constants.FlickrParameterKeys.Format: FlickrClient.Constants.FlickrParameterValues.ResponseFormat,
            FlickrClient.Constants.FlickrParameterKeys.NoJSONCallback: FlickrClient.Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        FlickrClient.sharedInstance().getImagesFromPin(parameters as [String: AnyObject]){(result, error) in
            
            guard error == nil else {
                self.displayError(error!)
                return
            }
            if let returnedPhotos = result {
                let photosToSave = self.returnPhotosToSave(returnedPhotos)
                //print("\(photosToSave)")
                for photo in photosToSave {
                    let thisPhoto = Photo(context: self.dataController.viewContext)
                    thisPhoto.imageData = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
                    thisPhoto.photoID = photo[FlickrClient.Constants.FlickrResponseKeys.Title] as? String
                    thisPhoto.photoToLocation = location
                    try? self.dataController.viewContext.save()
                    print("\(thisPhoto)")
                }
            }
        }
    }
    
    func returnPhotosToSave(_ photos: [AnyObject]) -> [AnyObject] {
        //let numberOfPhotosPassed = photos.count as Int
        let numberOfPhotosWeReturn: Int = 15
        
        var returnedPhotos = [AnyObject]()
        
        if photos.count == 0 {
            /*
             TODO: Handle the scenario where there are no photos for this area.
             */
        } else {
            var photoNum = 0
            while photoNum < numberOfPhotosWeReturn {
                let randomIndex = Int(arc4random_uniform(UInt32(photos.count)))
                let photo = photos[randomIndex]
                returnedPhotos.append(photo)
                photoNum = photoNum + 1
            }
        }
        return returnedPhotos
    }
    
    func makeBboxString(_ location: CLLocationCoordinate2D) -> String{
        
        let longitude = Double(location.longitude)
        let latitude = Double(location.latitude)
        
        let minimumLong = max(longitude - FlickrClient.Constants.Flickr.SearchBBoxHalfWidth, FlickrClient.Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrClient.Constants.Flickr.SearchBBoxHalfHeight, FlickrClient.Constants.Flickr.SearchLatRange.0)
        let maximumLong = min(longitude + FlickrClient.Constants.Flickr.SearchBBoxHalfWidth, FlickrClient.Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrClient.Constants.Flickr.SearchBBoxHalfHeight, FlickrClient.Constants.Flickr.SearchLatRange.1)
        
        return "\(minimumLong),\(minimumLat),\(maximumLong),\(maximumLat)"
        
    }
    
    func displayError(_ error: NSError) {
        /*
         TODO: Implement this method
         */
    }
}
