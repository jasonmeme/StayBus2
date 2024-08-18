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
    @State private var schools: [School] = []
    @State private var selectedSchool: School?
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
            if schools.isEmpty {
                ProgressView("Loading schools...")
            } else {
                Picker("Select School", selection: $selectedSchool) {
                    ForEach(schools, id: \.self) { school in
                        Text(school.name).tag(school as School?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                if let selectedSchool = selectedSchool {
                    SearchBar(text: $searchText)
                    
                    List {
                        if isLoading {
                            ProgressView()
                        } else {
                            ForEach(filteredRoutes) { route in
                                NavigationLink(destination: RouteDetailView(route: binding(for: route))) {
                                    Text(route.name)
                                }
                            }
                        }
                    }
                } else {
                    Text("Please select a school")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Routes")
        .onAppear(perform: fetchSchools)
        .onChange(of: selectedSchool) { newValue in
            if let school = newValue {
                fetchRoutes(for: school)
            } else {
                routes = []
            }
        }
    }
    
    private func fetchSchools() {
        let db = Firestore.firestore()
        db.collection("schools").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting schools: \(error)")
            } else {
                self.schools = querySnapshot?.documents.compactMap { document -> School? in
                    let data = document.data()
                    guard let name = data["name"] as? String else { return nil }
                    return School(id: document.documentID, name: name)
                } ?? []
                self.selectedSchool = self.schools.first
            }
        }
    }
    
    private func fetchRoutes(for school: School) {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("schools").document(school.id).collection("routes").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting routes: \(error)")
            } else {
                self.routes = querySnapshot?.documents.compactMap { document -> Route? in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let stops = data["stops"] as? [[String: Any]] else {
                        return nil
                    }
                    return Route(id: document.documentID, name: name, stops: stops.compactMap { StopModel(dictionary: $0, routeId: document.documentID) })
                } ?? []
                self.isLoading = false
            }
        }
    }
    
    private func binding(for route: Route) -> Binding<Route> {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else {
            fatalError("Can't find route in array")
        }
        return $routes[index]
    }
}

struct CustomDropdown: View {
    let placeholder: String
    let options: [String]
    @Binding var selection: String
    @Binding var isOpen: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selection.isEmpty ? placeholder : selection)
                    .foregroundColor(selection.isEmpty ? .gray : .primary)
                Spacer()
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .onTapGesture {
                withAnimation {
                    isOpen.toggle()
                }
            }
            
            if isOpen {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(selection == option ? Color.blue.opacity(0.1) : Color(.systemBackground))
                            .onTapGesture {
                                selection = option
                                withAnimation {
                                    isOpen = false
                                }
                            }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
        }
    }
}

struct School: Identifiable, Hashable {
    let id: String
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: School, rhs: School) -> Bool {
        lhs.id == rhs.id
    }
}

struct Route: Identifiable, Hashable {
    let id: String
    let name: String
    let stops: [StopModel]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        lhs.id == rhs.id
    }
}


struct StopModel: Identifiable, Hashable {
    let id: String
    let stopNumber: Int
    let time: String
    let location: String
    let coordinates: CLLocationCoordinate2D
    let routeId: String
    
    init?(dictionary: [String: Any], routeId: String) {
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
        self.routeId = routeId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: StopModel, rhs: StopModel) -> Bool {
        lhs.id == rhs.id
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
