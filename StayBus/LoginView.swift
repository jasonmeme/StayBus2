//
//  LoginRegistrationView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/10/24.
//

import SwiftUI
import Firebase
import Lottie

struct LoginView: View {
    @State private var isLogin = true // Toggle between login and registration
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width / 3.4)
                        .padding(.top, 5.0)
                        .padding(.trailing, 20.0)
                }
                
                LottieView(animation: .named("bus_new"))
                    .looping()
                    .padding(30)
                
                HeaderLoginView()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                HStack{
                    Spacer()
                    NavigationLink {
                        ForgotPassView()
                    } label: {
                        Text("Forgot Password")
                            .font(.system(size: 15))
                            .padding(.trailing, 20)
                    }
                    
                }
                
                if !isLogin {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                Button(isLogin ? "Login" : "Register") {
                    if isLogin {
                        login()
                        print("Login requested")
                    } else {
                        register()
                        print("Registration requested")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12.0)
                .foregroundColor(.white)
                .background(Color.blue)
                .font(.system(size: 20))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HStack {
                    Text("Don’t have an account?")
                        .font(.system(size: 15))
                        .fontWeight(.thin)
                    NavigationLink {
                        RegistrationView()
                    } label: {
                        Text("Sign Up")
                    }
                    
                }
                .padding(.bottom, 80)
            }
            .background(Color(hex: "#E2F3FC"))
            
        }
    }
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
            } else {
                print("Login successful!")
            }
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Registration error: \(error.localizedDescription)")
            } else {
                print("Registration successful!")
            }
        }
    }
    
}

struct LoginRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

