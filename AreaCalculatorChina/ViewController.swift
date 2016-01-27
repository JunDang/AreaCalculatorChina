//
//  ViewController.swift
//  AreaCalculatorChina
//
//  Created by Yuan Yinhuan on 15/11/17.
//  Copyright © 2015年 Jun Dang. All rights reserved.
//

import UIKit

enum MapType: Int {
    case Standard = 0
    case Satellite
}

class ViewController: UIViewController, MAMapViewDelegate, AMapSearchDelegate, UISearchBarDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate {
    
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var mapView: MAMapView!
    
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    var search: AMapSearchAPI!
    var pointAnnotation: MAPointAnnotation!
    var annotation: MAAnnotation!
    var searchController: UISearchController!
    var points: [CLLocationCoordinate2D]=[]
    var myPolyline:MAPolyline?           // line between 2 points
    var myPolylineView:MAPolylineView?   // draw lines
    var myPolygon: MAPolygon?
    var myPolygonView: MAPolygonView?
    var addresstoPass: String!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
        searchBar!.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func initMapView() {
        mapView!.showsCompass = false
        mapView!.scaleOrigin = CGPointMake(100, mapView.frame.size.height-20)
        mapView!.showsScale = true
        
        mapView!.delegate = self
        self.view.addSubview(mapView!)
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: "action:")
        uilpgr.delegate = self
        uilpgr.minimumPressDuration = 0.5
        mapView!.addGestureRecognizer(uilpgr)
        
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        let mapType = MapType(rawValue: mapTypeSegmentedControl.selectedSegmentIndex)
        switch (mapType!) {
        case .Standard:
            mapView!.mapType = MAMapType.Standard
        case .Satellite:
            mapView!.mapType = MAMapType.Satellite
            
        }
        
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
        if self.mapView?.annotations.count != 0 {
            annotation = self.mapView!.annotations[0] as! MAAnnotation
            self.mapView?.removeAnnotations(self.mapView?.annotations)
            self.mapView?.removeOverlays(self.mapView?.overlays)
            points.removeAll()
        }
        
        DataManager.getLocationFromBaidu(searchBar.text!, success: {(LocationData) -> Void in
            let json = JSON(data: LocationData)
            if json["msg"] != "Internal Service Error:无相关结果" {
                let longitudeX = json["result"]["location"]["lng"].double!
                let latitudeY = json["result"]["location"]["lat"].double!
                let centerCoordinate = CLLocationCoordinate2DMake(latitudeY, longitudeX)
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView!.setCenterCoordinate(centerCoordinate, animated: true)
                    self.pointAnnotation = MAPointAnnotation()
                    self.pointAnnotation.coordinate = CLLocationCoordinate2DMake(latitudeY, longitudeX)
                    self.pointAnnotation.title = searchBar.text
                    self.mapView!.addAnnotation(self.pointAnnotation)
                    //self.mapView!.setZoomLevel(6, animated: true)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    let myAlert = UIAlertController(title: nil, message: "没有找到对应的地址，请重新输入", preferredStyle: .Alert)
                    let action = UIAlertAction(
                        title: "好的",
                        style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    myAlert.addAction(action)
                    self.presentViewController(myAlert, animated: true, completion: nil)
                }
                
            }
        })
    }
    
    func mapView(mapView: MAMapView!, viewForAnnotation annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKindOfClass(MAPointAnnotation){
            let annotationIdentifier = "locationIdentifier"
            
            var poiAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationIdentifier) as? MAPinAnnotationView
            
            if poiAnnotationView == nil {
                poiAnnotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                
            }
            poiAnnotationView?.image = UIImage(named: "blank_badge_red")
            poiAnnotationView?.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
            poiAnnotationView!.animatesDrop = false
            poiAnnotationView!.canShowCallout = true
            poiAnnotationView!.draggable = true
            
            return poiAnnotationView
        }
        return nil
    }
    
    @IBAction func calculatorButtonPressed(sender: AnyObject) {
        if points.isEmpty {
           displayNowPointsMessage()
    
        } else {
            points.append(points[0])
            let area = abs(ringArea(points))
            let distance = abs(geoDistance(points))
            let calculatedArea = (round(area * 1000))/1000
            let calculatedAreaKilo = (round(area / 10000000 * 1000))/1000
            let calculatedMu = (round(area / 666.67 * 1000))/1000
            let calculatedDistance = (round(distance * 1000))/1000
            let calculatedKilo = (round(distance/1000 * 1000))/1000
            let userMessage = "该区域面积约为: \(calculatedArea)平方米，\(calculatedAreaKilo)平方公里，或\(calculatedMu)亩。周长约为: \(calculatedDistance)米或\(calculatedKilo)公里。"
            let myAlert = UIAlertController(title: "计算结果", message: userMessage, preferredStyle: .Alert)
            let action = UIAlertAction(
                title: "好的",
               style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
        }
        myAlert.addAction(action)
        presentViewController(myAlert, animated: true, completion: nil)
        }
        
        
    }
    
    
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        if points.isEmpty {
            displayNowPointsMessage()
        } else {
        self.mapView?.removeAnnotations(self.mapView?.annotations)
        self.mapView?.removeOverlays(self.mapView?.overlays)
            points.removeAll()
        }
        
    }
    func action(gestureRecoginizer: UIGestureRecognizer){
        
        if gestureRecoginizer.state == UIGestureRecognizerState.Began {
            
            let touchPoint = gestureRecoginizer.locationInView(self.mapView)
            let newCoordinate = self.mapView?.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            points.append(newCoordinate!)
            let pointOnMap: UnsafeMutablePointer<MAMapPoint> = UnsafeMutablePointer.alloc(points.count)
            for (var i = 0; i < points.count; i++){
                let point = MAMapPointForCoordinate(CLLocationCoordinate2DMake(points[i].latitude, points[i].longitude)) as MAMapPoint
                pointOnMap[i] = point
                //annotation
                let pointCoordinate = CLLocationCoordinate2DMake( points[i].latitude, points[i].longitude)
                let pointAnnotation = MAPointAnnotation()
                pointAnnotation.coordinate = pointCoordinate
                pointAnnotation.title = self.addresstoPass
                if (i == 0) {
                    self.mapView!.removeAnnotations(self.mapView?.annotations)
                }
                self.mapView!.addAnnotation(pointAnnotation)
            }
            self.mapView?.removeOverlays(self.mapView?.overlays)
            let pointsCount: NSNumber  = points.count
            if (pointsCount == 2) {
                if (myPolyline != nil) {
                    self.mapView?.removeOverlay(myPolyline)
                }
                myPolyline = MAPolyline(points: pointOnMap, count: pointsCount.unsignedLongValue)
                self.mapView?.addOverlay(myPolyline)
            } else if (pointsCount >= 3) {
                if (myPolygon != nil) {
                    self.mapView?.removeOverlay(myPolygon)
                }
                myPolygon = MAPolygon(points: pointOnMap, count: pointsCount.unsignedLongValue)
                self.mapView?.addOverlay(myPolygon)
            }
            
        }
        
    }
    
    func mapView(mapView: MAMapView!, viewForOverlay overlay: MAOverlay!) -> MAOverlayView! {
        var overLayView:MAOverlayView? = nil
        if overlay.isKindOfClass(MAPolyline) {
            if (myPolylineView != nil) {
                myPolylineView?.removeFromSuperview()
            }
            myPolylineView = MAPolylineView(polyline: myPolyline!)
            myPolylineView!.fillColor = UIColor.redColor()
            myPolylineView!.strokeColor = UIColor.redColor()
            myPolylineView!.lineWidth = 2
            overLayView = myPolylineView
        } else if overlay.isKindOfClass(MAPolygon) {
            if (myPolygonView != nil) {
                myPolygonView?.removeFromSuperview()
            }
            myPolygonView = MAPolygonView(polygon: myPolygon!)
            myPolygonView?.strokeColor = UIColor.redColor()
            overLayView = myPolygonView
        }
        return overLayView
    }
    
    func displayNowPointsMessage() {
        let userMessage = "请先长按地块的边界进行选择，然后按计算器按钮进行计算."
        let myAlert = UIAlertController(title: "提示", message: userMessage, preferredStyle: .Alert)
        let action = UIAlertAction(
            title: "知道了",
            style: .Default) { action in self.dismissViewControllerAnimated(true, completion: nil)
        }
        myAlert.addAction(action)
        presentViewController(myAlert, animated: true, completion: nil)

    }
    
    //calculate area
    func ringArea(points:[CLLocationCoordinate2D]) -> Double {
        var area: Double = 0.0
        
        if (points.count > 2) {
            var p1: CLLocationCoordinate2D = points[0]
            var p2: CLLocationCoordinate2D = points[1]
            
            for (var i = 0; i < points.count - 1; i++) {
                p1 = points[i]
                p2 = points[i + 1]
                area += rad(p2.longitude - p1.longitude) * (2 + sin(rad(p1.latitude)) + sin(rad(p2.latitude)))
            }
            
            area = area * 6378137 * 6378137 / 2;
        }
        
        return area
    }
    
    func rad(x: Double) -> Double {
        return x * M_PI / 180;
    }
    
    //calculate distance
    func geoDistance(points:[CLLocationCoordinate2D]) -> Double {
        var distance: Double = 0.0
        let EARTH_RADIUS = 6378137.0
        if (points.count >= 2) {
            var p1: CLLocationCoordinate2D = points[0]
            var p2: CLLocationCoordinate2D = points[1]
            for (var i = 0; i < points.count - 1; i++) {
                p1 = points[i]
                p2 = points[i + 1]
                let lat1 = rad(p1.latitude)
                let lat2 = rad(p2.latitude)
                let lng1 = rad(p1.longitude)
                let lng2 = rad(p2.longitude)
                distance += EARTH_RADIUS * acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lng1 - lng2))
            }
        }
        return distance
    }

    

}

