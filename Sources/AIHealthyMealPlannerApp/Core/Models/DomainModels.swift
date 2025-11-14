import Foundation

enum DietaryPreference: String, Codable, CaseIterable, Identifiable {
    case omnivore, vegetarian, vegan, pescatarian, keto, paleo, glutenFree
    var id: String { rawValue }
}

struct PreferenceProfile: Codable, Hashable {
    struct TasteScore: Codable, Hashable {
        var cuisine: String
        var score: Double
    }

    var likedMeals: Set<UUID> = []
    var dislikedMeals: Set<UUID> = []
    var tasteScores: [TasteScore] = []
    var lastUpdated: Date = .init()

    static let empty = PreferenceProfile()
}

struct UserProfile: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var firstName: String = ""
    var age: Int = 30
    var weight: Double = 70
    var height: Double = 170
    var activityLevel: Double = 1.2
    var dietaryPreferences: [DietaryPreference] = [.omnivore]
    var allergies: [String] = []
    var favoriteCuisines: [String] = []
    var goals: [String] = []

    var isEmpty: Bool {
        firstName.isEmpty
    }
}

struct MacroBreakdown: Codable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double

    static let zero = MacroBreakdown(calories: 0, protein: 0, carbs: 0, fats: 0)
}

struct Meal: Codable, Hashable, Identifiable {
    enum MealType: String, Codable, CaseIterable {
        case breakfast, lunch, dinner, snack
    }

    var id: UUID = .init()
    var type: MealType
    var recipe: Recipe
    var portionSize: String
    var macros: MacroBreakdown
}

struct MealDay: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var date: Date
    var meals: [Meal]
    var macroSummary: MacroBreakdown
}

struct MealPlan: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var weekOf: Date
    var days: [MealDay]
    var createdAt: Date = .init()
}

struct Ingredient: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var name: String
    var quantity: Double
    var unit: String
    var aisle: String?
}

struct Recipe: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var title: String
    var summary: String
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var difficulty: String
    var ingredients: [Ingredient]
    var steps: [String]
    var tags: [String]
    var macroBreakdown: MacroBreakdown
    var satisfactionScore: Double = 0
    var cuisine: String
}

struct ShoppingItem: Codable, Hashable, Identifiable {
    enum Source: String, Codable {
        case pantry, list, suggestion
    }

    var id: UUID = .init()
    var ingredient: Ingredient
    var isCompleted: Bool = false
    var source: Source = .list
    var store: String?
    var aisle: String? { ingredient.aisle }
}

struct PantryItem: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var barcode: String?
    var ingredient: Ingredient
    var quantityOnHand: Double
    var expiresOn: Date?
}

struct NutritionLogEntry: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var mealId: UUID
    var consumedAt: Date
    var macros: MacroBreakdown
    var energyLevel: Double?
    var moodNote: String?
}

struct FeedbackEvent: Codable, Hashable, Identifiable {
    enum FeedbackType: String, Codable {
        case thumbsUp, thumbsDown, tooManyCarbs, lovedIt, skip
    }

    var id: UUID = .init()
    var mealId: UUID
    var type: FeedbackType
    var comment: String?
    var createdAt: Date = .init()
}

struct Challenge: Codable, Hashable, Identifiable {
    var id: UUID = .init()
    var title: String
    var description: String
    var target: Int
    var progress: Int
    var rewardBadge: String

    var isCompleted: Bool { progress >= target }
}
