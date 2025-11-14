# AI Healthy Meal Planner

SwiftUI + Combine sample that demonstrates a multi-module architecture for an adaptive, taste-aware meal planning experience.  
The project scaffolds the core feature areas described in the specification: onboarding, AI-assisted meal planning, recipe rendering, shopping automation, nutrition tracking, and gamified feedback loops.

## Tech Stack
- Swift 5.9, SwiftUI, NavigationStack, Charts (optional)
- Combine-driven view models with dependency injection via `AppDependencies`
- CoreData placeholder via `PersistenceController`, CloudKit/Firebase sync stub (`CloudSyncService`)
- Create ML/server-side integration points exposed through `MealPlanningEngine` and `FeedbackLoop`
- HealthKit / WorkoutKit hooks encapsulated inside `HealthKitManager`
- Unit tests powered by XCTest (see `MealPlanningEngineTests`)

## Project Layout
```
Package.swift
Sources/AIHealthyMealPlannerApp/
├── App/                  # App entry + dependency wiring
├── Common/               # Shared helpers (notifications, constants)
├── Core/
│   ├── Models/           # Domain models (user, recipes, plans, feedback, etc.)
│   ├── Stores/           # Combine stores for profile, plans, shopping, gamification
│   ├── Engines/          # MealPlanningEngine (rule + ML hooks)
│   └── Services/         # FeedbackLoop, CloudSyncService
├── Data/
│   ├── Persistence/      # CoreData bootstrap placeholder
│   ├── Health/           # HealthKit manager actor
│   └── Sync/             # Room for CloudKit/Firebase adapters
└── Features/
    ├── Onboarding/       # Multi-step SwiftUI Form for profile capture
    ├── Dashboard/        # Meal plan grid, macro charts, feedback chips
    ├── RecipeKit/        # Recipe detail with timers + pantry mode stub
    ├── ShoppingList/     # Consolidated plan-to-cart list, export hook
    ├── NutritionTracker/ # HealthKit-powered insights + logs
    └── Gamification/     # Challenge center + streak tracking hooks
```

## Getting Started
1. Ensure the latest Xcode (15.2+) or Swift toolchain with SwiftUI support is installed.
2. Open the folder in Xcode (File → Open) or run `xed .` from `/workspace`.
3. Select the `AIHealthyMealPlannerApp` scheme and target iOS 17 simulator or a device.
4. Build & run. The onboarding sheet appears automatically until a profile is saved. Once complete, the sample plan, shopping list, nutrition tracker, and challenges tabs become interactive.

> **Note**  
> The ML generation, CloudKit/Firebase sync, grocery APIs, and HealthKit integrations are mocked so the sample can build everywhere (including Linux CI). Replace the stubs with concrete implementations when wiring the real services.

## Tests
Execute the SwiftPM test suite from Terminal:
```bash
swift test
```
The included `MealPlanningEngineTests` verify the engine creates a 7-day schedule with entries for each meal period.

## Next Steps
- Replace the deterministic recipe/meals with outputs from Create ML / server-hosted ranking APIs.
- Flesh out CoreData entities plus background sync bridging to CloudKit or Firebase.
- Implement Pantry barcode scanning via AVFoundation + product DB.
- Connect shopping list exports to Reminders/AppIntents and partner APIs (Instacart, Amazon Fresh).
- Integrate full HealthKit + WorkoutKit data ingestion and ActivityKit widgets for rings.