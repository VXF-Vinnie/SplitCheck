import SwiftUI
import SwiftData

//routes we navigate to that AREN'T a model object.
enum HomeRoute: Hashable {
    case previousBills
}

//the flow screens. @Model types don't auto-synthesize Hashable for the enum,
//so we write it ourselves using persistentModelID.
enum BillRoute: Hashable {
    case addPeople(Bill)
    case assignItems(Bill)
    case billSummary(Bill)
    case personSummary(Person)

    static func == (lhs: BillRoute, rhs: BillRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.addPeople(a), .addPeople(b)),
             let (.assignItems(a), .assignItems(b)),
             let (.billSummary(a), .billSummary(b)):
            return a.persistentModelID == b.persistentModelID
        case let (.personSummary(a), .personSummary(b)):
            return a.persistentModelID == b.persistentModelID
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .addPeople(let b):     hasher.combine(0); hasher.combine(b.persistentModelID)
        case .assignItems(let b):   hasher.combine(1); hasher.combine(b.persistentModelID)
        case .billSummary(let b):   hasher.combine(2); hasher.combine(b.persistentModelID)
        case .personSummary(let p): hasher.combine(3); hasher.combine(p.persistentModelID)
        }
    }
}

//the app's root: shows onboarding first, then the tab bar.
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var homePath = NavigationPath()
    @State private var billsPath = NavigationPath()
    @State private var firstTimeGreeting = false   //true only right after onboarding

    var body: some View {
        Group {
            if hasOnboarded {
                mainTabs
            } else {
                WelcomeView { name in
                    userName = name
                    hasOnboarded = true
                    firstTimeGreeting = true
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(.brandAccent)
    }

    //the two-tab main app, shown once the user has entered their name.
    private var mainTabs: some View {
        TabView {
            //--- Home tab ---
            NavigationStack(path: $homePath) {
                HomeView(path: $homePath, isFirstTime: firstTimeGreeting)
                    .billDestinations(context: context, path: $homePath)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            //--- Bills tab: full history ---
            NavigationStack(path: $billsPath) {
                PreviousBillView(path: $billsPath)
                    .billDestinations(context: context, path: $billsPath)
            }
            .tabItem { Label("Bills", systemImage: "list.bullet.rectangle") }
        }
    }
}

//every screen a stack can navigate to, in one place (shared by both tabs).
extension View {
    func billDestinations(context: ModelContext, path: Binding<NavigationPath>) -> some View {
        self
            .navigationDestination(for: Bill.self) { bill in
                EditBillView(bill: bill, context: context, path: path)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .previousBills:
                    PreviousBillView(path: path)
                }
            }
            .navigationDestination(for: BillRoute.self) { route in
                switch route {
                case .addPeople(let bill):
                    AddPeopleView(bill: bill, context: context, path: path)
                case .assignItems(let bill):
                    AssignItemsView(bill: bill, context: context, path: path)
                case .billSummary(let bill):
                    BillSummaryView(bill: bill, context: context, path: path)
                case .personSummary(let person):
                    PersonSummaryView(person: person, context: context)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bill.self, Item.self, Person.self, Restaurant.self, SavedPerson.self])
}
