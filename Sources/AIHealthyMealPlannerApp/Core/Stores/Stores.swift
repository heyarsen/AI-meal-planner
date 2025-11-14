import Foundation
import Combine

final class ProfileStore: ObservableObject {
    @Published private(set) var profile = UserProfile()

    func update(_ transform: (inout UserProfile) -> Void) {
        var copy = profile
        transform(&copy)
        profile = copy
    }
}

final class PreferenceProfileStore: ObservableObject {
    @Published private(set) var profile: PreferenceProfile = .empty

    func applyFeedback(_ feedback: FeedbackEvent) {
        var copy = profile
        switch feedback.type {
        case .thumbsUp, .lovedIt:
            copy.likedMeals.insert(feedback.mealId)
            copy.dislikedMeals.remove(feedback.mealId)
        case .thumbsDown, .tooManyCarbs, .skip:
            copy.dislikedMeals.insert(feedback.mealId)
            copy.likedMeals.remove(feedback.mealId)
        }
        copy.lastUpdated = .init()
        profile = copy
        NotificationCenter.default.post(name: .tasteProfileUpdated, object: copy)
    }

    func seedTasteScores(from cuisines: [String]) {
        var copy = profile
        copy.tasteScores = cuisines.map { PreferenceProfile.TasteScore(cuisine: $0, score: 0.6) }
        copy.lastUpdated = .init()
        profile = copy
        NotificationCenter.default.post(name: .tasteProfileUpdated, object: copy)
    }
}

final class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [UUID: Recipe] = [:]

    func upsert(_ recipe: Recipe) {
        recipes[recipe.id] = recipe
    }

    func recipe(for id: UUID) -> Recipe? {
        recipes[id]
    }
}

final class PantryStore: ObservableObject {
    @Published private(set) var items: [PantryItem] = []

    func setItems(_ items: [PantryItem]) {
        self.items = items
    }
}

final class ShoppingListStore: ObservableObject {
    @Published private(set) var items: [ShoppingItem] = []

    func setItems(_ items: [ShoppingItem]) {
        self.items = items
    }

    func toggle(_ itemID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].isCompleted.toggle()
    }
}

final class NutritionLogStore: ObservableObject {
    @Published private(set) var entries: [NutritionLogEntry] = []

    func log(_ entry: NutritionLogEntry) {
        entries.append(entry)
    }
}

final class FeedbackStore: ObservableObject {
    @Published private(set) var events: [FeedbackEvent] = []

    func record(_ event: FeedbackEvent) {
        events.append(event)
    }
}

final class GamificationStore: ObservableObject {
    @Published private(set) var challenges: [Challenge] = []

    init() {
        challenges = [
            Challenge(title: "Cook 3 new meals", description: "Try three recipes you have never cooked.", target: 3, progress: 0, rewardBadge: "Chef Explorer"),
            Challenge(title: "Hydration Hero", description: "Log your hydration for 5 consecutive days.", target: 5, progress: 0, rewardBadge: "Hydration Hero")
        ]
    }

    func updateProgress(for challengeID: Challenge.ID, delta: Int) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeID }) else { return }
        challenges[index].progress = min(challenges[index].target, challenges[index].progress + delta)
    }
}

@MainActor
final class MealPlanStore: ObservableObject {
    @Published private(set) var currentPlan: MealPlan?

    private let engine: MealPlanningEngine
    private let recipeStore: RecipeStore
    private let shoppingListStore: ShoppingListStore

    init(engine: MealPlanningEngine, recipeStore: RecipeStore, shoppingListStore: ShoppingListStore) {
        self.engine = engine
        self.recipeStore = recipeStore
        self.shoppingListStore = shoppingListStore
    }

    func refreshPlanIfNeeded(force: Bool = false) async {
        if !force, let plan = currentPlan, Calendar.current.isDateInToday(plan.weekOf) {
            return
        }

        let plan = await engine.generatePlan()
        currentPlan = plan
        let items = await engine.buildShoppingList(from: plan)
        shoppingListStore.setItems(items)
    }

    func applySubstitution(for mealId: UUID, ingredientID: UUID, replacement: Ingredient) {
        guard var plan = currentPlan else { return }
        for dayIndex in plan.days.indices {
            for mealIndex in plan.days[dayIndex].meals.indices where plan.days[dayIndex].meals[mealIndex].id == mealId {
                var recipe = plan.days[dayIndex].meals[mealIndex].recipe
                if let ingredientIndex = recipe.ingredients.firstIndex(where: { $0.id == ingredientID }) {
                    recipe.ingredients[ingredientIndex] = replacement
                    plan.days[dayIndex].meals[mealIndex].recipe = recipe
                }
            }
        }
        currentPlan = plan
        Task {
            let items = await engine.buildShoppingList(from: plan)
            await MainActor.run {
                shoppingListStore.setItems(items)
            }
        }
    }
}
