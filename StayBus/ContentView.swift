//
//  ContentView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/6/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isAuthenticated {
                    BeginView()
                } else {
                    HomeView()
                }
            }
        }
        .environmentObject(authManager)
    }
}
