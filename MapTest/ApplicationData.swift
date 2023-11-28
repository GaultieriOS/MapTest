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
    
    var searchText : String = ""
    let manager = CLLocationManager()
    
    
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
                for item in items {
                    if let location = item.placemark.location?.coordinate{
                        let place = SearchResult(name: item.name ?? "Undefined", location: location, url: item.url)
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
    
    func updateSearchText(search: String){
        searchText = search
    }
    
    func updateIsSearching(){
        isSearching = selectedLocation == nil
    }
    
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let lookAroundScene = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await lookAroundScene.scene
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
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
