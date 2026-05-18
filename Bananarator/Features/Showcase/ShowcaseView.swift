import SwiftUI
import FirebaseAuth

struct ShowcaseView: View {
    @StateObject private var viewModel = ShowcaseViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                BananaTheme.partyRadial.ignoresSafeArea()
                ConfettiBackground(showsGradient: false, density: 0.4)
                    .opacity(0.55)

                ScrollView {
                    VStack(spacing: 22) {
                        BananaBanner("SHOWCASE", subtitle: "Today's freshest bananas")
                            .padding(.top, 4)

                        if let featured = viewModel.featuredPost {
                            FeaturedBananaCard(post: featured) {
                                upvote(featured)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Tab picker styled as chunky toggle
                        BananaTabToggle(
                            selection: $viewModel.selectedTab,
                            options: ShowcaseViewModel.ShowcaseTab.allCases
                        )
                        .padding(.horizontal, 16)

                        switch viewModel.selectedTab {
                        case .recent: recentPostsGrid
                        case .top:    topPostsGrid
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showLeaderboard = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(Color.dapperBrown)
                            .padding(8)
                            .background(Circle().fill(Color.bananaYellow))
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .bananaShadow(BananaTheme.softShadow)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showLeaderboard) {
                LeaderboardView(topPosts: viewModel.topPosts)
            }
            .task {
                await viewModel.loadInitial()
            }
        }
    }

    private var recentPostsGrid: some View {
        LazyVStack(spacing: 18) {
            ForEach(viewModel.posts) { post in
                BananaCard(
                    post: post,
                    onUpvote: { upvote(post) },
                    onReport: { report(post) }
                )
                .padding(.horizontal, 16)
                .onAppear {
                    if post.id == viewModel.posts.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            }
        }
    }

    private var topPostsGrid: some View {
        LazyVStack(spacing: 18) {
            ForEach(viewModel.topPosts) { post in
                BananaCard(
                    post: post,
                    onUpvote: { upvote(post) },
                    onReport: { report(post) }
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private func upvote(_ post: BananaPost) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            await viewModel.upvote(post, userId: userId)
        }
    }

    private func report(_ post: BananaPost) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            await viewModel.reportPost(post, userId: userId, reason: "inappropriate")
        }
    }
}

// MARK: - Chunky tab toggle (replaces segmented picker)

struct BananaTabToggle<Option: Hashable & RawRepresentable>: View where Option.RawValue == String {
    @Binding var selection: Option
    let options: [Option]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(BananaTheme.heading(15))
                        .foregroundStyle(selected ? Color.white : Color.dapperBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selected ? AnyShapeStyle(BananaTheme.pinkPurple)
                                                : AnyShapeStyle(Color.clear))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            Capsule().fill(BananaTheme.cream)
                .overlay(Capsule().stroke(Color.white, lineWidth: 3))
        )
        .bananaShadow(BananaTheme.softShadow)
    }
}

struct LeaderboardView: View {
    let topPosts: [BananaPost]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BananaTheme.partyRadial.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(topPosts.enumerated()), id: \.element.id) { index, post in
                            leaderboardRow(index: index, post: post)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                        .font(BananaTheme.body(15))
                }
            }
        }
    }

    private func leaderboardRow(index: Int, post: BananaPost) -> some View {
        HStack(spacing: 14) {
            // Rank medallion
            ZStack {
                Circle()
                    .fill(rankColor(for: index))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))

                Text("\(index + 1)")
                    .font(BananaTheme.title(20))
                    .foregroundStyle(.white)
            }
            .bananaShadow(BananaTheme.softShadow)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(post.username)")
                    .font(BananaTheme.heading(16))
                    .foregroundStyle(Color.dapperBrown)

                Text("\(post.upvotes) upvotes")
                    .font(BananaTheme.caption(12))
                    .foregroundStyle(Color.dapperBrown.opacity(0.7))
            }

            Spacer()

            if index == 0 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Color.bananaYellow)
                    .shadow(color: Color.dapperBrown.opacity(0.4), radius: 0, x: 0, y: 2)
            }
        }
        .bananaCard(borderColor: index == 0 ? .bananaYellow : nil, borderWidth: 4)
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .bananaYellow
        case 1: return .partyBlue
        case 2: return .partyPurple
        default: return .partyPink
        }
    }
}

#Preview {
    ShowcaseView()
        .environmentObject(AppState())
}
