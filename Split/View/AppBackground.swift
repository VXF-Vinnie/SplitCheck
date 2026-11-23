//
//  AppBackground.swift
//  Split
//
//  Created by Mia Nguyen on 11/22/26.
//

import SwiftUI

//app accent + a faint card fill that reads on the dark background.
extension Color {
    static let brandAccent = Color(red: 0.98, green: 0.46, blue: 0.13)   //warm orange
    static let glowCard = Color.white.opacity(0.06)
}

//"Midnight Glow": a deep base with two soft color glows up top.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.047, green: 0.055, blue: 0.078)   //#0c0e14 deep base
            RadialGradient(colors: [Color.brandAccent.opacity(0.32), .clear],
                           center: UnitPoint(x: 0.5, y: 0.0), startRadius: 0, endRadius: 340)
            RadialGradient(colors: [Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.26), .clear],
                           center: UnitPoint(x: 0.92, y: 0.20), startRadius: 0, endRadius: 320)
        }
        .ignoresSafeArea()
    }
}

//drop the glow behind a screen and hide the default list/scroll background.
struct MidnightScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AppBackground())
    }
}
extension View {
    func midnightScreen() -> some View { modifier(MidnightScreen()) }
}
