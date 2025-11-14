import SwiftUI
import Combine

final class ShoppingListViewModel: ObservableObject {
    @Published private(set) var items: [ShoppingItem] = []

    private let shoppingListStore: ShoppingListStore
    private let planStore: MealPlanStore

    init(shoppingListStore: ShoppingListStore, planStore: MealPlanStore) {
        self.shoppingListStore = shoppingListStore
        self.planStore = planStore

        shoppingListStore.$items
            .receive(on: DispatchQueue.main)
            .assign(to: &$items)
    }

    func toggle(_ item: ShoppingItem) {
        shoppingListStore.toggle(item.id)
    }

    func exportToReminders() {
        // Hook AppIntents / Reminders integration
    }

    func ensureLatestPlan() {
        Task {
            await planStore.refreshPlanIfNeeded()
        }
    }
}

struct ShoppingListView: View {
    @ObservedObject var viewModel: ShoppingListViewModel

    var body: some View {
        List {
            ForEach(groupedKeys, id: \.self) { aisle in
                Section(aisle) {
                    ForEach(groupedItems[aisle] ?? []) { item in
                        HStack {
                            Button {
                                viewModel.toggle(item)
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading) {
                                Text(item.ingredient.name)
                                Text("\(item.ingredient.quantity, specifier: "%.0f") \(item.ingredient.unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Shopping")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.exportToReminders()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            viewModel.ensureLatestPlan()
        }
    }

    private var groupedItems: [String: [ShoppingItem]] {
        Dictionary(grouping: viewModel.items) { $0.aisle ?? "Other" }
    }

    private var groupedKeys: [String] {
        groupedItems.keys.sorted()
    }
}
