import Foundation

actor MealPlanningEngine {
    private let preferenceStore: PreferenceProfileStore
    private let profileStore: ProfileStore
    private let pantryStore: PantryStore

    init(
        preferenceStore: PreferenceProfileStore,
        profileStore: ProfileStore,
        pantryStore: PantryStore
    ) {
        self.preferenceStore = preferenceStore
        self.profileStore = profileStore
        self.pantryStore = pantryStore
    }

    func generatePlan() async -> MealPlan {
        let profile = await MainActor.run { profileStore.profile }
        let tasteProfile = await MainActor.run { preferenceStore.profile }

        let weekStart = Calendar.current.startOfDay(for: Date())
        var days: [MealDay] = []
        for offset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let meals = Meal.MealType.allCases.map { type in
                makeMeal(type: type, profile: profile, tasteProfile: tasteProfile)
            }
            let macroSummary = meals.reduce(MacroBreakdown.zero) { partial, meal in
                MacroBreakdown(
                    calories: partial.calories + meal.macros.calories,
                    protein: partial.protein + meal.macros.protein,
                    carbs: partial.carbs + meal.macros.carbs,
                    fats: partial.fats + meal.macros.fats
                )
            }
            days.append(MealDay(date: date, meals: meals, macroSummary: macroSummary))
        }

        return MealPlan(weekOf: weekStart, days: days)
    }

    func buildShoppingList(from plan: MealPlan) -> [ShoppingItem] {
        var ingredients: [UUID: Ingredient] = [:]
        for day in plan.days {
            for meal in day.meals {
                for ingredient in meal.recipe.ingredients {
                    ingredients[ingredient.id] = ingredient
                }
            }
        }

        let pantryItems = pantryStore.items
        let filtered = ingredients.values.filter { ingredient in
            !pantryItems.contains(where: { $0.ingredient.name == ingredient.name })
        }

        return filtered.map { ingredient in
            ShoppingItem(ingredient: ingredient)
        }
    }

    private func makeMeal(type: Meal.MealType, profile: UserProfile, tasteProfile: PreferenceProfile) -> Meal {
        let cuisine = tasteProfile.tasteScores.sorted { $0.score > $1.score }.first?.cuisine ?? profile.favoriteCuisines.first ?? "Fusion"
        let macros = recommendedMacros(for: type, profile: profile)
        let ingredients = sampleIngredients(for: cuisine)
        let recipe = Recipe(
            title: "\(cuisine) \(type.rawValue.capitalized)",
            summary: "A balanced \(type.rawValue) tailored to your goals.",
            prepTimeMinutes: 15,
            cookTimeMinutes: 20,
            difficulty: "Easy",
            ingredients: ingredients,
            steps: [
                "Gather ingredients and prep.",
                "Cook according to instructions.",
                "Plate and enjoy."
            ],
            tags: [cuisine, type.rawValue],
            macroBreakdown: macros,
            satisfactionScore: Double.random(in: 0.5...0.9),
            cuisine: cuisine
        )

        return Meal(type: type, recipe: recipe, portionSize: "1 serving", macros: macros)
    }

    private func recommendedMacros(for type: Meal.MealType, profile: UserProfile) -> MacroBreakdown {
        let baseCalories = 2000.0 * profile.activityLevel
        let split: (Double, Double, Double, Double)
        switch type {
        case .breakfast:
            split = (0.25, 0.25, 0.35, 0.4)
        case .lunch:
            split = (0.3, 0.3, 0.3, 0.4)
        case .dinner:
            split = (0.3, 0.35, 0.25, 0.4)
        case .snack:
            split = (0.15, 0.1, 0.1, 0.2)
        }

        return MacroBreakdown(
            calories: baseCalories * split.0,
            protein: baseCalories / 4 * split.1,
            carbs: baseCalories / 4 * split.2,
            fats: baseCalories / 9 * split.3
        )
    }

    private func sampleIngredients(for cuisine: String) -> [Ingredient] {
        [
            Ingredient(name: "\(cuisine) greens", quantity: 2, unit: "cups", aisle: "Produce"),
            Ingredient(name: "\(cuisine) protein", quantity: 1, unit: "portion", aisle: "Butcher"),
            Ingredient(name: "\(cuisine) carbs", quantity: 1, unit: "cup", aisle: "Grains")
        ]
    }
}
