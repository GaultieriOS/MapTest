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
            Map(initialPosition: .automatic){
                ForEach(applicationData.annotations){ place in
                    Marker(place.name, coordinate: place.location)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onMapCameraChange { context in
                print(context.region)
                Task {
                    await applicationData.setAnnotations(region:context.region)
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
