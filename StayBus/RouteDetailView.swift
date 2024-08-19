import SwiftUI
import MapKit
import Firebase

struct RouteDetailView: View {
    @Binding var route: Route
    @State private var selectedStop: StopModel?
    @State private var directions: [MKRoute] = []
    @State private var busLocation: CLLocationCoordinate2D?
    @State private var isRouteOffline: Bool = false
    @State private var lastUpdateTime: Date?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MapView(route: route, directions: $directions, selectedStop: $selectedStop, busLocation: $busLocation)
                    .frame(height: geometry.size.height * 0.55)
                stopList
                
                if isRouteOffline {
                    Text("Route is offline")
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationTitle(route.name)
        .sheet(item: $selectedStop) { stop in
            StopDetailView(stop: stop)
        }
        .onAppear {
            calculateRoute()
            startBusLocationUpdates()
        }
    }

    private var stopList: some View {
        List(route.stops) { stop in
            VStack(alignment: .leading) {
                Text("Stop \(stop.stopNumber): \(stop.location)")
                    .font(.headline)
                Text("Time: \(stop.time)")
                    .font(.subheadline)
            }
            .padding(.vertical, 8)
        }
    }

    private func calculateRoute() {
        let stops = route.stops
        guard stops.count >= 2 else { return }

        for i in 0..<(stops.count - 1) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: stops[i].coordinates))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: stops[i+1].coordinates))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else { return }
                self.directions.append(route)
            }
        }
    }
    private func startBusLocationUpdates() {
            guard let deviceID = route.deviceID else { return }
            
            let db = Firestore.firestore()
            let docRef = db.collection("deviceLocations").document(deviceID)
            
            func fetchLocation() {
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let data = document.data()
                        if let latitude = data?["latitude"] as? Double,
                           let longitude = data?["longitude"] as? Double,
                           let lastUpdate = data?["lastUpdate"] as? Timestamp {
                            
                            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let updateTime = lastUpdate.dateValue()
                            
                            DispatchQueue.main.async {
                                self.busLocation = location
                                self.lastUpdateTime = updateTime
                                self.isRouteOffline = Date().timeIntervalSince(updateTime) > 300 // 5 minutes
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            }
            
            fetchLocation() // Initial fetch
            
            // Set up timer for periodic updates
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                fetchLocation()
            }
        }
}

struct MapView: UIViewRepresentable {
    let route: Route
    @Binding var directions: [MKRoute]
    @Binding var selectedStop: StopModel?
    @Binding var busLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set initial region to focus on the first stop
        if let firstStop = route.stops.first {
            let region = MKCoordinateRegion(
                center: firstStop.coordinates,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        // Add stop annotations
        let stopAnnotations = route.stops.map { stop -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = stop.coordinates
            annotation.title = "Stop \(stop.stopNumber)"
            annotation.subtitle = stop.location
            return annotation
        }
        uiView.addAnnotations(stopAnnotations)
        
        // Add bus location annotation if available
        if let busLocation = busLocation {
            let busAnnotation = MKPointAnnotation()
            busAnnotation.coordinate = busLocation
            busAnnotation.title = "Bus Location"
            uiView.addAnnotation(busAnnotation)
        }
        
        // Add route overlays
        for direction in directions {
            uiView.addOverlay(direction.polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation.title == "Bus Location" {
                let identifier = "BusMarker"
                var view: MKMarkerAnnotationView
                
                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                } else {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                
                view.markerTintColor = .blue
                view.glyphImage = UIImage(systemName: "bus.fill")
                return view
            } else {
                // Use the existing implementation for stop markers
                return nil
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct StopDetailView: View {
    let stop: StopModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stop \(stop.stopNumber)")
                .font(.title)
            Text("Location: \(stop.location)")
                .font(.headline)
            Text("Arrival Time: \(stop.time)")
                .font(.subheadline)
        }
        .padding()
    }
}
