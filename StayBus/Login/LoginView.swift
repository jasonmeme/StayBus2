//
//  LoginRegistrationView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/10/24.
//

import SwiftUI
import Firebase
import Lottie

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        do {
            try await AuthenticationManager.shared.signIn(email: email, password: password)
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

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                Text("Log In")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Welcome Back")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("Please enter your details")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(.top, 60)
            
            VStack(spacing: 15) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(ModernTextFieldStyle())
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(ModernTextFieldStyle())
            }
            .padding(.top, 20)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            CustomButton(title: "Sign In", action: {
                Task {
                    await viewModel.signIn()
                }
            }, isPrimary: true)
            .padding(.top, 20)
            
            // TODO forgot password
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Don't have an account? Sign Up") {
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

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
    }
}

struct LoginRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
    }
}

