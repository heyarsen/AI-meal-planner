import SwiftUI
import Combine

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var currentStep: Int = 0
    @State private var timerActive: Bool = false
    @State private var remainingSeconds: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                ingredientList
                stepper
                pantryMode
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard timerActive, remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 { timerActive = false }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.summary)
                .font(.headline)
            HStack {
                Label("\(recipe.prepTimeMinutes) min prep", systemImage: "timer")
                Label(recipe.difficulty, systemImage: "flame")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var ingredientList: some View {
        VStack(alignment: .leading) {
            Text("Ingredients").font(.title3).bold()
            ForEach(recipe.ingredients) { ingredient in
                HStack {
                    Text("\(ingredient.quantity, specifier: "%.0f") \(ingredient.unit)")
                        .monospacedDigit()
                    Text(ingredient.name).bold()
                    Spacer()
                    Text(ingredient.aisle ?? "General").foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var stepper: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps").font(.title3).bold()
            ForEach(recipe.steps.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                    HStack {
                        Text("Step \(index + 1)")
                            .font(.headline)
                        Spacer()
                        Button {
                            startTimer(for: recipe.steps[index])
                            currentStep = index
                        } label: {
                            Label("Start timer", systemImage: "play.circle")
                        }
                    }
                    Text(recipe.steps[index])
                        .padding(.vertical, 4)
                }
                .padding()
                .background(currentStep == index ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if timerActive {
                HStack {
                    Image(systemName: "timer")
                    Text("Timer: \(remainingSeconds) sec").monospacedDigit()
                    Button("Stop") { timerActive = false }
                }
                .padding()
                .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var pantryMode: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pantry substitutions").font(.title3).bold()
            Text("Scan pantry or pick stored inventory to see smart substitutions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                // Hook into barcode scanner / Pantry mode
            } label: {
                Label("Open Pantry Mode", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func startTimer(for step: String) {
        remainingSeconds = estimateSeconds(from: step)
        timerActive = true
    }

    private func estimateSeconds(from step: String) -> Int {
        if step.lowercased().contains("simmer") { return 600 }
        if step.lowercased().contains("rest") { return 300 }
        return 120
    }
}
