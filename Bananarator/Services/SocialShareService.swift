import UIKit
import Photos

// MARK: - Public types

enum ShareDestination {
    case savePhotos
    case instagramStories
    case snapchat
    case copyImage
    case shareSheet
}

enum ShareError: Error {
    case noPermission
    case openSettingsRequired
    case schemeUnavailable
    case exportFailed
}

// MARK: - SocialShareService
/// Routes user-initiated shares to specific destinations. Wraps `ExportService` for
/// pixel logic — this layer only handles permissions, URL schemes, pasteboard, and
/// `UIActivityViewController` construction.
///
/// `@MainActor` because every destination touches `UIPasteboard`,
/// `UIApplication.shared.open(_:)`, or `UIActivityViewController`, all of which
/// are main-thread bound. `ExportService` remains a plain class for the pixel work.
@MainActor
final class SocialShareService {
    static let shared = SocialShareService()

    private let exportService: ExportService

    private init(exportService: ExportService = .shared) {
        self.exportService = exportService
    }

    // MARK: Save to Photos

    func saveToPhotos(_ image: UIImage) async -> Result<Void, ShareError> {
        let status = await ensurePhotosAddPermission()
        switch status {
        case .authorized, .limited:
            break
        case .denied, .restricted:
            return .failure(.openSettingsRequired)
        case .notDetermined:
            return .failure(.noPermission)
        @unknown default:
            return .failure(.noPermission)
        }

        do {
            try await exportService.saveToPhotoLibrary(image)
            return .success(())
        } catch {
            return .failure(.exportFailed)
        }
    }

    // MARK: Instagram Stories

    func shareToInstagramStories(_ image: UIImage) async -> Result<Void, ShareError> {
        guard let url = URL(string: "instagram-stories://share?source_application=com.bananarator.app") else {
            return .failure(.schemeUnavailable)
        }
        guard UIApplication.shared.canOpenURL(url) else {
            return .failure(.schemeUnavailable)
        }
        guard let pngData = exportService.pngData(image) else {
            return .failure(.exportFailed)
        }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": pngData
        ]]
        let expiration = Date().addingTimeInterval(60 * 5)
        UIPasteboard.general.setItems(
            pasteboardItems,
            options: [.expirationDate: expiration]
        )

        let opened = await UIApplication.shared.open(url)
        return opened ? .success(()) : .failure(.schemeUnavailable)
    }

    // MARK: Snapchat

    func shareToSnapchat(_ image: UIImage) async -> Result<Void, ShareError> {
        guard let url = URL(string: "snapchat://") else {
            return .failure(.schemeUnavailable)
        }
        guard UIApplication.shared.canOpenURL(url) else {
            return .failure(.schemeUnavailable)
        }

        // Save to camera roll first so user can pick it inside Snap.
        let saveResult = await saveToPhotos(image)
        if case .failure(let error) = saveResult {
            return .failure(error)
        }

        let opened = await UIApplication.shared.open(url)
        return opened ? .success(()) : .failure(.schemeUnavailable)
    }

    // MARK: Copy

    func copyImage(_ image: UIImage) {
        UIPasteboard.general.image = image
    }

    // MARK: Share Sheet

    /// Returns a configured `UIActivityViewController` for the "More" path.
    /// Callers must set `popoverPresentationController.sourceView` on iPad before presenting.
    func presentShareSheet(image: UIImage, text: String, from view: UIView) -> UIActivityViewController {
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
        if let popover = controller.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }
        return controller
    }

    // MARK: - Permissions

    private func ensurePhotosAddPermission() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current != .notDetermined {
            return current
        }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
