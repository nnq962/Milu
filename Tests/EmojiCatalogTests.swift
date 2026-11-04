import Testing
import UIKit
@testable import Timi

@MainActor
struct EmojiCatalogTests {
    @Test func everySelectableEmojiHasItsOwnBundledArtwork() throws {
        let choices = IconCatalog.emojiGroups.flatMap(\.icons)
        let names = choices.map(\.name)
        #expect(!choices.isEmpty)
        #expect(Set(names).count == names.count)
        for choice in choices {
            #expect(IconCatalog.isEmoji(choice.name))
            #expect(!choice.title.isEmpty)
            let image = try #require(UIImage(named: choice.name), "Missing artwork for \(choice.name)")
            #expect(image.size.width > 0 && image.size.height > 0)
        }
    }

    @Test func newAndPreviouslySavedGoalsUseTheSameSelectableArtwork() {
        for (previous, emoji) in [("hugeicons-car-01", "🚗"), ("hugeicons-luggage-01", "🧳"),
                                  ("hugeicons-rocket-01", "🚀"), ("hugeicons-boat", "⛵")] {
            let asset = IconCatalog.emojiName(emoji)
            #expect(GoalArtwork.name(for: previous) == asset)
            #expect(GoalArtwork.name(for: asset) == asset)
            #expect(IconCatalog.icon(named: asset) != nil)
        }
        for asset in SavingsGoal.suggestedIcons {
            #expect(IconCatalog.icon(named: asset) != nil)
        }
        let unavailableAsset = "milu-emoji-ffff"
        #expect(GoalArtwork.name(for: unavailableAsset) == SavingsGoal.defaultIcon)
        #expect(IconCatalog.assetName(for: unavailableAsset) == IconCatalog.emojiName("🏷️"))
    }
}
