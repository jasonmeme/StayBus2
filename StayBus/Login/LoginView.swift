//
//  LoginRegistrationView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/10/24.
//

import SwiftUI
import Firebase
import Lottie
import AuthenticationServices

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func signIn(authManager: AuthenticationManager) async {
           guard !email.isEmpty, !password.isEmpty else {
               errorMessage = "Please enter both email and password."
               return
           }
           
           isLoading = true
           do {
               try await authManager.signIn(email: email, password: password)
           } catch {
               errorMessage = error.localizedDescription
           }
           isLoading = false
       }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeSheet: ActiveSheet?
    @State private var showForgotPassword = false
        
        enum ActiveSheet: Identifiable {
            case googleSignIn
            case appleSignIn
            case forgotPassword
            var id: Int {
                hashValue
            }
        }
    
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
                
                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        activeSheet = .forgotPassword
                                    }
                                    .foregroundColor(Color(hex: "#407D9F"))
                                }
            }
            .padding(.top, 20)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            CustomButton(title: "Sign In", action: {
                Task {
                    await viewModel.signIn(authManager: authManager)
                }
            }, isPrimary: true)
            .padding(.top, 20)
            
            VStack(spacing: 15) {
                CustomButton(action: {
                                    authManager.signInWithGoogle()
                                }, isPrimary: false) {
                                    HStack {
                                        Image("google_logo") // Make sure to add this image to your asset catalog
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                        Text("Sign In with Google")
                                            .font(.system(size: 20, weight: .semibold, design: .default))
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(10)

                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        activeSheet = .appleSignIn
                    }
                )
                .frame(height: 55)
                .cornerRadius(10)
            }
            .padding(.top, 20)
            
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
        .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .googleSignIn:
                        GoogleSignInView(authManager: _authManager)
                    case .appleSignIn:
                        AppleSignInView(authManager: authManager)
                    case .forgotPassword:
                        ForgotPassView()
                    }
                }
        .padding(.horizontal, 40)
        .background(Color(hex: "#E2F3FC"))
        .edgesIgnoringSafeArea(.all)
        .onChange(of: authManager.isAuthenticated) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

struct GoogleSignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if authManager.isAuthenticating {
                ProgressView("Signing in with Google...")
            } else if let error = authManager.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                Button("Dismiss") {
                    dismiss()
                }
            } else {
                Text("Preparing Google Sign-In...")
            }
        }
        .onAppear {
            authManager.signInWithGoogle()
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

struct AppleSignInView: View {
    let authManager: AuthenticationManager
    
    var body: some View {
        Text("Signing in with Apple...")
            .onAppear {
                authManager.signInWithApple()
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

