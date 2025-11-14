import SwiftUI
import Combine
#if canImport(Charts)
import Charts
#endif

final class PlanDashboardViewModel: ObservableObject {
    @Published private(set) var plan: MealPlan?
    @Published private(set) var tasteSummary: String = ""
    @Published var isLoading: Bool = false

    private let mealPlanStore: MealPlanStore
    private let feedbackLoop: FeedbackLoop
    private var cancellables = Set<AnyCancellable>()

    init(
        mealPlanStore: MealPlanStore,
        feedbackLoop: FeedbackLoop
    ) {
        self.mealPlanStore = mealPlanStore
        self.feedbackLoop = feedbackLoop

        mealPlanStore.$currentPlan
            .receive(on: DispatchQueue.main)
            .assign(to: &$plan)

        NotificationCenter.default.publisher(for: .tasteProfileUpdated)
            .compactMap { $0.object as? PreferenceProfile }
            .map { profile in
                profile.tasteScores.sorted { $0.score > $1.score }
                    .map { "\($0.cuisine) \(Int($0.score * 100))%" }
                    .joined(separator: ", ")
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$tasteSummary)
    }

    @MainActor
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        await mealPlanStore.refreshPlanIfNeeded(force: true)
    }

    func submit(feedback type: FeedbackEvent.FeedbackType, mealId: UUID) {
        Task {
            let feedback = FeedbackEvent(mealId: mealId, type: type, comment: nil)
            await feedbackLoop.submit(feedback: feedback)
        }
    }
}

struct PlanDashboardView: View {
    @ObservedObject var viewModel: PlanDashboardViewModel

    var body: some View {
        VStack {
            if let plan = viewModel.plan {
                planView(plan)
            } else {
                ProgressView("Generating plan…")
                    .task {
                        await viewModel.refresh()
                    }
            }
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func planView(_ plan: MealPlan) -> some View {
        List {
            if !viewModel.tasteSummary.isEmpty {
                Section("Taste profile") {
                    Text(viewModel.tasteSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(plan.days) { day in
                Section(dateFormatter.string(from: day.date)) {
                    macroSummary(day)
                    ForEach(day.meals) { meal in
                        NavigationLink(destination: RecipeDetailView(recipe: meal.recipe)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.recipe.title).font(.headline)
                                Text(meal.recipe.summary).font(.subheadline).foregroundStyle(.secondary)
                                feedbackChips(for: meal)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func macroSummary(_ day: MealDay) -> some View {
        VStack(alignment: .leading) {
            Text("Daily macros").font(.subheadline).foregroundStyle(.secondary)
#if canImport(Charts)
            Chart {
                BarMark(
                    x: .value("Macro", "Calories"),
                    y: .value("Value", day.macroSummary.calories)
                )
                BarMark(
                    x: .value("Macro", "Protein"),
                    y: .value("Value", day.macroSummary.protein)
                )
                BarMark(
                    x: .value("Macro", "Carbs"),
                    y: .value("Value", day.macroSummary.carbs)
                )
                BarMark(
                    x: .value("Macro", "Fats"),
                    y: .value("Value", day.macroSummary.fats)
                )
            }
            .frame(height: 120)
#else
            HStack {
                macroTile("Calories", value: day.macroSummary.calories)
                macroTile("Protein", value: day.macroSummary.protein)
                macroTile("Carbs", value: day.macroSummary.carbs)
                macroTile("Fats", value: day.macroSummary.fats)
            }
#endif
        }
    }

    private func macroTile(_ title: String, value: Double) -> some View {
        VStack {
            Text(title).font(.caption)
            Text(value.formatted(.number.precision(.fractionLength(0))))
                .font(.headline)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func feedbackChips(for meal: Meal) -> some View {
        HStack {
            Button("Loved it") {
                viewModel.submit(feedback: .lovedIt, mealId: meal.id)
            }
            .buttonStyle(.borderedProminent)
            Button("Too many carbs") {
                viewModel.submit(feedback: .tooManyCarbs, mealId: meal.id)
            }
            .buttonStyle(.bordered)
        }
        .font(.caption)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
}
