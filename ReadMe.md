# Split

**Split** is an iOS app that helps groups divide a restaurant bill quickly and accurately. Instead of one person manually totaling the check, working out tax, and calculating tips, Split assigns each item to the people who ordered it and calculates what everyone owes, including their proportional share of tax and tip.

> **Status:** In development. This is a class project for CSE 335 at Arizona State University, Fall 2026.

---

## Features

- **Two ways to split.** Divide a total evenly, or itemize the bill and split it by what each person ordered.
- **Restaurant lookup.** Find nearby restaurants on a map based on your current location, and attach the restaurant to the bill.
- **Itemized bills.** Enter items with prices and quantities, and edit them to fix mistakes or add anything that was missed.
- **Item assignment.** Assign each item to one or more people. Shared items are divided evenly among the people who shared them.
- **Proportional tax and tip.** Choose an 18%, 20%, or 25% tip, or enter a custom amount. Each person pays tax and tip in proportion to their share of the bill.
- **Payment tracking.** Mark who has paid and who still owes.
- **Bill history.** Every completed bill is saved, so you can revisit past splits.

## Tech Stack

| Area | Technology |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM (Model–View–ViewModel) |
| Persistence | SwiftData |
| Maps and location | MapKit, Core Location |
| Networking | URLSession, with JSON decoded using `Codable` |
| Restaurant data | `[RESTAURANT API NAME]` |

## Requirements

- Xcode 16 or later
- iOS 17 or later
- An API key for `[RESTAURANT API NAME]`

## Getting Started

1. Clone the repository:
   ```bash
   git clone [REPO URL]
   cd [REPO FOLDER]
   ```
2. Open `[PROJECT NAME].xcodeproj` in Xcode.
3. Add your API key. See [API Key Setup](#api-key-setup) below.
4. Select an iOS 17+ simulator or device, then build and run (⌘R).
5. When prompted, allow location access so the app can find nearby restaurants.

### API Key Setup

`[TO BE COMPLETED once the restaurant API is chosen. Describe where the key goes, for example a configuration file excluded from Git with an example template committed in its place.]`

## Project Structure

The app follows the MVVM architecture, so data, view logic, and screens are kept in separate modules:

```
Split/
├── Models/        # SwiftData models (bills, items, people, restaurants)
├── ViewModels/    # Calculation logic and screen state
├── Views/         # SwiftUI screens
├── Services/      # Location and restaurant API services
└── SplitTests/    # Unit tests
```

*This structure is planned and may change during development.*

## Roadmap

| Phase | Scope | Due |
|---|---|---|
| Phase I | Design (use case, class, and MVVM diagrams; UI walkthrough) and first implementation iteration | Oct 25, 2026 |
| Phase II | Completed app | Nov 22, 2026 |
| Phase III | Individual technical presentations | Dec 4, 2026 |

## Development Workflow

- `main` always holds a version that compiles.
- Work happens on feature branches named `a/short-name` or `b/short-name`.
- Each change is merged through a pull request that links its issue and is reviewed by the other team member.
- Tasks are tracked with GitHub Issues and the project board.

## Team

- **Vincent Farfan**
- **Mia Nguyen**

Arizona State University, CSE 335, Fall 2026
