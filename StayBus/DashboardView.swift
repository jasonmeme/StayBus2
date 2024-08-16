//
//  DashboardView.swift
//  StayBus
//
//  Created by Jason Zhu on 8/16/24.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to StayBus")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Add quick access buttons or widgets here
                NavigationLink(destination: RouteListView()) {
                    DashboardButton(title: "View Routes", systemImage: "list.bullet")
                }
                
                NavigationLink(destination: MapView()) {
                    DashboardButton(title: "Open Map", systemImage: "map")
                }
                
                // Add more quick access buttons as needed
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

struct DashboardButton: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AuthenticationManager.shared)
    }
}
