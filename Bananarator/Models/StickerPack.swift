import Foundation

struct StickerAsset: Identifiable, Codable, Hashable {
    let id: String
    let imageName: String
    let packId: String
}

struct StickerPack: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let previewImageName: String
    let stickers: [StickerAsset]
    let price: Decimal?
    let isSecret: Bool

    var isFree: Bool { price == nil }

    private static func indexed(packId: String, slug: String, count: Int) -> [StickerAsset] {
        (1...count).map { i in
            let n = String(format: "%02d", i)
            return StickerAsset(
                id: "sticker.\(slug).\(n)",
                imageName: "sticker_\(slug)_\(n)",
                packId: packId
            )
        }
    }

    static let cottagecore = StickerPack(
        id: "stickers.cottagecore",
        name: "Cottagecore",
        previewImageName: "sticker_cottagecore_01",
        stickers: indexed(packId: "stickers.cottagecore", slug: "cottagecore", count: 10),
        price: nil,
        isSecret: false
    )

    static let pride = StickerPack(
        id: "stickers.pride",
        name: "Pride",
        previewImageName: "sticker_pride_01",
        stickers: indexed(packId: "stickers.pride", slug: "pride", count: 10),
        price: nil,
        isSecret: false
    )

    static let premiumPacks: [StickerPack] = [
        StickerPack(
            id: "stickers.gym",
            name: "Do You Even",
            previewImageName: "sticker_gym_01",
            stickers: indexed(packId: "stickers.gym", slug: "gym", count: 12),
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.goth",
            name: "Goth Mood",
            previewImageName: "sticker_goth_01",
            stickers: indexed(packId: "stickers.goth", slug: "goth", count: 10),
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.audacity",
            name: "The Audacity",
            previewImageName: "sticker_audacity_01",
            stickers: indexed(packId: "stickers.audacity", slug: "audacity", count: 9),
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.witchy",
            name: "Witchy Vibes",
            previewImageName: "sticker_witchy_01",
            stickers: indexed(packId: "stickers.witchy", slug: "witchy", count: 10),
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.y2k",
            name: "So Random",
            previewImageName: "sticker_y2k_01",
            stickers: indexed(packId: "stickers.y2k", slug: "y2k", count: 10),
            price: 0.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.disco",
            name: "Boogie Nights",
            previewImageName: "sticker_disco_01",
            stickers: indexed(packId: "stickers.disco", slug: "disco", count: 10),
            price: 1.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.drag",
            name: "YAS Queen",
            previewImageName: "sticker_drag_01",
            stickers: indexed(packId: "stickers.drag", slug: "drag", count: 14),
            price: 1.99,
            isSecret: false
        ),
        StickerPack(
            id: "stickers.fancy",
            name: "Fancy Pants",
            previewImageName: "sticker_fancy_01",
            stickers: indexed(packId: "stickers.fancy", slug: "fancy", count: 12),
            price: 1.99,
            isSecret: false
        ),
    ]

    static var all: [StickerPack] {
        [cottagecore, pride] + premiumPacks
    }
}
