//
//  Home.swift
//  StayBus
//
//  Created by Jason Zhu on 5/13/24.
//

import SwiftUI

struct BeginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .environmentObject(authManager)
    }
}

struct BeginView_Previews: PreviewProvider {
    static var previews: some View {
        BeginView()
            .environmentObject(AuthenticationManager.shared)
    }
}

#Preview {
    HomeView()
}
