//
//  CustomLabel.swift
//  StayBus
//
//  Created by Jason Zhu on 5/18/24.
//

import SwiftUI

struct LabelView: View {
    var text: String
    var fontSize: CGFloat
    var fontWeight: Font.Weight = .regular
    var colorHex: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(Color(hex: colorHex))
                .padding(.leading, 20.0)
            Spacer()
        }
    }
}
