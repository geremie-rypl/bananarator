# Bananarator Social Sharing & Save-to-Device Plan

**Date**: 2026-05-13
**Status**: Proposed

## TL;DR

Ship Phase 1 in one afternoon: keep `UIActivityViewController` as the universal fallback, treat **Save to Photos** as a primary destination (not just a stepping stone), layer in three native deep links (Instagram Stories, Snapchat, X/Twitter) that need zero API approvals, and route everything through a new `SocialShareService` that wraps `ExportService`. Defer all API-based posting (TikTok Content Posting API, Instagram Graph API) to Phase 2.

---

## 1. Destinations — honest assessment

| Destination | Mechanism | Phase | Notes |
|---|---|---|---|
| **Save to Photos (camera roll)** | `PHPhotoLibrary.shared().performChanges` with `creationRequestForAsset(from:)` | 1 | First-class button. Most reliable share path. Required by IG Feed / Snapchat fallbacks anyway |
| **Save to Files** | `UIActivityViewController` with `.saveToFiles` | 1 | Free via share sheet |
| **iMessage / Mail / Notes** | `UIActivityViewController` | 1 | Already works |
| **Instagram Stories** | URL scheme + `UIPasteboard` | 1 | No API key. Documented public scheme |
| **Instagram Feed** | No direct-post API. Save to Photos → open Instagram | 1 (workaround) | Acceptable degraded UX |
| **Snapchat** | `snapchat://` URL scheme (Phase 1) → Creative Kit SDK (Phase 2) | 1 | Saves first, then opens Snapchat |
| **X / Twitter** | Share sheet (image attachment via intent URL doesn't work) | 1 | Don't build a custom button — just include in share sheet |
| **TikTok** | Share Kit SDK requires dev portal + business verification + review | 2 | Phase 1: users save then switch to TikTok manually |
| **Threads / Bluesky / Mastodon** | Share sheet | 1 | Free |

---

## 2. Phased delivery

### Phase 1 — ship this week (3–5 hours)

1. New `SocialShareService` in `Bananarator/Services/`.
2. Custom share sheet UI (`SocialShareSheet.swift`) replacing the bare `UIActivityViewController` presentation in `EditorView.swift`. Row of platform buttons + "Save" + "More" fallback.
3. Per-destination handlers: Save to Photos, Instagram Stories, Snapchat, Copy Image, More (share sheet).
4. Update `Info.plist` with `LSApplicationQueriesSchemes` and `NSPhotoLibraryAddUsageDescription`.
5. Hook share completion → `appState.onShare()` and `AnalyticsService.trackShare(platform:)`.

### Phase 2 — after MVP traction
- TikTok Share Kit (dev portal + capability key + review).
- Snapchat Creative Kit SDK (sticker overlays, attribution badge).
- Instagram Graph API for Business/Creator accounts (OAuth + Firebase function).

### Phase 3 — only if metrics justify
- Cross-posting backend.
- Scheduled posts.
- Open Graph preview pages for install attribution.

---

## 3. Phase 1 per-destination detail

### Save to Photos (first-class)

- Permission: `NSPhotoLibraryAddUsageDescription` in Info.plist (add-only — never request full library access).
- API: `PHPhotoLibrary.shared().performChanges { PHAssetCreationRequest.creationRequestForAsset(from: image) }`.
- On denial: show alert with "Open Settings" → `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`.
- On success: haptic feedback + toast "Saved to Photos 🍌".
- Track as `platform: "save"` in analytics — this counts as a "share" for the unlock counter (still drives the viral loop because users post manually from camera roll).

### Instagram Stories

- URL scheme: `instagram-stories://share?source_application=<appID>`
- `UIPasteboard.general.setItems(_:options:)` with:
  - `com.instagram.sharedSticker.backgroundImage` → PNG `Data`
  - `expirationDate` = now + 5 min
- Check `canOpenURL` first; fall back to share sheet if false.
- Skip sticker overlay layer in Phase 1.

### Snapchat (URL-scheme path)

- Save image to camera roll first → open `snapchat://`. Snap auto-prompts about the recent photo. If unreliable in testing, drop this button and rely on share sheet.

### Copy Image / Copy Link

- `UIPasteboard.general.image = cleanImage` → toast "Copied".
- Useful for Discord, iMessage paste, etc.

### Share sheet (More)

- `UIActivityViewController` with `[cleanImage, "Made with Bananarator 🍌 <app link>"]`.
- Exclude `.addToReadingList`, `.assignToContact`, `.openInIBooks`, `.print`.
- iPad: set `popoverPresentationController.sourceView`.

### Required Info.plist additions

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your banana masterpiece to Photos.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>snapchat</string>
    <string>twitter</string>
    <string>tiktok</string>
</array>
```

### Image format

- Save to Photos: PNG (preserves quality, no recompression artifacts on re-share).
- IG Stories: PNG.
- Share sheet / Copy: JPEG 0.9.
- Use `cleanImage` for all user-initiated shares; `censoredImage` only for Showcase upload.

---

## 4. Code changes

### New files
- `Bananarator/Services/SocialShareService.swift` — one method per destination, returns `Result<Void, ShareError>`.
- `Bananarator/Features/Editor/SocialShareSheet.swift` — SwiftUI bottom sheet with destination buttons + toast on completion.

### Modified files
- `Bananarator/Services/ExportService.swift` — keep flatten/censor, expose `pngData(_:)` helper, move `UIActivityViewController` logic out to `SocialShareService`. Existing `saveToPhotoLibrary` stays here as a low-level primitive that `SocialShareService.saveToPhotos()` calls.
- `Bananarator/Features/Editor/EditorView.swift` — swap the `ShareSheet` representable for `SocialShareSheet`. Same trigger button.
- `Bananarator/Info.plist` — add usage description + query schemes.
- `Bananarator/Services/AnalyticsService.swift` — `trackShare(platform: String)`.

### Architectural note
`SocialShareService` depends on `ExportService`, not the other way around. Keeps pixel logic separate from network/destination logic.

---

## 5. Open questions

1. **Watermark on shares?** Censored image has it baked in; clean image doesn't. Recommend small bottom-corner watermark on all shared/saved images (removable for paid users). Drives viral loop.
2. **Auto-post to Firestore Showcase on every share?** Recommend default-on toggle in the share sheet for first 3 shares, user-controlled after.
3. **App link in share text?** Need App Store URL once on TestFlight. Hardcode for Phase 1.
4. **Snapchat reliability without Creative Kit?** Test before committing the Snap button. If flaky, drop until Phase 2.
5. **iPad popover anchor.** Required to avoid crash. Trivial to add.

---

## 6. Critical files

- `Bananarator/Services/ExportService.swift` — current image pipeline and ad-hoc share method
- `Bananarator/Features/Editor/EditorView.swift` — only existing share trigger
- `Bananarator/Features/Editor/EditorViewModel.swift` — produces the `ExportResult` passed to sharing
- `Bananarator/Info.plist` — privacy strings + URL scheme allowlist
- `Bananarator/Services/AnalyticsService.swift` — share-event tracking, drives `appState.onShare()` unlock counter
