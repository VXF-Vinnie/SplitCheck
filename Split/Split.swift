import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Bill.self, Item.self, Person.self, Restaurant.self])
    }
}
