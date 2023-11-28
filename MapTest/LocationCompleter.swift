//
//  LocationCompleter.swift
//  MapTest
//
//  Created by Gaultier on 28/11/2023.
//

import MapKit


@Observable
class LocationService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    
    var annotationsCompletion: [SearchResult] = []
    
    var completions = [SearchCompletions]()
    
    init(completer: MKLocalSearchCompleter) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }
    
    func update(queryFragment: String) {
        completer.resultTypes = .pointOfInterest
        completer.queryFragment = queryFragment
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { completion in
            let mapItem = completion.value(forKey: "_mapItem") as? MKMapItem
            
            return .init(
                title: completion.title,
                subTitle: completion.subtitle,
                url: mapItem?.url
            )
        }
    }
    
@MainActor
    func search(with query: String, coordinate: CLLocationCoordinate2D? = nil) async throws -> [SearchResult] {

            let mapKitRequest = MKLocalSearch.Request()
            mapKitRequest.naturalLanguageQuery = query
            mapKitRequest.resultTypes = .pointOfInterest
            if let coordinate {
                mapKitRequest.region = .init(.init(origin: .init(coordinate), size: .init(width: 1, height: 1)))
            }
            let search = MKLocalSearch(request: mapKitRequest)
            
            
            let response = try await search.start()
            
            annotationsCompletion = []
            return response.mapItems.compactMap { mapItem in
                if let location = mapItem.placemark.location?.coordinate {
                    return SearchResult(name: mapItem.name ?? "", location: location, url: mapItem.url)
                }
                return SearchResult(name: mapItem.name ?? "", location: mapItem.placemark.location!.coordinate, url: mapItem.url)
            }
        
    }
}
