//
//  InitialsAvatar.swift
//  Split
//
//  Created by Mia Nguyen on 11/10/26.
//

import SwiftUI

//a circle avatar showing a person's initials in a color picked from their name.
//reused on every screen that lists people so the look stays consistent.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 40

    //first letter of first name + first letter of last name (e.g. "Mia Nguyen" -> "MN").
    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? (parts.last?.first.map(String.init) ?? "") : ""
        let result = (first + last).uppercased()
        return result.isEmpty ? "?" : result
    }

    //color is derived from the name so it's stable across relaunches (not truly random,
    //but deterministic means the same person is always the same color).
    private var color: Color {
        let palette: [Color] = [.blue, .green, .orange, .pink, .purple, .teal, .indigo, .red]
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }

    var body: some View {
        Circle()
            .fill(color.opacity(0.85))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}
