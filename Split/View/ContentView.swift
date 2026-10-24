import SwiftUI
import SwiftData

//routes we navigate to that AREN'T a model object.
//(we push Bill objects directly, but "Previous Bills" isn't a model, so it gets a case here.)
enum HomeRoute: Hashable {
    case previousBills
}

//the app's root view. Split.swift shows this first.
//it owns the navigation stack for the whole app.
struct ContentView: View {
    // The SwiftData context (where bills/items are saved). Comes from the app's modelContainer.
    @Environment(\.modelContext) private var context

    //the navigation history. Appending to this pushes a new screen
    //the back button pops it. Keeping it here lets any screen navigate by editing `path`.
    @State private var path = NavigationPath()

    var body: some View {
        //NavigationStack = the container that handles push/pop navigation.
        NavigationStack(path: $path) {
            // The first screen shown inside the stack.
            HomeView(path: $path)

                //rule: whenever a Bill is pushed onto `path`, show the item editor for it.
                .navigationDestination(for: Bill.self) { bill in
                    EditBillView(bill: bill, context: context)
                }

                //rule: whenever a HomeRoute is pushed, show the matching screen.
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .previousBills:
                        PreviousBillView(path: $path)
                    }
                }
        }
    }
}

// Xcode preview. We attach a modelContainer so SwiftData works in the preview too.
#Preview {
    ContentView()
        .modelContainer(for: [Bill.self, Item.self, Person.self, Restaurant.self])
}
