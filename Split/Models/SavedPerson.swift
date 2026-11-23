//
//  SavedPerson.swift
//  Split
//
//  Created by Mia Nguyen on 11/22/26.
//

import Foundation
import SwiftData

//a remembered person, saved across bills so names autocomplete when adding people.
@Model
final class SavedPerson {
    var name: String
    var lastUsed: Date

    init(name: String, lastUsed: Date = .now) {
        self.name = name
        self.lastUsed = lastUsed
    }
}
