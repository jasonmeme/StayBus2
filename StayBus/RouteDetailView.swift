import SwiftUI
import MapKit

struct RouteDetailView: View {
    @Binding var route: Route
    @State private var selectedStop: StopModel?
    @State private var directions: [MKRoute] = []

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MapView(route: route, directions: $directions, selectedStop: $selectedStop)
                    .frame(height: geometry.size.height * 0.55)
                stopList
            }
        }
        .navigationTitle(route.name)
        .sheet(item: $selectedStop) { stop in
            StopDetailView(stop: stop)
        }
        .onAppear {
            calculateRoute()
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
}

struct MapView: UIViewRepresentable {
    let route: Route
    @Binding var directions: [MKRoute]
    @Binding var selectedStop: StopModel?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Set initial region to focus on the first stop
        if let firstStop = route.stops.first {
            let region = MKCoordinateRegion(
                center: firstStop.coordinates,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        // Add stop annotations
        let annotations = route.stops.map { stop -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = stop.coordinates
            annotation.title = "Stop \(stop.stopNumber)"
            annotation.subtitle = stop.location
            return annotation
        }
        uiView.addAnnotations(annotations)
        
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
            guard let annotation = annotation as? MKPointAnnotation else { return nil }
            
            let identifier = "StopMarker"
            var view: MKMarkerAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            
            view.markerTintColor = .red
            view.glyphText = annotation.title?.components(separatedBy: " ").last
            
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? MKPointAnnotation,
                  let stop = parent.route.stops.first(where: { $0.location == annotation.subtitle }) else { return }
            parent.selectedStop = stop
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
