//
//  RouteListView.swift
//  StayBus
//
//  Created by Jason Zhu on 8/16/24.
//

import SwiftUI
import MapKit
import Firebase
import CoreLocation

struct RouteListView: View {
    @State private var routes: [Route] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    var filteredRoutes: [Route] {
            if searchText.isEmpty {
                return routes
            } else {
                return routes.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
        }
    
    var body: some View {
            VStack {
                SearchBar(text: $searchText)
                
                List {
                    if isLoading {
                        ProgressView()
                    } else {
                        ForEach(filteredRoutes) { route in
                            NavigationLink(destination: RouteDetailView(route: $routes[routes.firstIndex(where: { $0.id == route.id })!])) {
                                HStack {
                                    Text(route.name)
                                    Spacer()
                                    if route.isFavorite {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Routes")
            .onAppear(perform: fetchRoutes)
        }
    
    private func fetchRoutes() {
        let db = Firestore.firestore()
        db.collection("schools").document("Thorntons Ferry Elementary School").collection("routes").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.routes = querySnapshot?.documents.compactMap { document -> Route? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let stops = data["stops"] as? [[String: Any]] else {
                        return nil
                    }
                    return Route(id: document.documentID, name: name, stops: stops.compactMap { Stop(dictionary: $0) })
                } ?? []
                self.isLoading = false
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search routes", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
}

struct Route: Identifiable, Hashable {
    let id: String
    let name: String
    let stops: [Stop]
    var isFavorite: Bool = false
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.id == rhs.id
    }
}


struct Stop: Identifiable, Hashable {
    let id: String
    let stopNumber: Int
    let time: String
    let location: String
    let coordinates: CLLocationCoordinate2D
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let stopNumber = dictionary["stopNumber"] as? Int,
              let time = dictionary["time"] as? String,
              let location = dictionary["location"] as? String,
              let coordinatesDict = dictionary["coordinates"] as? [String: Double],
              let latitude = coordinatesDict["latitude"],
              let longitude = coordinatesDict["longitude"] else {
            return nil
        }
        
        self.id = id
        self.stopNumber = stopNumber
        self.time = time
        self.location = location
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Stop, rhs: Stop) -> Bool {
        lhs.id == rhs.id
    }
}

struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        RouteListView()
    }
}
