import SwiftUI

struct BananaCard: View {
    let post: BananaPost
    let onUpvote: () -> Void
    let onReport: () -> Void

    @State private var isRevealed = false
    @State private var showReportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image with blur overlay
            ZStack {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(BananaTheme.cream)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView().tint(.partyPink))

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: isRevealed ? 0 : 22)

                    case .failure:
                        Rectangle()
                            .fill(BananaTheme.cream)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                BananaPlaceholderArt(symbol: "photo", tint: .partyPurple, size: 60)
                            )

                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white, lineWidth: 4)
                )

                if !isRevealed {
                    VStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(Color.white)

                        Text("Tap to reveal")
                            .font(BananaTheme.body(13))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(BananaTheme.pinkPurple))
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRevealed.toggle()
                }
            }

            // Post info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.username)")
                        .font(BananaTheme.heading(15))
                        .foregroundStyle(Color.dapperBrown)

                    HStack(spacing: 6) {
                        if let filter = post.filterUsed {
                            Label(filter, systemImage: "camera.filters")
                                .font(BananaTheme.caption(11))
                                .foregroundStyle(Color.partyPurple)
                        }

                        if post.stickerCount > 0 {
                            Label("\(post.stickerCount)", systemImage: "face.smiling")
                                .font(BananaTheme.caption(11))
                                .foregroundStyle(Color.partyPink)
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: onUpvote) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.heart.fill")
                            Text("\(post.upvotes)")
                        }
                    }
                    .buttonStyle(BananaChipButtonStyle(tint: .pink, filled: true))

                    Menu {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label("Report", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(Color.dapperBrown.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(BananaTheme.cream))
                    }
                }
            }

            if post.isFeatured {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text("Featured")
                }
                .font(BananaTheme.caption(12))
                .foregroundStyle(Color.dapperBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(BananaTheme.bananaYellow))
                .overlay(Capsule().stroke(Color.white, lineWidth: 2))
            }
        }
        .bananaCard(borderColor: post.isFeatured ? .bananaYellow : .partyPink,
                    borderWidth: 4)
        .confirmationDialog("Report Post", isPresented: $showReportSheet) {
            Button("Inappropriate Content", role: .destructive) { onReport() }
            Button("Spam", role: .destructive) { onReport() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FeaturedBananaCard: View {
    let post: BananaPost
    let onUpvote: () -> Void

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color.dapperBrown)
                Text("TODAY'S FEATURED")
                    .font(BananaTheme.heading(14))
                    .foregroundStyle(Color.dapperBrown)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(BananaTheme.bananaYellow))
            .overlay(Capsule().stroke(Color.white, lineWidth: 3))
            .bananaShadow(BananaTheme.softShadow)

            ZStack {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: isRevealed ? 0 : 22)
                    } else {
                        Rectangle()
                            .fill(BananaTheme.cream)
                            .overlay(BananaPlaceholderArt(symbol: "sparkles",
                                                         tint: .partyPink, size: 80))
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white, lineWidth: 4)
                )

                if !isRevealed {
                    Text("Tap to reveal")
                        .font(BananaTheme.body(14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(BananaTheme.pinkPurple))
                        .overlay(Capsule().stroke(Color.white, lineWidth: 2))
                }
            }
            .onTapGesture {
                withAnimation { isRevealed.toggle() }
            }

            HStack {
                Text("@\(post.username)")
                    .font(BananaTheme.heading(15))
                    .foregroundStyle(Color.dapperBrown)

                Spacer()

                Button(action: onUpvote) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.heart.fill")
                        Text("\(post.upvotes)")
                    }
                }
                .buttonStyle(BananaChipButtonStyle(tint: .pink, filled: true))
            }
        }
        .bananaCard(gradient: LinearGradient(
            colors: [Color.bananaYellow.opacity(0.55), Color.partyPink.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ), borderColor: .bananaYellow, borderWidth: 4)
    }
}

#Preview {
    ZStack {
        BananaTheme.partyRadial.ignoresSafeArea()
        VStack {
            BananaCard(
                post: BananaPost(
                    userId: "123",
                    username: "bananafan",
                    imageURL: "https://example.com/image.jpg",
                    filterUsed: "Neon Dreams",
                    stickerCount: 3,
                    upvotes: 42,
                    createdAt: Date(),
                    isFeatured: false
                ),
                onUpvote: {},
                onReport: {}
            )
        }
        .padding()
    }
}
