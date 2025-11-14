import SwiftUI
import Combine

final class ChallengeCenterViewModel: ObservableObject {
    @Published private(set) var challenges: [Challenge] = []

    private let store: GamificationStore

    init(store: GamificationStore) {
        self.store = store

        store.$challenges
            .receive(on: DispatchQueue.main)
            .assign(to: &$challenges)
    }

    func increment(_ challenge: Challenge) {
        store.updateProgress(for: challenge.id, delta: 1)
    }
}

struct ChallengeCenterView: View {
    @ObservedObject var viewModel: ChallengeCenterViewModel

    var body: some View {
        List {
            ForEach(viewModel.challenges) { challenge in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(challenge.title).font(.headline)
                        Spacer()
                        Text(challenge.rewardBadge).padding(6).background(Color.accentColor.opacity(0.2), in: Capsule())
                    }
                    Text(challenge.description).font(.subheadline)
                    ProgressView(value: Double(challenge.progress), total: Double(challenge.target))
                    HStack {
                        Text("\(challenge.progress)/\(challenge.target)")
                        Spacer()
                        Button("Add progress") {
                            viewModel.increment(challenge)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Challenges")
    }
}
