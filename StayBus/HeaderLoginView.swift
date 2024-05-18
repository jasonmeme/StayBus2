//
//  HeaderView.swift
//  StayBus
//
//  Created by Jason Zhu on 5/18/24.
//

import SwiftUI

struct HeaderLoginView: View {
    var body: some View {
            VStack {
                LabelView(text: "Log In", fontSize: 40, fontWeight: .bold, colorHex: "#000000")
                    .padding(.bottom, 4.0)
                    
                LabelView(text: "Welcome Back", fontSize: 20, colorHex: "#A0A0A0")
                LabelView(text: "Please Enter Your Details.", fontSize: 20, colorHex: "#A0A0A0")
        }
    }
}
