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
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    var droppedPin : MKAnnotationView?
    var locations:[Location] = []
    var dataController:DataController!

    // MARK: - Lifecycle Methods
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
        
        // Set the fetch request and add pins to map
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
    
    /*
     We create the next view controller and create the fetch request.
     The fetch request performs the search by matching a latitude and longitude of the pin the user tapped on.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let controller = segue.destination as! PinDetailViewController
        
        let locationFetchRequest:NSFetchRequest<Location> = Location.fetchRequest()
        let latitude = Double((droppedPin?.annotation?.coordinate.latitude)!)
        let longitude = Double((droppedPin?.annotation?.coordinate.longitude)!)
        
        let locationPredicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude, longitude])
        locationFetchRequest.predicate = locationPredicate
        
        if let result = try? dataController.viewContext.fetch(locationFetchRequest){
            controller.location = result[0]
        }

        controller.dataController = dataController
    }

    // MARK: - Mapview Methods
    
    /*
     Whenever the user moves the map, we call saveMapRegion()
     */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    /*
     Creates the pin and it's properties
     */
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
    
    /*
     When a user taps on a pin, it will perform the segue
     */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        droppedPin = view
        performSegue(withIdentifier: "pushToCollection", sender: self)
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
    
    // MARK: - Helper Methods
    
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
            
        }
    }
}
