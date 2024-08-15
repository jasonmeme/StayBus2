//
//  Home.swift
//  StayBus
//
//  Created by Jason Zhu on 5/13/24.
//

import SwiftUI

struct BeginView: View {
    var body: some View {
        TabView(selection: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Selection@*/.constant(1)/*@END_MENU_TOKEN@*/) {
            Text("Tab Content 1").tabItem { Text("Home") }.tag(1)
            MapView().tabItem { Text("Profile") }.tag(2)
            ProfileView().tabItem { Text("Map") }.tag(3)
        }
    }
}

#Preview {
    HomeView()
}
