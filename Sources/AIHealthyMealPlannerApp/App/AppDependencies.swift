import Foundation

@MainActor
struct AppDependencies {
    let persistence: PersistenceController
    let profileStore: ProfileStore
    let preferenceStore: PreferenceProfileStore
    let mealPlanStore: MealPlanStore
    let recipeStore: RecipeStore
    let pantryStore: PantryStore
    let shoppingListStore: ShoppingListStore
    let nutritionStore: NutritionLogStore
    let feedbackStore: FeedbackStore
    let gamificationStore: GamificationStore

    let mealPlanningEngine: MealPlanningEngine
    let feedbackLoop: FeedbackLoop
    let syncService: CloudSyncService
    let healthKit: HealthKitManager

    init() {
        let persistence = PersistenceController()
        let profileStore = ProfileStore()
        let preferenceStore = PreferenceProfileStore()
        let recipeStore = RecipeStore()
        let pantryStore = PantryStore()
        let shoppingListStore = ShoppingListStore()
        let nutritionStore = NutritionLogStore()
        let feedbackStore = FeedbackStore()
        let gamificationStore = GamificationStore()
        let healthKit = HealthKitManager()

        let mealPlanningEngine = MealPlanningEngine(
            preferenceStore: preferenceStore,
            profileStore: profileStore,
            pantryStore: pantryStore
        )

        let mealPlanStore = MealPlanStore(
            engine: mealPlanningEngine,
            recipeStore: recipeStore,
            shoppingListStore: shoppingListStore
        )

        let feedbackLoop = FeedbackLoop(
            feedbackStore: feedbackStore,
            mealPlanStore: mealPlanStore,
            preferenceStore: preferenceStore
        )

        let syncService = CloudSyncService(
            profileStore: profileStore,
            mealPlanStore: mealPlanStore,
            preferenceStore: preferenceStore,
            feedbackStore: feedbackStore
        )

        self.persistence = persistence
        self.profileStore = profileStore
        self.preferenceStore = preferenceStore
        self.mealPlanStore = mealPlanStore
        self.recipeStore = recipeStore
        self.pantryStore = pantryStore
        self.shoppingListStore = shoppingListStore
        self.nutritionStore = nutritionStore
        self.feedbackStore = feedbackStore
        self.gamificationStore = gamificationStore
        self.mealPlanningEngine = mealPlanningEngine
        self.feedbackLoop = feedbackLoop
        self.syncService = syncService
        self.healthKit = healthKit
    }

    // MARK: - ViewModel factories

    func onboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(profileStore: profileStore, preferenceStore: preferenceStore)
    }

    func planDashboardViewModel() -> PlanDashboardViewModel {
        PlanDashboardViewModel(
            mealPlanStore: mealPlanStore,
            feedbackLoop: feedbackLoop
        )
    }

    func shoppingListViewModel() -> ShoppingListViewModel {
        ShoppingListViewModel(
            shoppingListStore: shoppingListStore,
            planStore: mealPlanStore
        )
    }

    func nutritionInsightsViewModel() -> NutritionInsightsViewModel {
        NutritionInsightsViewModel(
            nutritionStore: nutritionStore,
            healthKitManager: healthKit
        )
    }

    func challengeCenterViewModel() -> ChallengeCenterViewModel {
        ChallengeCenterViewModel(store: gamificationStore)
    }
}
