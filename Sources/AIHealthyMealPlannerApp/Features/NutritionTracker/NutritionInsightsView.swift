import SwiftUI
import Combine

final class NutritionInsightsViewModel: ObservableObject {
    @Published private(set) var entries: [NutritionLogEntry] = []
    @Published private(set) var todaysSummary: MacroBreakdown = .zero

    private let nutritionStore: NutritionLogStore
    private let healthKitManager: HealthKitManager

    init(nutritionStore: NutritionLogStore, healthKitManager: HealthKitManager) {
        self.nutritionStore = nutritionStore
        self.healthKitManager = healthKitManager

        nutritionStore.$entries
            .receive(on: DispatchQueue.main)
            .assign(to: &$entries)
    }

    func refreshHealthData() {
        Task {
            todaysSummary = await healthKitManager.fetchDailySummary()
        }
    }
}

struct NutritionInsightsView: View {
    @ObservedObject var viewModel: NutritionInsightsViewModel

    var body: some View {
        List {
            Section("Today") {
                macroRow("Calories", value: viewModel.todaysSummary.calories, unit: "kcal")
                macroRow("Protein", value: viewModel.todaysSummary.protein, unit: "g")
                macroRow("Carbs", value: viewModel.todaysSummary.carbs, unit: "g")
                macroRow("Fats", value: viewModel.todaysSummary.fats, unit: "g")
            }

            Section("Recent logs") {
                ForEach(viewModel.entries) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.consumedAt, style: .date)
                        Text("Calories \(entry.macros.calories, specifier: "%.0f")").font(.subheadline)
                        if let energy = entry.energyLevel {
                            Text("Energy \(energy, specifier: "%.1f")/10").font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.refreshHealthData()
                } label: {
                    Image(systemName: "waveform.path.ecg.rectangle")
                }
            }
        }
        .onAppear {
            viewModel.refreshHealthData()
        }
    }

    private func macroRow(_ title: String, value: Double, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value, specifier: "%.0f") \(unit)")
                .font(.headline)
        }
    }
}
