//
//  SheetView.swift
//  MapTest
//
//  Created by Gaultier on 28/11/2023.
//

import SwiftUI
import MapKit

struct SheetView: View {
    // 1
    @State private var locationService = LocationService(completer: .init())
    @ObservedObject var applicationData : ApplicationData
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a restaurant", text: $applicationData.search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task {

                            applicationData.annotations = (try? await locationService.search(with: applicationData.search)) ?? []
                        }
                    }
            }
            .modifier(TextFieldGrayBackgroundColor())
            
            Spacer()
            List {
                ForEach(locationService.completions) { completion in
                    Button(action: { didTapOnCompletion(completion) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.headline)
                                .fontDesign(.rounded)
                            Text(completion.subTitle)
                            if let url = completion.url {
                                Link(url.absoluteString, destination: url)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .onChange(of: applicationData.search) {
            applicationData.updateSearchText(search: applicationData.search)
            locationService.update(queryFragment: applicationData.search)
        
        }
        .padding()
        .interactiveDismissDisabled()
        .presentationDetents([.height(200), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try await locationService.search(with: "\(completion.title)").first {
                applicationData.annotations = [singleLocation]
                applicationData.selectedLocation = applicationData.annotations.first
            }
        }
    }
}

struct TextFieldGrayBackgroundColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}
