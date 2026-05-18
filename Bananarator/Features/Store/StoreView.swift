import SwiftUI
import StoreKit

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                BananaTheme.partyRadial.ignoresSafeArea()
                ConfettiBackground(showsGradient: false, density: 0.35)
                    .opacity(0.5)

                ScrollView {
                    VStack(spacing: 22) {
                        BananaBanner("SHOP", subtitle: "Stickers • Filters • Magic")
                            .padding(.top, 4)

                        if !viewModel.hasUnlimitedAccess() {
                            unlimitedBanner
                                .padding(.horizontal, 16)
                        }

                        if !viewModel.filterProducts.isEmpty {
                            productSection(
                                title: "Filters",
                                icon: "camera.filters",
                                tint: .partyPurple,
                                products: viewModel.filterProducts
                            )
                            .padding(.horizontal, 16)
                        }

                        if !viewModel.stickerProducts.isEmpty {
                            productSection(
                                title: "Sticker Packs",
                                icon: "face.smiling",
                                tint: .partyPink,
                                products: viewModel.stickerProducts
                            )
                            .padding(.horizontal, 16)
                        }

                        Button {
                            Task { await viewModel.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                        }
                        .buttonStyle(BananaPillButtonStyle(variant: .secondary))
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadProducts()
            }
            .overlay {
                if viewModel.isLoading || viewModel.isPurchasing {
                    ZStack {
                        Color.black.opacity(0.45).ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
            .alert("Purchase Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var unlimitedBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(BananaTheme.pinkPurple)
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    Image(systemName: "infinity")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }
                .bananaShadow(BananaTheme.softShadow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Unlimited")
                        .font(BananaTheme.title(22))
                        .foregroundStyle(Color.dapperBrown)

                    Text("Unlock all filters & stickers forever")
                        .font(BananaTheme.body(13))
                        .foregroundStyle(Color.dapperBrown.opacity(0.7))
                }

                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(viewModel.subscriptionProducts) { product in
                    SubscriptionButton(product: product) {
                        Task { await viewModel.purchase(product) }
                    }
                }
            }
        }
        .bananaCard(gradient: LinearGradient(
            colors: [Color.bananaYellow.opacity(0.4), Color.partyPink.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ), borderColor: .bananaYellow, borderWidth: 4, padding: 20)
    }

    private func productSection(title: String, icon: String, tint: Color, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tint))
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .bananaShadow(BananaTheme.softShadow)

                Text(title)
                    .font(BananaTheme.title(22))
                    .foregroundStyle(.white)
                    .shadow(color: Color.dapperBrown.opacity(0.45), radius: 0, x: 0, y: 2)

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 14) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        isPurchased: viewModel.isPurchased(product.id),
                        hasUnlimited: viewModel.hasUnlimitedAccess(),
                        tint: tint
                    ) {
                        Task { await viewModel.purchase(product) }
                    }
                }
            }
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    let onPurchase: () -> Void

    private var isBestValue: Bool { product.id == "unlimited.annual" }

    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 6) {
                Text(product.displayName)
                    .font(BananaTheme.body(13))
                    .foregroundStyle(Color.dapperBrown.opacity(0.8))

                Text(product.displayPrice)
                    .font(BananaTheme.title(20))
                    .foregroundStyle(Color.partyPink)

                if isBestValue {
                    Text("BEST VALUE")
                        .font(BananaTheme.caption(10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(BananaTheme.partyGreen))
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isBestValue ? Color.partyGreen : Color.partyPink, lineWidth: 3)
            )
            .bananaShadow(BananaTheme.softShadow)
        }
        .buttonStyle(.plain)
    }
}

struct ProductCard: View {
    let product: Product
    let isPurchased: Bool
    let hasUnlimited: Bool
    var tint: Color = .partyPink
    let onPurchase: () -> Void

    private var isUnlocked: Bool { isPurchased || hasUnlimited }

    private var previewImage: String {
        switch product.id {
        case "filter.futuristic": return "filter_futuristic"
        case "filter.doctor":     return "filter_doctor"
        case "filter.party":      return "filter_party"
        case "filter.galaxy":     return "filter_galaxy"
        case "filter.tropical":   return "filter_tropical"
        case "stickers.fancy":    return "pack_fancy_preview"
        case "stickers.food":     return "pack_food_preview"
        default:                  return "pack_default_preview"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BananaTheme.cream)
                    .frame(height: 110)

                if UIImage(named: previewImage) != nil {
                    Image(previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    BananaPlaceholderArt(
                        symbol: product.id.hasPrefix("filter") ? "camera.filters" : "sparkles",
                        tint: tint,
                        size: 70
                    )
                }

                if isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(BananaTheme.partyGreen))
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                        Spacer()
                    }
                    .padding(8)
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            GlowingLock(size: 16)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            )

            Text(product.displayName)
                .font(BananaTheme.heading(14))
                .foregroundStyle(Color.dapperBrown)
                .lineLimit(1)

            if isUnlocked {
                Text("OWNED")
                    .font(BananaTheme.caption(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(BananaTheme.partyGreen))
            } else {
                Button(action: onPurchase) {
                    Text(product.displayPrice)
                        .font(BananaTheme.body(13))
                }
                .buttonStyle(BananaChipButtonStyle(tint: .pink, filled: true))
            }
        }
        .padding(12)
        .bananaCard(borderColor: isUnlocked ? .partyGreen : tint, borderWidth: 4, padding: 0)
    }
}

#Preview {
    StoreView()
        .environmentObject(AppState())
}
