import Foundation
import Combine

final class FeedbackLoop {
    private let feedbackStore: FeedbackStore
    private let mealPlanStore: MealPlanStore
    private let preferenceStore: PreferenceProfileStore

    init(
        feedbackStore: FeedbackStore,
        mealPlanStore: MealPlanStore,
        preferenceStore: PreferenceProfileStore
    ) {
        self.feedbackStore = feedbackStore
        self.mealPlanStore = mealPlanStore
        self.preferenceStore = preferenceStore
    }

    func submit(feedback: FeedbackEvent) async {
        await MainActor.run {
            feedbackStore.record(feedback)
            preferenceStore.applyFeedback(feedback)
        }

        await mealPlanStore.refreshPlanIfNeeded(force: true)
    }
}

actor CloudSyncService {
    private let profileStore: ProfileStore
    private let mealPlanStore: MealPlanStore
    private let preferenceStore: PreferenceProfileStore
    private let feedbackStore: FeedbackStore

    init(
        profileStore: ProfileStore,
        mealPlanStore: MealPlanStore,
        preferenceStore: PreferenceProfileStore,
        feedbackStore: FeedbackStore
    ) {
        self.profileStore = profileStore
        self.mealPlanStore = mealPlanStore
        self.preferenceStore = preferenceStore
        self.feedbackStore = feedbackStore
    }

    func initialize() async {
        // Placeholder for CloudKit/Firebase bootstrap
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    func pullLatestPlan() async {
        await mealPlanStore.refreshPlanIfNeeded(force: true)
    }

    func pushFeedback() async {
        _ = feedbackStore.events
        _ = preferenceStore.profile
    }
}
