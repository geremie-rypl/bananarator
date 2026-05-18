import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel: EditorViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let onDismiss: () -> Void

    @State private var showShareSheet = false
    @State private var exportResult: ExportService.ExportResult?

    init(baseImage: UIImage, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditorViewModel(baseImage: baseImage))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            BananaTheme.partyRadial.ignoresSafeArea()
            ConfettiBackground(showsGradient: false, density: 0.5)
                .opacity(0.55)

            VStack(spacing: 0) {
                toolbar
                canvas
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showStickerPicker) {
            StickerPickerView { asset in
                viewModel.addSticker(asset)
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showShareSheet) {
            if let result = exportResult {
                ShareSheet(image: result.cleanImage) {
                    appState.onShare()
                }
            }
        }
        .overlay {
            if viewModel.isExporting {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Exporting…")
                            .font(BananaTheme.body(15))
                            .foregroundStyle(.white)
                    }
                    .padding(28)
                    .bananaCard(fill: BananaTheme.dapperBrown.opacity(0.85), padding: 0)
                }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(BananaCircleButtonStyle(tint: .red, size: 44))

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(BananaCircleButtonStyle(tint: .blue, size: 44))
                .opacity(viewModel.canUndo ? 1 : 0.35)
                .disabled(!viewModel.canUndo)

                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .buttonStyle(BananaCircleButtonStyle(tint: .blue, size: 44))
                .opacity(viewModel.canRedo ? 1 : 0.35)
                .disabled(!viewModel.canRedo)
            }

            Spacer()

            Button {
                Task {
                    if let result = await viewModel.exportImages() {
                        exportResult = result
                        showShareSheet = true
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(BananaCircleButtonStyle(tint: .green, size: 44))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle().fill(BananaTheme.dapperBrown.opacity(0.45))
                )
                .ignoresSafeArea(edges: .top)
        )
    }

    private var canvas: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Base image
                Image(uiImage: viewModel.baseImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Layer 2: Filter overlay
                if let filter = viewModel.selectedFilter {
                    FilterOverlayView(filter: filter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Layer 3: Stickers
                ForEach($viewModel.stickers) { $sticker in
                    StickerView(
                        sticker: $sticker,
                        isSelected: viewModel.selectedStickerId == sticker.id,
                        onSelect: {
                            viewModel.selectSticker(sticker.id)
                        },
                        onDelete: {
                            viewModel.deleteSelectedSticker()
                        },
                        onBringToFront: {
                            viewModel.bringToFront(sticker.id)
                        }
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectSticker(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Filter picker (horizontal strip)
            FilterPickerView(
                filters: viewModel.availableFilters.filter { !$0.isSecret || appState.isContentUnlocked($0.id) },
                selectedFilter: viewModel.selectedFilter,
                onSelect: { filter in
                    viewModel.selectFilter(filter)
                }
            )
            .environmentObject(appState)

            // Big action buttons
            HStack(spacing: 28) {
                Button {
                    viewModel.showStickerPicker = true
                } label: {
                    Image(systemName: "face.smiling")
                }
                .buttonStyle(BananaCircleButtonStyle(tint: .purple, size: 64))

                if viewModel.selectedStickerId != nil {
                    Button {
                        viewModel.deleteSelectedSticker()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(BananaCircleButtonStyle(tint: .red, size: 64))
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    Task {
                        if let result = await viewModel.exportImages() {
                            exportResult = result
                            showShareSheet = true
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(BananaCircleButtonStyle(tint: .green, size: 64))
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: viewModel.selectedStickerId)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(BananaTheme.dapperBrown.opacity(0.45)))
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onShare: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onShare()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EditorView(baseImage: UIImage(systemName: "photo")!, onDismiss: {})
        .environmentObject(AppState())
}
