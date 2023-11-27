//
//  ApplicationData.swift
//  MapTest
//
//  Created by Gaultier on 24/11/2023.
//

import Foundation
import SwiftUI
import MapKit

struct Annotation: Identifiable {
    let id = UUID()
    var selected: Bool = false
    var name: String
    var location: CLLocationCoordinate2D
    
    init(name: String, location: CLLocationCoordinate2D){
        self.name = name
        self.location = location
    }
}

class ApplicationData: NSObject, ObservableObject, CLLocationManagerDelegate {

 
    @Published var annotations: [Annotation] = []
    @State  var cameraPosition: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    
    let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = 500

    }
    
    func setAnnotations(region: MKCoordinateRegion) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Pizza"
        request.region = region
        
        let search = MKLocalSearch(request: request)
        if let results = try? await search.start(){
            let items = results.mapItems
            
            await MainActor.run {
                annotations = []
                for item in items {
                    if let location = item.placemark.location?.coordinate{
                        let place = Annotation(name: item.name ?? "Undefined", location: location)
                        annotations.append(place)
                    }
                }
            }
        }
    }
    
    func grantUserAuthorization(){
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
//        if let coordinates = locations.first?.coordinate {
//            region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
//            print(region.center.latitude)
//            print(region.center.longitude)
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("Error")
        print(error.localizedDescription)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
