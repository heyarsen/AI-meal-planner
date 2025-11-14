import SwiftUI

@main
struct AIHealthyMealPlannerApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView()
                .environmentObject(appViewModel)
                .task {
                    await appViewModel.bootstrap()
                }
        }
    }
}

final class AppViewModel: ObservableObject {
    @Published private(set) var dependencies: AppDependencies

    init(dependencies: AppDependencies = AppDependencies()) {
        self.dependencies = dependencies
    }

    @MainActor
    func bootstrap() async {
        await dependencies.persistence.setup()
        await dependencies.healthKit.requestAuthorization()
        await dependencies.syncService.initialize()
        await dependencies.mealPlanStore.refreshPlanIfNeeded()
    }
}

struct RootCoordinatorView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                PlanDashboardView(viewModel: appViewModel.dependencies.planDashboardViewModel())
            }
            .tabItem {
                Label("Plan", systemImage: "calendar")
            }
            .tag(0)

            NavigationStack {
                ShoppingListView(viewModel: appViewModel.dependencies.shoppingListViewModel())
            }
            .tabItem {
                Label("Shop", systemImage: "cart")
            }
            .tag(1)

            NavigationStack {
                NutritionInsightsView(viewModel: appViewModel.dependencies.nutritionInsightsViewModel())
            }
            .tabItem {
                Label("Track", systemImage: "chart.bar.fill")
            }
            .tag(2)

            NavigationStack {
                ChallengeCenterView(viewModel: appViewModel.dependencies.challengeCenterViewModel())
            }
            .tabItem {
                Label("Play", systemImage: "flag.checkered")
            }
            .tag(3)
        }
        .sheet(isPresented: .constant(appViewModel.dependencies.profileStore.profile.isEmpty)) {
            OnboardingView(viewModel: appViewModel.dependencies.onboardingViewModel())
        }
    }
}
