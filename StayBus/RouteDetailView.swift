import SwiftUI
import MapKit

struct RouteDetailView: View {
    @Binding var route: Route
    @State private var region: MKCoordinateRegion
    @State private var showingNotificationSetup = false
    
    init(route: Binding<Route>) {
        self._route = route
        let firstStop = route.wrappedValue.stops.first!
        _region = State(initialValue: MKCoordinateRegion(
            center: firstStop.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        VStack {
            Map {
                ForEach(route.stops) { stop in
                    Annotation(stop.location, coordinate: stop.coordinates) {
                        Image(systemName: "bus.fill")
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                    }
                }
            }
            .frame(height: 300)
            
            List(route.stops) { stop in
                VStack(alignment: .leading) {
                    Text("Stop \(stop.stopNumber): \(stop.location)")
                        .font(.headline)
                    Text("Time: \(stop.time)")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(route.name)
        .navigationBarItems(trailing: HStack {
            Button(action: {
                showingNotificationSetup = true
            }) {
                Image(systemName: "bell")
            }
            Button(action: {
                route.isFavorite.toggle()
            }) {
                Image(systemName: route.isFavorite ? "star.fill" : "star")
                    .foregroundColor(route.isFavorite ? .yellow : .gray)
            }
        })
        .sheet(isPresented: $showingNotificationSetup) {
            NotificationSetupView(route: $route)
        }
    }
}
