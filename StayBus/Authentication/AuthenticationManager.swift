//
//  AuthenticationManager.swift
//  StayBus
//
//  Created by Jason Zhu on 5/23/24.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseCore



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

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var error: Error?
    
    private var currentNonce: String?
    
    static let shared = AuthenticationManager()
    
    private override init() {
        super.init()
        isAuthenticated = Auth.auth().currentUser != nil
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if authResult != nil {
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                }
            }
        }
    }
    
    func createUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if authResult != nil {
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                }
            }
        }
    }
    
    func signInWithGoogle() {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            let config = GIDConfiguration(clientID: clientID)
            
            isAuthenticating = true
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                isAuthenticating = false
                error = NSError(domain: "SignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
                return
            }
            
            GIDSignIn.sharedInstance.configuration = config
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    self.isAuthenticating = false
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self.error = NSError(domain: "SignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
                    self.isAuthenticating = false
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.error = error
                        } else {
                            self?.isAuthenticated = true
                        }
                        self?.isAuthenticating = false
                    }
                }
            }
        }
    
    func signInWithApple() {
            let nonce = randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
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
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isAuthenticating = true
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                isAuthenticating = false
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                isAuthenticating = false
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if let error = error {
                        self?.error = error
                    } else if authResult != nil {
                        self?.isAuthenticated = true
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        DispatchQueue.main.async {
            self.isAuthenticating = false
            self.error = error
        }
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

