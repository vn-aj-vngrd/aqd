import Foundation
import Testing
@testable import AQDCore

struct MannequinLayoutTests {
    private let shirt = UUID(), trousers = UUID(), loafers = UUID(), belt = UUID(), coat = UUID(), dress = UUID()

    @Test func ac1EachCategoryLandsInItsOwnSlotAndAccessoriesGoToTheTray() {
        let layout = MannequinLayout.place([(shirt, .tops), (trousers, .bottoms), (loafers, .shoes), (belt, .accessories)])
        let byID = Dictionary(uniqueKeysWithValues: layout.placements.map { ($0.id, $0) })
        #expect(byID[shirt]?.slot == .torso)
        #expect(byID[trousers]?.slot == .legs)
        #expect(byID[loafers]?.slot == .feet)
        #expect(byID[belt]?.slot == .tray)
        #expect(byID[belt]?.frame == nil)
        #expect(layout.tray == [belt])
        #expect(layout.placements.count == 4)
    }

    @Test func ac1ShoesSitBelowTheTrousersAtTheFeet() throws {
        let layout = MannequinLayout.place([(trousers, .bottoms), (loafers, .shoes)])
        let legs = try #require(layout.placements.first { $0.id == trousers }?.frame)
        let feet = try #require(layout.placements.first { $0.id == loafers }?.frame)
        #expect(feet.y >= legs.y + legs.height - 0.0001)
        #expect(feet.y + feet.height <= 1.0001)
    }

    @Test func ac1DrawOrderIsBottomsDressesTopsLayersWhateverTheOutfitOrder() {
        let layout = MannequinLayout.place([(coat, .layers), (shirt, .tops), (dress, .dresses), (trousers, .bottoms)])
        #expect(layout.drawOrder == [trousers, dress, shirt, coat])
        let z = Dictionary(uniqueKeysWithValues: layout.placements.map { ($0.id, $0.zIndex) })
        #expect((z[trousers] ?? 0) < (z[dress] ?? 0))
        #expect((z[dress] ?? 0) < (z[shirt] ?? 0))
        #expect((z[shirt] ?? 0) < (z[coat] ?? 0))
    }

    @Test func ac1TwoPiecesInOneSlotStackInOutfitOrderLaterInFront() {
        let second = UUID()
        let layout = MannequinLayout.place([(shirt, .tops), (second, .tops)])
        #expect(layout.drawOrder == [shirt, second])
        let z = Dictionary(uniqueKeysWithValues: layout.placements.map { ($0.id, $0.zIndex) })
        #expect((z[shirt] ?? 0) < (z[second] ?? 0))
    }

    @Test func ac1TrayKeepsOutfitOrderAndEmptyOutfitPlacesNothing() {
        let other = UUID()
        #expect(MannequinLayout.place([(belt, .accessories), (shirt, .tops), (other, .accessories)]).tray == [belt, other])
        let empty = MannequinLayout.place([])
        #expect(empty.placements.isEmpty && empty.tray.isEmpty && empty.drawOrder.isEmpty)
    }

    @Test func ac1SlotFramesStayInsideTheFigureCanvas() {
        for category in PieceCategory.allCases where category != .accessories {
            let frame = MannequinLayout.place([(UUID(), category)]).placements[0].frame
            #expect(frame != nil)
            guard let frame else { continue }
            #expect(frame.x >= 0 && frame.y >= 0 && frame.x + frame.width <= 1.0001 && frame.y + frame.height <= 1.0001)
        }
    }

    @Test("AC-9: every category has a placeholder symbol so a slot is never blank") func ac9EveryCategoryHasANonEmptyPlaceholderSymbol() {
        for category in PieceCategory.allCases {
            #expect(!MannequinLayout.placeholderSymbol(for: category).isEmpty)
        }
        #expect(MannequinLayout.placeholderSymbol(for: .shoes) != MannequinLayout.placeholderSymbol(for: .tops))
    }
}
