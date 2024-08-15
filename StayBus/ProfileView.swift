//
//  Profile.swift
//  StayBus
//
//  Created by Jason Zhu on 5/14/24.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Welcome to your profile!")
                .font(.title2)
            
            Spacer()
            
            CustomButton(title: "Sign Out", action: signOut, isPrimary: false)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .background(Color(hex: "#E2F3FC"))
        .edgesIgnoringSafeArea(.all)
    }
    
    private func signOut() {
        authManager.signOut()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager.shared)
    }
}

#Preview {
    ProfileView()
}
