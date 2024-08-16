//
//  FavoriteRoutesView.swift
//  StayBus
//
//  Created by Jason Zhu on 8/16/24.
//

import SwiftUI

struct FavoriteRoutesView: View {
    @Binding var routes: [Route]
    
    var favoriteRoutes: [Route] {
        routes.filter { $0.isFavorite }
    }
    
    var body: some View {
        List {
            ForEach(favoriteRoutes.indices, id: \.self) { index in
                NavigationLink(destination: RouteDetailView(route: binding(for: favoriteRoutes[index]))) {
                    Text(favoriteRoutes[index].name)
                }
            }
        }
        .navigationTitle("Favorite Routes")
    }
    
    private func binding(for route: Route) -> Binding<Route> {
        guard let index = routes.firstIndex(where: { $0.id == route.id }) else {
            fatalError("Can't find route in array")
        }
        return $routes[index]
    }
}
