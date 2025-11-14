import XCTest
@testable import AIHealthyMealPlannerApp

final class MealPlanningEngineTests: XCTestCase {
    func testGeneratesSevenDayPlan() async throws {
        let profileStore = ProfileStore()
        profileStore.update { profile in
            profile.firstName = "Test"
            profile.favoriteCuisines = ["Italian"]
        }
        let preferenceStore = PreferenceProfileStore()
        preferenceStore.seedTasteScores(from: ["Italian"])
        let pantryStore = PantryStore()
        let engine = MealPlanningEngine(
            preferenceStore: preferenceStore,
            profileStore: profileStore,
            pantryStore: pantryStore
        )

        let plan = await engine.generatePlan()

        XCTAssertEqual(plan.days.count, 7)
        XCTAssertEqual(plan.days.first?.meals.count, Meal.MealType.allCases.count)
    }
}
