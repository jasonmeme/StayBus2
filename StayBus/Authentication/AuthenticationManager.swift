//
//  AuthenticationManager.swift
//  StayBus
//
//  Created by Jason Zhu on 5/23/24.
//

import Foundation
import FirebaseAuth


struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}

enum AuthError: Error {
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case unknown(String)
}

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    
    static let shared = AuthenticationManager()
    
    private init() {
        // Check if user is already signed in
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func createUser(email: String, password: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
