//
//  ApplicationData.swift
//  MapTest
//
//  Created by Gaultier on 24/11/2023.
//

import Foundation
import SwiftUI
import MapKit

struct SearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
    var url: URL?
}

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    var isSelected: Bool = false
    var name: String
    var location: CLLocationCoordinate2D
    var url: URL?
    
    init(name: String, location: CLLocationCoordinate2D, url: URL?) {
        self.name = name
        self.location = location
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(isSelected)
            hasher.combine(name)
            hasher.combine(location.latitude)
            hasher.combine(location.longitude)
            hasher.combine(url)
        }

        static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
            return lhs.id == rhs.id &&
                lhs.isSelected == rhs.isSelected &&
                lhs.name == rhs.name &&
                lhs.location.latitude == rhs.location.latitude &&
                lhs.location.longitude == rhs.location.longitude &&
                lhs.url == rhs.url
        }
}

class ApplicationData: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var annotations: [SearchResult] = []
    @Published var selectedLocation: SearchResult?
    @Published var isSearching = true
    @Published var searchResults = [SearchResult]()
    @Published var search: String = ""
    @Published var scene: MKLookAroundScene?
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var travelTime: String?
    
    var searchText : String = ""
    let manager = CLLocationManager()
    let gradient = LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
    let stroke = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [8, 8])
    
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = 500
    }
    
    @MainActor func setAnnotations(region: MKCoordinateRegion, search: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = search
        request.region = region
        
        let search = MKLocalSearch(request: request)
        if let results = try? await search.start(){
            let items = results.mapItems
            
           await MainActor.run {
                annotations = []
               if let selected = selectedLocation{
                   annotations.append(selected)
               }
                for item in items {
                    if let location = item.placemark.location?.coordinate{
                        let place = SearchResult(name: item.name ?? "Undefined", location: location, url: item.url)
                        annotations.append(place)
                    }
                }
               annotations = removeDuplicates(annotations)
           }
        }
    }
    
    func removeDuplicates(_ array: [SearchResult]) -> [SearchResult] {
        var uniqueNames: Set<CLLocationCoordinate2D> = []
        var uniqueResults: [SearchResult] = []

        for result in array {
            if !uniqueNames.contains(result.location) {
                uniqueNames.insert(result.location)
                uniqueResults.append(result)
            }
        }

        return uniqueResults
    }
    
    func grantUserAuthorization(){
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func updateSearchText(search: String){
        searchText = search
    }
    
    func updateIsSearching(){
        isSearching = selectedLocation == nil
        route = nil
    }
    
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let lookAroundScene = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await lookAroundScene.scene
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        userLocation = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("Error")
        print(error.localizedDescription)
    }
    
    func fetchRouteFrom(_ source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        Task(priority: .userInitiated) {
            let result = try? await MKDirections(request: request).calculate()
            route = result?.routes.first
            getTravelTime()
        }
    }
    
    func getTravelTime() {
        guard let route else { return }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        travelTime = formatter.string(from: route.expectedTravelTime)
    }
}


extension CLLocationCoordinate2D: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
