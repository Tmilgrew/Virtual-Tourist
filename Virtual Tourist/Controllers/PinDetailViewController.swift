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
    
    // MARK: - Properties
    var location:Location! 
    var dataController:DataController!
    var photos: [Photo] = []
    
    //MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    //let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
    //var photoPredicate = NSPredicate()
    
    fileprivate func setupFetchedResultsController(){
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let photoPredicate = NSPredicate(format: "photoToLocation == %@", location)
        photoFetchRequest.predicate = photoPredicate
        let sortDescriptor = NSSortDescriptor(key: "photoID", ascending: true)
        photoFetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        setupFetchedResultsController()
        
        if photos.count == 0 {
            print("we had no photos")
            getPhotosFromPin(location!)
            collectionView.reloadData()
        } else {
            print("we have photos")
            collectionView.reloadData()
        }
        //print("photos from pinDetail \(photos)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
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
                print("\(photosToSave)")
                for photo in photosToSave {
                    let thisPhoto = Photo(context: self.dataController.viewContext)
                    thisPhoto.imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
                    thisPhoto.photoID = photo[FlickrClient.Constants.FlickrResponseKeys.Title] as? String
                    //thisPhoto.imageData = thisPhoto.getPhotoData(thisPhoto.imageUrl!)
                    self.getPhotoData(thisPhoto.imageUrl!, thisPhoto){(data, error) in
                        thisPhoto.imageData = NSData(data: data! as Data)
                    }
                    thisPhoto.photoToLocation = location
                    try? self.dataController.viewContext.save()
                    print("\(thisPhoto)")
                }
            }
        }
    }
    
    func getPhotoData(_ urlString: String, _ photo: Photo, completionHandlerForGetPhotoData: @escaping (_ results: NSData?, _ errorString: String?) -> Void) {
        let url = URL(string: urlString)
        
        
        URLSession.shared.dataTask(with: url!){(data,response,error) in
            if error != nil {
                print("Failed fetching image: ", error as Any)
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print("Not a proper HTTPURLResponse or statusCode")
                return
            }
            
            completionHandlerForGetPhotoData(NSData(data: data!) , nil)
            }.resume()
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

extension PinDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
         TODO: Implement this method.  Item selected should be highlighted and added to a list of photos in queue to delete.
         */
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        /*
         TODO: Implement this method.
         */
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        
//        let image = UIImage(data: photo.imageData! as Data)
//        cell.imageView.image = image
//        if photo.imageData == nil {
//            cell.imageView.image = UIImage(contentsOfFile: <#T##String#>)
//        }
        //getPhotoData(photo.imageUrl!, photo){(data, error) in
        let imgData = photo.imageData
        let img: NSData? = photo.value(forKey: "imageData") as? NSData
//        cell.imageView.image = UIImage(contentsOfFile: photo.imageUrl!)
        cell.imageView.image = UIImage(data: img! as Data)

        //}
        
        
        return cell
        
    }
    
    
}
