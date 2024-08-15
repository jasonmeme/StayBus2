//
//  ContentView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/6/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                BeginView()
            } else {
                HomeView()
            }
        }
        .environmentObject(authManager)  // Add this line to ensure child views receive the AuthenticationManager
    }
}
