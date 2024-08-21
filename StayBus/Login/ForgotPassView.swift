//
//  ForgotPassView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/13/24.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ForgotPassView: View {
    @State private var email = ""
    @State private var message = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Reset Password")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)

            TextField("Email", text: $email)
                .textFieldStyle(ModernTextFieldStyle())
                .autocapitalization(.none)

            CustomButton(title: "Send Reset Link", action: sendResetLink, isPrimary: true)
                .disabled(email.isEmpty || isLoading)

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(message.contains("sent") ? .green : .red)
                    .multilineTextAlignment(.center)
            }

            if isLoading {
                ProgressView()
            }

            Spacer()

            CustomButton(title: "Back to Login", action: { dismiss() }, isPrimary: false)
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(Color(hex: "#E2F3FC"))
        .edgesIgnoringSafeArea(.all)
    }

    private func sendResetLink() {
        isLoading = true
        message = ""

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            if let error = error {
                message = "Error: \(error.localizedDescription)"
            } else {
                message = "Password reset link sent to \(email)"
            }
        }
    }
}

struct ForgotPassView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPassView()
    }
}
