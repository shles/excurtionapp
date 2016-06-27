//
//  ViewController.swift
//  ExcurtionApp
//
//  Created by Артмеий Шлесберг on 24/06/16.
//  Copyright © 2016 Shlesberg. All rights reserved.
//

import UIKit
import MapKit
import Parse

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationArray: [MKMapItem] = []
    var annotations : [PhotoAnnotation] = []
    let locationManager = CLLocationManager()
    var excurtionId : Int! = 1
    
    var addingPiontMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getExcurtionId()
        retrieveExcurtion()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Point", style: .Done, target: self, action: #selector(addPoint))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "New Excurtion", style: .Done, target: self, action: #selector(newExcurtion))
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.locationSelected(_:)))

        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        
        mapView.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let route = overlay;
        let routeRenderer =  MKPolylineRenderer(overlay: route)
        routeRenderer.strokeColor = UIColor.blueColor()
        return routeRenderer;
    }
    
    func plotPolyline(route: MKRoute) {
        
        mapView.addOverlay(route.polyline)
        
        if mapView.overlays.count == 1 {
            mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
        else {
            let polylineBoundingRect =  MKMapRectUnion(mapView.visibleMapRect,
                                                       route.polyline.boundingMapRect)
            mapView.setVisibleMapRect(polylineBoundingRect,
                                      edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                      animated: false)
        }
    }
    
    func calculateSegmentDirections(index: Int, time: NSTimeInterval, routes: [MKRoute]) {
        
        let request: MKDirectionsRequest = MKDirectionsRequest()
        request.source = locationArray[index]
        request.destination = locationArray[index+1]
        request.requestsAlternateRoutes = true
        request.transportType = .Automobile
        
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler ({
            (response: MKDirectionsResponse?, error: NSError?) in
            if let routeResponse = response?.routes {
                let quickestRouteForSegment: MKRoute =
                    routeResponse.sort({$0.expectedTravelTime <
                        $1.expectedTravelTime})[0]
                
                var timeVar = time
                var routesVar = routes
                
                routesVar.append(quickestRouteForSegment)
                timeVar += quickestRouteForSegment.expectedTravelTime
                
                if index+2 < self.locationArray.count {
                    self.calculateSegmentDirections(index+1, time: timeVar, routes: routesVar)
                } else {
                    self.showRoute(routesVar, time: timeVar)
                    //self.hideActivityIndicator()
                }
            } else if let _ = error {
                let alert = UIAlertController(title: nil,
                    message: "Directions not available.", preferredStyle: .Alert)
                let okButton = UIAlertAction(title: "OK",
                style: .Cancel) { (alert) -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                }
                alert.addAction(okButton)
                self.presentViewController(alert, animated: true,
                    completion: nil)
            }
        })
    }
    
    func showRoute(routes: [MKRoute], time: NSTimeInterval) {
        for i in 0..<routes.count {
            plotPolyline(routes[i])
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? PhotoAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
                view.image = UIImage(named: "test")
            }
            return view
        }
        return nil
    }
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let annot = mapView.selectedAnnotations[0] as! PhotoAnnotation
        
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("photosList") as! PhotoListViewController
        
        vc.pointId = annot.pointId
        
        self.showViewController(vc, sender: self)
    }
    
    func newExcurtion(){
        locationArray = []
        mapView.removeAnnotations(annotations)
        mapView.removeOverlays(mapView.overlays)
        annotations = []
        
        excurtionId!+=1
        
        saveExcurtionId()
        
    }
    
    func addPoint(){
        addingPiontMode = true
    }
    
    func retrieveExcurtion(){
        let adress : [String : AnyObject] = [:]
        
        let q = PFQuery(className: "ExcurtionPoint" )
        
        q.whereKey("excurtionId", equalTo: excurtionId)
        q.orderByAscending("position")
        
        q.findObjectsInBackgroundWithBlock({ objects, error in
            
            for object in objects! {
                let geo = object["location"] as! PFGeoPoint
                let id = object.objectId!
                let position = object["position"] as! Int
                
                let coord = CLLocationCoordinate2D(latitude: geo.latitude , longitude: geo.longitude)
                let placemark = MKPlacemark(coordinate: coord, addressDictionary: adress)
                let mapItem = MKMapItem(placemark: placemark)
                
                let annot = PhotoAnnotation(title: "exc", locationName: "point", pointId: id, coordinate: coord, pos: position)
                
                self.annotations.append(annot)
                self.locationArray.append(mapItem)
            }
            self.mapView.addAnnotations(self.annotations)
            
            if self.annotations.count > 1 {
                self.calculateSegmentDirections(0, time: 0, routes: [])
            }
        })
    }
    
    func locationSelected(recognazer : UITapGestureRecognizer){
        if addingPiontMode {
            addingPiontMode = false
            
            let point  = recognazer.locationInView(mapView)
            
            let tapPoint = mapView.convertPoint(point, toCoordinateFromView: self.view)
            
            let testObject = PFObject(className: "ExcurtionPoint")
            print(testObject.objectId)
            
            let pos : Int
            
            if annotations.isEmpty {
                pos =  1
            }else {
                pos = annotations.last!.position + 1
            }
            testObject["location"] = PFGeoPoint(latitude: tapPoint.latitude, longitude: tapPoint.longitude)
            testObject["position"] = pos
            testObject["excurtionId"] = excurtionId
            
           
            
            testObject.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                print("Object has been saved.")
                print(testObject.objectId)
                
                let annotPoint = PhotoAnnotation(title: "excurtion point", locationName: "", pointId: testObject.objectId!, coordinate: tapPoint, pos: pos)
                
                self.mapView.addAnnotation(annotPoint)
                self.annotations.append(annotPoint)
                
                let placemark = MKPlacemark(coordinate: tapPoint, addressDictionary: [:])
                let mapItem = MKMapItem(placemark: placemark)
                self.locationArray.append(mapItem)
                if self.annotations.count >= 2 {
                    self.calculateSegmentDirections(pos-2, time: 0, routes: [])
                }
            }
        }
    }
    
    func saveExcurtionId(){
        NSUserDefaults.standardUserDefaults().setInteger(excurtionId, forKey: "EID")
    }
    
    func getExcurtionId(){
        if let eid = NSUserDefaults.standardUserDefaults().valueForKey("EID") as? Int {
            excurtionId = eid
        } else {
            excurtionId = 1
        }
    }
}

