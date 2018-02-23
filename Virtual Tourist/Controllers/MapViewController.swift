//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 1/17/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var droppedPin : MKAnnotationView?
    var locations:[Location] = []
    var dataController:DataController!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView.delegate = self
        
        // Set the gesture recognizer
        let holdForPin = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        holdForPin.minimumPressDuration = 0.75
        mapView.addGestureRecognizer(holdForPin)
        
        // check to see if values have been saved before.  If so, call loadMapCenter()
        if UserDefaults.standard.value(forKey: "hasSavedBefore") != nil{
            loadMapCenter()
        } else {
            print("We've never saved before")
        }
        
        let fetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            locations = result
            var annotations = [MKPointAnnotation]()
            for location in locations {
                let lat = CLLocationDegrees(location.latitude)
                let long = CLLocationDegrees(location.longitude)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*
     Whenever the user moves the map, we call saveMapRegion()
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        saveMapRegion()
    }
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
//        let controller = storyboard!.instantiateViewController(withIdentifier: "PinDetailViewController") as! PinDetailViewController
//        let fetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
//        let coordinatePredicate: NSPredicate
//
//
//        let latitude = Double((view.annotation?.coordinate.latitude)!)
//        let longitude = Double((view.annotation?.coordinate.longitude)!)
//
//        coordinatePredicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude, longitude])
//        fetchRequest.predicate = coordinatePredicate
//
//        if let result = try? dataController.viewContext.fetch(fetchRequest){
//            controller.location = result[0]
//        }
        /*
         TODO: Handle Error
         */
        droppedPin = view
        performSegue(withIdentifier: "pushToCollection", sender: self)
        //navigationController!.pushViewController(controller, animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let controller = segue.destination as! PinDetailViewController
        
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let locationFetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
        let latitude = Double((droppedPin?.annotation?.coordinate.latitude)!)
        let longitude = Double((droppedPin?.annotation?.coordinate.longitude)!)
        
        
        let locationPredicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude, longitude])
        locationFetchRequest.predicate = locationPredicate
        if let result = try? dataController.viewContext.fetch(locationFetchRequest){
            controller.location = result[0]
        }
        
        let photoPredicate = NSPredicate(format: "photoToLocation == %@", controller.location)
        photoFetchRequest.predicate = photoPredicate
        if let photoResult = try? dataController.viewContext.fetch(photoFetchRequest){
            controller.photos = photoResult
        }
        
        controller.dataController = dataController
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
//        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        
        

        //photoPredicate = NSPredicate(format: "photo == %@", argumentArray: <#T##[Any]?#>)
    }
    
    
    /*
     In this method, we save the user's longitude, latitude, longitudeDelta, and latitudeDelta.
     We will use this information to persist the user's last centerpoint and zoom level.
     */
    func saveMapRegion(){
        UserDefaults.standard.set(Double(mapView.region.center.longitude), forKey: "usersLongitude1")
        UserDefaults.standard.set(Double(mapView.region.center.latitude), forKey: "usersLatitude1")
        UserDefaults.standard.set(Double(mapView.region.span.longitudeDelta), forKey: "usersDeltaLongitude1")
        UserDefaults.standard.set(Double(mapView.region.span.latitudeDelta), forKey: "usersDeltaLatitude1")
        UserDefaults.standard.set(true, forKey: "hasSavedBefore")
    }
    
    /*
     In this method, we get the user's last longitude, latitude, longitudeDelta, and latitudeDelta.
     We use these values to create a MKCoordinateRegion and then we set the map to this region.
     This persists the user's last centerpoint and zoom level
     */
    func loadMapCenter(){
        print("we are in loadMapCenter()")
        if let longitudeDouble = UserDefaults.standard.value(forKey: "usersLongitude1"), let latitudeDouble = UserDefaults.standard.value(forKey: "usersLatitude1"), let longitudeDeltaDouble = UserDefaults.standard.value(forKey: "usersDeltaLongitude1"), let latitudeDeltaDouble = UserDefaults.standard.value(forKey: "usersDeltaLatitude1"){
            let region:MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2DMake(latitudeDouble as! CLLocationDegrees, longitudeDouble as! CLLocationDegrees), span: MKCoordinateSpan(latitudeDelta: latitudeDeltaDouble as! CLLocationDegrees, longitudeDelta: longitudeDeltaDouble as! CLLocationDegrees))
            mapView.setRegion(region, animated: false)
        } else {
            print("had and issue in loadmapcenter")
        }
    }
    
//    func presentPhotosOfLocation(){
//
//    }
    
    @objc func addAnnotation(_ sender: UIGestureRecognizer){
        print("we are in addAnnotation()")
        if sender.state == .began {
            let userTouchLocation = sender.location(in: mapView)
            let userTouchCoordinate = mapView.convert(userTouchLocation, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = userTouchCoordinate
            
            mapView.addAnnotation(annotation)
            let location = Location(context: dataController.viewContext)
            location.latitude = annotation.coordinate.latitude as Double
            location.longitude = annotation.coordinate.longitude as Double
            try? dataController.viewContext.save()
            
            //getPhotosFromPin(userTouchCoordinate)
            
            /*
             TODO:
                A) Create the UI and segue for next page
                1) Persist this pin location
                2) Make the call to Flickr based on this pin
                3) Persist the photos returned by the call
                4) Display photos in next view
             */
        }
    }
    
//    func getPhotosFromPin(_ location: CLLocationCoordinate2D){
//        
//        // Need to make a string from Longitude and Latitude
//        let bboxString = makeBboxString(location)
//        
//        let parameters = [
//            FlickrClient.Constants.FlickrParameterKeys.Method: FlickrClient.Constants.FlickrParameterValues.SearchMethod,
//            FlickrClient.Constants.FlickrParameterKeys.APIKey: FlickrClient.Constants.FlickrParameterValues.APIKey,
//            FlickrClient.Constants.FlickrParameterKeys.BoundingBox: bboxString,
//            FlickrClient.Constants.FlickrParameterKeys.Extras: FlickrClient.Constants.FlickrParameterValues.MediumURL,
//            FlickrClient.Constants.FlickrParameterKeys.Format: FlickrClient.Constants.FlickrParameterValues.ResponseFormat,
//            FlickrClient.Constants.FlickrParameterKeys.NoJSONCallback: FlickrClient.Constants.FlickrParameterValues.DisableJSONCallback
//        ]
//        
//        FlickrClient.sharedInstance().getImagesFromPin(parameters as [String: AnyObject]){(result, error) in 
//            
//            guard error == nil else {
//                self.displayError(error!)
//                return
//            }
//            if let returnedPhotos = result {
//                let photosToSave = self.returnPhotosToSave(returnedPhotos)
//                print("\(photosToSave)")
//                for photo in photosToSave {
//                    let thisPhoto = Photo(context: self.dataController.viewContext)
//                    thisPhoto.imageData = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as? String
//                    thisPhoto.photoID = photo[FlickrClient.Constants.FlickrResponseKeys.Title] as? String
//                    try? self.dataController.viewContext.save()
//                }
//            }
//        }
//    }
//    
//    func returnPhotosToSave(_ photos: [AnyObject]) -> [AnyObject] {
//        //let numberOfPhotosPassed = photos.count as Int
//        let numberOfPhotosWeReturn: Int = 15
//        
//        var returnedPhotos = [AnyObject]()
//        
//        if photos.count == 0 {
//            /*
//             TODO: Handle the scenario where there are no photos for this area.
//             */
//        } else {
//            var photoNum = 0
//            while photoNum < numberOfPhotosWeReturn {
//                let randomIndex = Int(arc4random_uniform(UInt32(photos.count)))
//                let photo = photos[randomIndex]
//                returnedPhotos.append(photo)
//                photoNum = photoNum + 1
//            }
//        }
//        return returnedPhotos
//    }
//    
//    func makeBboxString(_ location: CLLocationCoordinate2D) -> String{
//        
//        let longitude = Double(location.longitude)
//        let latitude = Double(location.latitude)
//        
//        let minimumLong = max(longitude - FlickrClient.Constants.Flickr.SearchBBoxHalfWidth, FlickrClient.Constants.Flickr.SearchLonRange.0)
//        let minimumLat = max(latitude - FlickrClient.Constants.Flickr.SearchBBoxHalfHeight, FlickrClient.Constants.Flickr.SearchLatRange.0)
//        let maximumLong = min(longitude + FlickrClient.Constants.Flickr.SearchBBoxHalfWidth, FlickrClient.Constants.Flickr.SearchLonRange.1)
//        let maximumLat = min(latitude + FlickrClient.Constants.Flickr.SearchBBoxHalfHeight, FlickrClient.Constants.Flickr.SearchLatRange.1)
//        
//        return "\(minimumLong),\(minimumLat),\(maximumLong),\(maximumLat)"
//        
//    }
//    
//    func displayError(_ error: NSError) {
//        
//    }
}
