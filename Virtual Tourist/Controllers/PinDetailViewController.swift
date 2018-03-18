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
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var itemToDelete = [Photo]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var selectedIndexes = [NSIndexPath]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    //MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var debugLabel: UILabel!
    
    
    //MARK: - Fetch Request Setup
    fileprivate func setupFetchedResultsController(){
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let photoPredicate = NSPredicate(format: "photoToLocation == %@", location)
        photoFetchRequest.predicate = photoPredicate
        let sortDescriptor = NSSortDescriptor(key: "photoID", ascending: true)
        photoFetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self as NSFetchedResultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        mapView.delegate = self
        setupFetchedResultsController()
        itemToDelete.removeAll()
        selectedIndexes.removeAll()
        setupMap()
        
        if location.locationToPhoto?.count == 0 {
            getPhotosFromPin(location!)
        }
    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: - Action Methods
    @IBAction func updateCollectionView(_ sender: Any) {
        
        if collectionButton.currentTitle == "Delete Selected Pictures" {
            for photo in itemToDelete {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
            collectionButton.setTitle("New Collection", for: .normal)
        } else {
            location.removeFromLocationToPhoto(location.locationToPhoto!)
            try? dataController.viewContext.save()
            getPhotosFromPin(location!)
        }
        itemToDelete.removeAll()
        selectedIndexes.removeAll()
    }
    
    
    
    // MARK: - Helper Methods
    
    func getPhotosFromPin(_ location: Location) {
        
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
                self.displayError(error?.localizedDescription)
                return
            }
            
            if let returnedPhotos = result {
                let photosToSave = self.returnPhotosToSave(returnedPhotos)
                
                for photo in photosToSave {
                    let thisPhoto = Photo(context: self.dataController.viewContext)
                    thisPhoto.imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
                    thisPhoto.photoID = photo[FlickrClient.Constants.FlickrResponseKeys.Title] as? String
                    thisPhoto.photoToLocation = location
                }
                try? self.dataController.viewContext.save()
            }
        }
    }
    
    
    func returnPhotosToSave(_ photos: [AnyObject]) -> [AnyObject] {
        let numberOfPhotosWeReturn: Int = 15
        
        var returnedPhotos = [AnyObject]()
        
        if photos.count == 0 {
            self.debugLabel.text = "There are no photos for this location"
            self.collectionButton.isEnabled = false
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
    
    func setupMap(){
        mapView.isUserInteractionEnabled = false
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)), animated: true)
        mapView.regionThatFits(MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)))
    }
    
    func displayError(_ error: String?) {
        
        performUIUpdatesOnMain {
            self.collectionButton.isEnabled = false
            self.collectionButton.backgroundColor = UIColor.gray
            self.collectionButton.setTitleColor(UIColor.white, for: .normal)
            if let errorString = error {
                print(errorString)
                self.debugLabel.text = errorString
            } else {
                self.debugLabel.text = "unknown error"
            }
        }
    }
}

// MARK: - Collection View Methods
extension PinDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let indexSelection = selectedIndexes.index(of: indexPath as NSIndexPath) {
            selectedIndexes.remove(at: indexSelection)
            itemToDelete.remove(at: itemToDelete.index(of: fetchedResultsController.object(at: indexPath))!)
            if itemToDelete.count == 0 {
                collectionButton.setTitle("New Collection", for: .normal)
            }
        } else {
            collectionButton.setTitle("Delete Selected Pictures", for: .normal)
            selectedIndexes.append(indexPath as NSIndexPath)
            itemToDelete.append(fetchedResultsController.object(at: indexPath))
        }
        print("\(itemToDelete)")
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let alreadySavedPhoto = self.fetchedResultsController.object(at: indexPath)
        
        if alreadySavedPhoto.imageData == nil {
            cell.imageView.image = UIImage(named: "placeholder")
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
            
            DispatchQueue.main.async(){
                
                let image = try! UIImage(data: Data(contentsOf: URL(string: alreadySavedPhoto.imageUrl!)!))
                alreadySavedPhoto.imageData = UIImagePNGRepresentation(image!) as NSData?
                try? self.dataController.viewContext.save()
                cell.activityIndicator.isHidden = true
                cell.activityIndicator.stopAnimating()
                cell.imageView.image = image
            }
        }else {
            let image = UIImage(data: alreadySavedPhoto.imageData! as Data)
            cell.activityIndicator.isHidden = true
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = image
        }

        if self.selectedIndexes.index(of: indexPath as NSIndexPath) == nil{
            cell.imageView.alpha = 1.0
            cell.imageView.backgroundColor = UIColor.white
        } else {
            cell.imageView.alpha = 0.3
            cell.imageView.backgroundColor = UIColor.gray
        }

        return cell
    }
}

// MARK: - Fetched Results Controller Delegate Methods
extension PinDetailViewController:NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for pathToInsert in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [pathToInsert as IndexPath])
            }
            
            for pathToDelete in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [pathToDelete as IndexPath])
            }}, completion: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath! as NSIndexPath)
        case .delete:
            deletedIndexPaths.append(indexPath! as NSIndexPath)
        default:
            break
        }
    }
}

extension PinDetailViewController:MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

