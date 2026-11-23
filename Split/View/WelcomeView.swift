//
//  WelcomeView.swift
//  Split
//
//  Created by Mia Nguyen on 11/20/26.
//

import SwiftUI

//first-launch screen: greet the user and capture their name.
struct WelcomeView: View {
    var onFinish: (String) -> Void
    @State private var name = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 8) {
                    Text("Welcome")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Split restaurant bills with friends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Please enter your name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("Your name", text: $name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.glowCard))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
                        .foregroundStyle(.white)
                        .submitLabel(.done)
                        .onSubmit(finish)
                }
                Spacer()
                Button(action: finish) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.brandAccent))
                }
                .buttonStyle(.plain)
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.5 : 1)
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }

    private func finish() {
        guard !trimmed.isEmpty else { return }
        onFinish(trimmed)
    }
}
