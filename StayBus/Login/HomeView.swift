//
//  HomeView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/20/24.
//

import SwiftUI
import Lottie

struct HomeView: View {
    @State private var showLogin = false
    @State private var showRegistration = false
    
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Logo and App Name
                HStack {
                    Spacer()
                    Image("Logo") // Make sure you have a logo image in your assets
                        .resizable()
                        .scaledToFit()
                        .frame(height: 125)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                
                LottieView(animation: .named("bus_new"))
                                                .looping()
                                                .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                
                
                // Lottie animation
                
                
                Spacer()
                
                // Sign In button
                CustomButton(title: "Sign In", action: { showLogin = true }, isPrimary: true)
                    .padding(.horizontal, 40)
                
                // Create Account button
                CustomButton(title: "Create Account", action: { showRegistration = true }, isPrimary: false)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#E2F3FC"), Color(hex: "#FFFFFF")]), startPoint: .top, endPoint: .bottom)
            )
            .sheet(isPresented: $showLogin) {
                            LoginView().environmentObject(authManager)
                        }
                        .sheet(isPresented: $showRegistration) {
                            RegistrationView().environmentObject(authManager)
                        }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    
}
