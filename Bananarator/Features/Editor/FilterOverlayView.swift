import SwiftUI

struct FilterOverlayView: View {
    let filter: FilterItem

    var body: some View {
        Image(filter.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
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
                    imageName: nil,
                    name: "None",
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
                        imageName: filter.imageName,
                        name: filter.name,
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
    let imageName: String?
    let name: String
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BananaTheme.cream)

                    if let imageName = imageName, UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else if imageName == nil {
                        Image(systemName: "nosign")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(Color.dapperBrown.opacity(0.55))
                    } else {
                        BananaPlaceholderArt(symbol: "camera.filters", tint: .partyPurple, size: 52)
                    }

                    if isLocked {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.5))
                        GlowingLock(size: 18)
                    }
                }
                .frame(width: 68, height: 68)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.bananaYellow : Color.white,
                                lineWidth: isSelected ? 4 : 2)
                )
                .bananaShadow(BananaTheme.softShadow)

                Text(name)
                    .font(BananaTheme.caption(11))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
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
