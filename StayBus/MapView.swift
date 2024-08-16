import SwiftUI
import MapKit
import Firebase

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.85, longitude: -71.52),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var routes: [Route] = []
    @State private var selectedRoute: Route?
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: routes.flatMap { $0.stops }) { stop in
                MapAnnotation(coordinate: stop.coordinates) {
                    Image(systemName: "bus.fill")
                        .foregroundColor(selectedRoute?.id == stop.id ? .red : .blue)
                        .background(Circle().fill(Color.white))
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(routes) { route in
                            Button(action: {
                                selectedRoute = route
                                let firstStop = route.stops.first!
                                region = MKCoordinateRegion(
                                    center: firstStop.coordinates,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            }) {
                                Text(route.name)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.1))
            }
        }
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
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
