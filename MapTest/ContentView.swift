//
//  ContentView.swift
//  MapTest
//
//  Created by Gaultier on 24/11/2023.
//

import SwiftUI
import MapKit
import CoreLocationUI

struct ContentView: View {
    
    @ObservedObject var applicationData = ApplicationData()
    
    var body: some View {
        VStack{

            Map(initialPosition: .automatic, selection: $applicationData.selectedLocation){
                    ForEach(applicationData.annotations){ place in
                        Marker(place.name, coordinate: place.location)
                            .tag(place)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                }
                .onMapCameraChange { context in
                    Task {
                        await applicationData.setAnnotations(region:context.region, search: applicationData.searchText)
                    }
                }
                .sheet(isPresented: $applicationData.isSearching){
                    SheetView(applicationData: applicationData)
                }
                .overlay(alignment: .bottom){
                    if applicationData.selectedLocation != nil{
                        LookAroundPreview(scene: $applicationData.scene, allowsNavigation: false, badgePosition: .bottomTrailing)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .safeAreaPadding(.bottom, 40)
                            .padding(.horizontal, 20)
                    }
                }
                .onChange(of: applicationData.selectedLocation) {
                    if let selectedLocation = applicationData.selectedLocation {
                        Task {
                            applicationData.scene = try? await applicationData.fetchScene(for: selectedLocation.location)
                        }
                    }
                    applicationData.updateIsSearching()
                }
                .onChange(of: applicationData.searchResults) {
                    if let firstResult = applicationData.searchResults.first, applicationData.searchResults.count == 1 {
                                applicationData.selectedLocation = firstResult
                            }
                        }
            }.onAppear {
                applicationData.grantUserAuthorization()
            }
    }
}

#Preview {
    ContentView()
}
