//
//  Registration.swift
//  StayBus
//
//  Created by Jason Zhu on 5/13/24.
//

import SwiftUI
import Firebase

struct RegistrationView: View {
    @State private var isLogin = true // Toggle between login and registration
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image("Logo") // Replace "yourLogo" with the actual name of your logo in the asset catalog
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width / 3) // Adjusting the logo size based on screen width
                    .padding(.top, 5.0)
                    .padding(.trailing, 20.0) // Adjust top padding as needed
            }
            VStack {
                HStack {
                    Text("Sign Up")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.leading, 20.0)
                HStack {
                    Text("New Here?")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#A0A0A0"))
                    Spacer()
                }
                .padding(.leading, 20.0)
                HStack {
                    Text("Please Enter Your Details.")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#A0A0A0"))
                    Spacer()
                }
                .padding(.leading, 20.0)
                
                TextField("Full Name", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                HStack{
                    Spacer()
                    Button("Forgot Password") {
                        
                    }
                    .font(.system(size: 15))
                    .padding(.trailing, 20)
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
                    Button("Sign Up") {
                    }
                    .font(.system(size: 15))
                    .underline()
                }
                .padding(.bottom, 20)
            }
        }
        
        .background(Color(hex: "#E2F3FC"))
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

#Preview {
    RegistrationView()
}
