import SwiftUI
import MapKit
import Firebase

struct RouteDetailView: View {
    @Binding var route: Route
    @State private var selectedStop: StopModel?
    @State private var directions: [MKRoute] = []
    @State private var busLocation: CLLocationCoordinate2D?
    @State private var isRouteOffline: Bool = true
    @State private var lastUpdateTime: Date?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                MapView(route: route, directions: $directions, selectedStop: $selectedStop, busLocation: $busLocation, isRouteOffline: $isRouteOffline)
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
    @Binding var isRouteOffline: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
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
        
        let stopAnnotations = route.stops.map { stop -> NumberedAnnotation in
            let annotation = NumberedAnnotation(
                coordinate: stop.coordinates,
                title: "Stop \(stop.stopNumber)",
                subtitle: stop.location,
                number: stop.stopNumber
            )
            return annotation
        }
        uiView.addAnnotations(stopAnnotations)
        
        if let busLocation = busLocation, !isRouteOffline {
            let busAnnotation = MKPointAnnotation()
            busAnnotation.coordinate = busLocation
            busAnnotation.title = "Bus Location"
            uiView.addAnnotation(busAnnotation)
        }
        
        for direction in directions {
            uiView.addOverlay(direction.polyline)
        }
        
        if let busLocation = busLocation, !isRouteOffline {
            let region = uiView.region
            let span = MKCoordinateSpan(
                latitudeDelta: max(region.span.latitudeDelta, 0.05),
                longitudeDelta: max(region.span.longitudeDelta, 0.05)
            )
            let newRegion = MKCoordinateRegion(center: busLocation, span: span)
            uiView.setRegion(newRegion, animated: true)
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
                if let numberedAnnotation = annotation as? NumberedAnnotation {
                    let identifier = "NumberedStopMarker"
                    let view: NumberedMarkerView
                    
                    if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? NumberedMarkerView {
                        dequeuedView.annotation = numberedAnnotation
                        view = dequeuedView
                    } else {
                        view = NumberedMarkerView(annotation: numberedAnnotation, reuseIdentifier: identifier)
                    }
                    
                    view.number = numberedAnnotation.number
                    view.canShowCallout = true
                    return view
                } else if annotation.title == "Bus Location" {
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
                    view.displayPriority = .required
                    return view
                }
                
                return nil
            }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 64/255, green: 125/255, blue: 159/255, alpha: 1)  // #407D9F
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

class NumberedAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let number: Int

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, number: Int) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.number = number
    }
}

class NumberedMarkerView: MKAnnotationView {
    var number: Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(x: 0, y: 0, width: 24, height: 24)  // Reduced size
        self.backgroundColor = .clear  // Ensure transparent background
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let circleRect = rect.insetBy(dx: 1, dy: 1)  // Slight inset to prevent edge clipping
        
        // Draw outer circle
        context.setFillColor(UIColor(red: 64/255, green: 125/255, blue: 159/255, alpha: 1).cgColor)
        context.fillEllipse(in: circleRect)
        
        // Draw inner circle
        let inset = circleRect.insetBy(dx: 3, dy: 3)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: inset)
        
        // Draw number
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),  // Smaller font size
            .foregroundColor: UIColor(red: 64/255, green: 125/255, blue: 159/255, alpha: 1)
        ]
        let numberString = "\(number)"
        let size = numberString.size(withAttributes: attributes)
        let point = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        numberString.draw(at: point, withAttributes: attributes)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.layer.borderWidth = 0  // Ensure no border is drawn
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
