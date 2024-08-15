//
//  Registration.swift
//  StayBus
//
//  Created by Jason Zhu on 5/13/24.
//

import SwiftUI
import Firebase


@MainActor
final class RegistrationViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func register() async {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        do {
            try await AuthenticationManager.shared.createUser(email: email, password: password)
            // TODO: Save full name to user profile or Firestore
        } catch {
            if let authError = error as? AuthError {
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                Text("Sign Up")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                
                Text("New Here?")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("Please enter your details")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            
            VStack(spacing: 15) {
                TextField("Full Name", text: $viewModel.fullName)
                    .textFieldStyle(ModernTextFieldStyle())
                
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(ModernTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            .padding(.top, 20)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            CustomButton(title: "Register", action: {
                Task {
                    await viewModel.register()
                }
            }, isPrimary: true)
            .padding(.top, 20)
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.5 : 1)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            )
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "#407D9F"))
                Spacer()
            }
            .padding(.bottom, 20)
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(Color(hex: "#E2F3FC"))
        .edgesIgnoringSafeArea(.all)
        .onChange(of: authManager.isAuthenticated) { _, newValue in
                    if newValue {
                        // User is authenticated, dismiss this view
                        dismiss()
                    }
                }
    }
}

#Preview {
    RegistrationView()
}
