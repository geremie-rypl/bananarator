import SwiftUI

struct FilterOverlayView: View {
    let filter: FilterItem

    var body: some View {
        Group {
            if let kind = ProceduralFilterKind(filterId: filter.id) {
                ProceduralFilterOverlay(kind: kind)
            } else {
                Image(filter.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .allowsHitTesting(false)
    }
}

struct FilterPickerView: View {
    @EnvironmentObject var appState: AppState
    let filters: [FilterItem]
    let selectedFilter: FilterItem?
    let onSelect: (FilterItem?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                // No filter option
                FilterThumbnail(
                    filter: nil,
                    isSelected: selectedFilter == nil,
                    isLocked: false
                ) {
                    onSelect(nil)
                }

                ForEach(filters) { filter in
                    let isLocked = !filter.isFree &&
                                   !filter.isSecret &&
                                   !appState.isContentUnlocked(filter.id)

                    FilterThumbnail(
                        filter: filter,
                        isSelected: selectedFilter?.id == filter.id,
                        isLocked: isLocked
                    ) {
                        if !isLocked || appState.isContentUnlocked(filter.id) {
                            onSelect(filter)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .frame(height: 116)
    }
}

struct FilterThumbnail: View {
    let filter: FilterItem?
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    private var displayName: String { filter?.name ?? "None" }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BananaTheme.cream)

                    thumbnailContent

                    if isLocked {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.5))
                        GlowingLock(size: 18)
                    }
                }
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.bananaYellow : Color.white,
                                lineWidth: isSelected ? 4 : 2)
                )
                .bananaShadow(BananaTheme.softShadow)

                Text(displayName)
                    .font(BananaTheme.caption(11))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let filter {
            if let kind = ProceduralFilterKind(filterId: filter.id) {
                ProceduralFilterOverlay(kind: kind)
            } else if UIImage(named: filter.imageName) != nil {
                Image(filter.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                BananaPlaceholderArt(symbol: "camera.filters", tint: .partyPurple, size: 52)
            }
        } else {
            Image(systemName: "nosign")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Color.dapperBrown.opacity(0.55))
        }
    }
}

#Preview {
    ZStack {
        BananaTheme.partyRadial.ignoresSafeArea()
        FilterPickerView(
            filters: FilterItem.all,
            selectedFilter: nil,
            onSelect: { _ in }
        )
        .environmentObject(AppState())
    }
}
