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
    
    var droppedPin : MKPinAnnotationView?
    
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
}
