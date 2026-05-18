import SwiftUI
import UIKit

// MARK: - SocialShareSheet
/// Custom bottom-sheet replacement for the bare `UIActivityViewController`. Presents
/// destination buttons (Save, IG Stories, Snapchat, Copy, More) on top of the
/// existing banana visual language.
struct SocialShareSheet: View {
    let exportResult: ExportService.ExportResult
    let onComplete: (ShareDestination) -> Void

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var toastMessage: String?
    @State private var showSettingsAlert = false
    @State private var settingsAlertMessage = ""
    @State private var showFallbackShareSheet = false

    private let haptics = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()

    private let shareText = "Made with Bananarator 🍌"

    var body: some View {
        ZStack {
            BananaTheme.partyRadial.ignoresSafeArea()
            ConfettiBackground(showsGradient: false, density: 0.4)
                .opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                handle

                Text("Share your masterpiece")
                    .font(BananaTheme.heading(22))
                    .foregroundStyle(.white)

                Image(uiImage: exportResult.cleanImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .bananaShadow(BananaTheme.cardShadow)
                    .padding(.horizontal, 24)

                destinationGrid

                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)

            if let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(BananaTheme.body(15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(BananaTheme.dapperBrown.opacity(0.92))
                        )
                        .bananaShadow(BananaTheme.softShadow)
                        .padding(.bottom, 44)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .alert("Photo access needed", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(settingsAlertMessage)
        }
        .sheet(isPresented: $showFallbackShareSheet) {
            ActivityViewControllerRepresentable(
                image: exportResult.cleanImage,
                text: shareText,
                onComplete: { completed in
                    if completed {
                        recordShare(.shareSheet)
                    }
                }
            )
        }
    }

    // MARK: Layout

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 44, height: 5)
    }

    private var destinationGrid: some View {
        VStack(spacing: 20) {
            HStack(spacing: 22) {
                destinationButton(
                    title: "Save",
                    systemImage: "square.and.arrow.down.fill",
                    tint: .green
                ) {
                    Task { await handleSave() }
                }

                destinationButton(
                    title: "Stories",
                    systemImage: "camera.fill",
                    tint: .purple
                ) {
                    Task { await handleInstagramStories() }
                }

                destinationButton(
                    title: "Snapchat",
                    systemImage: "bolt.fill",
                    tint: .yellow
                ) {
                    Task { await handleSnapchat() }
                }
            }

            HStack(spacing: 22) {
                destinationButton(
                    title: "Copy",
                    systemImage: "doc.on.doc.fill",
                    tint: .blue
                ) {
                    handleCopy()
                }

                destinationButton(
                    title: "More",
                    systemImage: "ellipsis",
                    tint: .pink
                ) {
                    showFallbackShareSheet = true
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func destinationButton(
        title: String,
        systemImage: String,
        tint: BananaCircleButtonStyle.Tint,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Button {
                action()
            } label: {
                Image(systemName: systemImage)
            }
            .buttonStyle(BananaCircleButtonStyle(tint: tint, size: 64))

            Text(title)
                .font(BananaTheme.caption(13))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Handlers

    private func handleSave() async {
        let result = await SocialShareService.shared.saveToPhotos(exportResult.cleanImage)
        switch result {
        case .success:
            notification.notificationOccurred(.success)
            showToast("Saved to Photos 🍌")
            recordShare(.savePhotos)
        case .failure(.openSettingsRequired):
            settingsAlertMessage = "Bananarator needs permission to save to your Photos library. Open Settings to enable it."
            showSettingsAlert = true
        case .failure:
            showToast("Couldn't save. Try again.")
        }
    }

    private func handleInstagramStories() async {
        let result = await SocialShareService.shared.shareToInstagramStories(exportResult.cleanImage)
        switch result {
        case .success:
            haptics.impactOccurred()
            recordShare(.instagramStories)
        case .failure(.schemeUnavailable):
            // Silent fallback to share sheet.
            showFallbackShareSheet = true
        case .failure:
            showToast("Couldn't open Instagram.")
        }
    }

    private func handleSnapchat() async {
        let result = await SocialShareService.shared.shareToSnapchat(exportResult.cleanImage)
        switch result {
        case .success:
            haptics.impactOccurred()
            recordShare(.snapchat)
        case .failure(.schemeUnavailable):
            showFallbackShareSheet = true
        case .failure(.openSettingsRequired):
            settingsAlertMessage = "Snapchat needs your photo to be saved first. Allow Photos access in Settings."
            showSettingsAlert = true
        case .failure:
            showToast("Couldn't open Snapchat.")
        }
    }

    private func handleCopy() {
        SocialShareService.shared.copyImage(exportResult.cleanImage)
        haptics.impactOccurred()
        showToast("Copied")
        recordShare(.copyImage)
    }

    // MARK: Helpers

    private func recordShare(_ destination: ShareDestination) {
        appState.onShare()
        AnalyticsService.shared.trackShare(platform: destination.analyticsName)
        onComplete(destination)
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }
}

// MARK: - Destination analytics name

private extension ShareDestination {
    var analyticsName: String {
        switch self {
        case .savePhotos:        return "save"
        case .instagramStories:  return "instagram_stories"
        case .snapchat:          return "snapchat"
        case .copyImage:         return "copy"
        case .shareSheet:        return "share_sheet"
        }
    }
}

// MARK: - UIActivityViewController bridge

struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let image: UIImage
    let text: String
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .print
        ]
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
