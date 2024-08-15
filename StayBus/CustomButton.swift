//
//  CustomButton.swift
//  StayBus
//
//  Created by Jason Zhu on 8/15/24.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    let isPrimary: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.isPressed = false
                }
            }
            self.action()
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(isPrimary ? .white : Color(hex: "#407D9F"))
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(isPrimary ? Color(hex: "#407D9F") : Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "#407D9F"), lineWidth: isPrimary ? 0 : 2)
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}
