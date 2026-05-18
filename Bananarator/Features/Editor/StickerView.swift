import SwiftUI

struct StickerView: View {
    @Binding var sticker: StickerState
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onBringToFront: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        Image(sticker.asset.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .scaleEffect(sticker.transform.scale * currentScale)
            .rotationEffect(sticker.transform.rotation + currentRotation)
            .offset(
                x: sticker.transform.position.x + dragOffset.width,
                y: sticker.transform.position.y + dragOffset.height
            )
            .overlay(
                isSelected ? selectionOverlay : nil
            )
            .gesture(combinedGesture)
            .onTapGesture {
                onSelect()
                onBringToFront()
            }
            .zIndex(Double(sticker.zIndex))
    }

    private var selectionOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.bannerRed))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .bananaShadow(BananaTheme.softShadow)
                }
            }
            Spacer()
        }
        .frame(width: 100 * sticker.transform.scale, height: 100 * sticker.transform.scale)
    }

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            SimultaneousGesture(dragGesture, magnificationGesture),
            rotationGesture
        )
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                sticker.transform.position.x += value.translation.width
                sticker.transform.position.y += value.translation.height
                dragOffset = .zero
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = value
            }
            .onEnded { value in
                sticker.transform.scale *= value
                sticker.transform.scale = max(0.3, min(3.0, sticker.transform.scale))
                currentScale = 1.0
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = value
            }
            .onEnded { value in
                sticker.transform.rotation += value
                currentRotation = .zero
            }
    }
}

struct StickerPickerView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (StickerAsset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BananaTheme.partyRadial.ignoresSafeArea()
                ConfettiBackground(showsGradient: false, density: 0.55)
                    .opacity(0.5)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(availablePacks) { pack in
                            stickerPackSection(pack)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Sticker Drawer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(BananaTheme.body(15))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var availablePacks: [StickerPack] {
        StickerPack.all.filter { pack in
            !pack.isSecret || appState.isContentUnlocked(pack.id)
        }
    }

    private func stickerPackSection(_ pack: StickerPack) -> some View {
        let isLocked = !pack.isFree && !appState.isContentUnlocked(pack.id)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(pack.name)
                    .font(BananaTheme.title(22))
                    .foregroundStyle(Color.dapperBrown)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(BananaTheme.pinkPurple))
                }

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 84), spacing: 14)
            ], spacing: 14) {
                ForEach(pack.stickers) { sticker in
                    StickerThumbnail(
                        sticker: sticker,
                        isLocked: isLocked
                    ) {
                        if !isLocked {
                            onSelect(sticker)
                            dismiss()
                        }
                    }
                }
            }
        }
        .padding(16)
        .bananaCard(borderColor: isLocked ? .partyPurple : .partyPink,
                    borderWidth: 4, padding: 0)
    }
}

struct StickerThumbnail: View {
    let sticker: StickerAsset
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BananaTheme.cream)

                if UIImage(named: sticker.imageName) != nil {
                    Image(sticker.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                } else {
                    BananaPlaceholderArt(symbol: "sparkles", tint: .partyPink, size: 56)
                }

                if isLocked {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                    GlowingLock(size: 22)
                }
            }
            .frame(width: 76, height: 76)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            )
            .bananaShadow(BananaTheme.softShadow)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StickerPickerView(onSelect: { _ in })
        .environmentObject(AppState())
}
