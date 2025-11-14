import SwiftUI
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var favoriteCuisinesText: String = ""
    @Published var allergyText: String = ""

    private let profileStore: ProfileStore
    private let preferenceStore: PreferenceProfileStore

    init(profileStore: ProfileStore, preferenceStore: PreferenceProfileStore) {
        self.profileStore = profileStore
        self.preferenceStore = preferenceStore
        self.profile = profileStore.profile
        self.favoriteCuisinesText = profile.favoriteCuisines.joined(separator: ", ")
        self.allergyText = profile.allergies.joined(separator: ", ")
    }

    func saveProfile() {
        profile.favoriteCuisines = favoriteCuisinesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        profile.allergies = allergyText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        profileStore.update { current in
            current = profile
        }
        preferenceStore.seedTasteScores(from: profile.favoriteCuisines)
    }
}

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("First name", text: $viewModel.profile.firstName)
                    Stepper(value: $viewModel.profile.age, in: 16...90) {
                        Label("Age: \(viewModel.profile.age)", systemImage: "person.fill")
                    }
                    Stepper(value: $viewModel.profile.weight, in: 40...200, step: 1) {
                        Text("Weight \(Int(viewModel.profile.weight)) kg")
                    }
                    Stepper(value: $viewModel.profile.height, in: 120...220, step: 1) {
                        Text("Height \(Int(viewModel.profile.height)) cm")
                    }
                }

                Section("Preferences") {
                    Picker("Diet", selection: Binding(
                        get: { viewModel.profile.dietaryPreferences.first ?? .omnivore },
                        set: { viewModel.profile.dietaryPreferences = [$0] }
                    )) {
                        ForEach(DietaryPreference.allCases) { pref in
                            Text(pref.rawValue.capitalized).tag(pref)
                        }
                    }
                    TextField("Favorite cuisines (comma separated)", text: $viewModel.favoriteCuisinesText)
                    TextField("Allergies (comma separated)", text: $viewModel.allergyText)
                }

                Section("Goals") {
                    TextField("Goals (lose weight, gain muscle, etc.)", text: Binding(
                        get: { viewModel.profile.goals.joined(separator: ", ") },
                        set: { newValue in
                            viewModel.profile.goals = newValue.split(separator: ",").map {
                                $0.trimmingCharacters(in: .whitespaces)
                            }
                        }
                    ))
                    Slider(value: $viewModel.profile.activityLevel, in: 1.0...1.8, step: 0.1) {
                        Text("Activity")
                    }
                    Text("Activity multiplier \(viewModel.profile.activityLevel, specifier: "%.1f")")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveProfile()
                        dismiss()
                    }.disabled(viewModel.profile.firstName.isEmpty)
                }
            }
        }
    }
}
