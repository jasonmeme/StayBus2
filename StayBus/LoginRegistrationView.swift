//
//  LoginRegistrationView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/10/24.
//

import SwiftUI
import Firebase
import Lottie

struct LoginRegistrationView: View {
    @State private var isLogin = true // Toggle between login and registration
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""


    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                LottieView(animation: .named("bus"))
                .looping()
                .frame(width:UIScreen.main.bounds.width * 0.5, height: 200)
                .padding(.top, UIScreen.main.bounds.height * 0.1)
                
                Text("Log In")
                    .multilineTextAlignment(.leading)
                    .font(Font.custom("DM Serif Display Regular", size: 40)) // Set the font to title style
                    .multilineTextAlignment(.leading)
                
                Text("Welcome Back")
                    .multilineTextAlignment(.leading)
                    .font(Font.custom("Roboto Regular", size: 20)) // Set the font to title style
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(hex: "#A0A0A0"))
                Text("Please Enter Your Details.")
                    .multilineTextAlignment(.leading)
                    .font(Font.custom("Roboto Regular", size: 20)) // Set the font to title style
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(hex: "#A0A0A0"))
                
                Spacer()
            
                Picker("Mode", selection: $isLogin) {
                    Text("Login").tag(true)
                    Text("Register").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if !isLogin {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }

                Button(isLogin ? "Login" : "Register") {
                    // Action for login or register
                    if isLogin {
                        login()
                        print("Login requested")
                    } else {
                        register()
                        print("Registration requested")
                    }
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)

                Spacer()
            }
            .background(Color(hex: "#E2F3FC"))
            Image("Logo") // Replace "yourLogo" with the actual name of your logo in the asset catalog
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width / 4) // Adjusting the logo size based on screen width
                .padding(.top, 3) // Adjust top padding as needed
                .padding(.trailing, 30) // Adjust trailing padding as needed
            
            
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
        LoginRegistrationView()
    }
}

