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

struct MannequinAdjustmentsTests {
    private let shirt = UUID(), belt = UUID()
    private func layout() -> MannequinLayout { MannequinLayout.place([(shirt, .tops), (belt, .accessories)]) }

    @Test func ac2DragAndPinchMoveAndScaleThePieceAndResetRestoresEveryDefault() throws {
        let base = layout()
        let defaultFrame = try #require(base.frame(of: shirt, adjustments: MannequinAdjustments()))
        var adjustments = MannequinAdjustments()
        adjustments.drag(shirt, dx: 0.1, dy: 0.2)
        adjustments.setScale(shirt, 1.5)
        let moved = try #require(base.frame(of: shirt, adjustments: adjustments))
        #expect(moved != defaultFrame)
        #expect(moved.width > defaultFrame.width)
        #expect(adjustments.isAdjusted)
        adjustments.reset()
        #expect(adjustments == MannequinAdjustments())
        #expect(!adjustments.isAdjusted)
        #expect(base.frame(of: shirt, adjustments: adjustments) == defaultFrame)
    }

    @Test func ac2ScaleIsClampedToHalfThroughDouble() {
        var adjustments = MannequinAdjustments()
        adjustments.setScale(shirt, 9)
        #expect(adjustments.scale(for: shirt) == 2.0)
        adjustments.setScale(shirt, 0.01)
        #expect(adjustments.scale(for: shirt) == 0.5)
    }

    @Test func ac2ScaleKeepsTheFrameCentre() throws {
        let base = layout()
        let before = try #require(base.frame(of: shirt, adjustments: MannequinAdjustments()))
        var adjustments = MannequinAdjustments()
        adjustments.setScale(shirt, 2)
        let after = try #require(base.frame(of: shirt, adjustments: adjustments))
        #expect(abs((before.x + before.width / 2) - (after.x + after.width / 2)) < 0.0001)
        #expect(abs((before.y + before.height / 2) - (after.y + after.height / 2)) < 0.0001)
    }

    @Test func ac7EachStepChangesPositionOrSizeByOneStep() {
        var adjustments = MannequinAdjustments()
        adjustments.step(shirt, .right)
        #expect(abs(adjustments.offset(for: shirt).dx - MannequinAdjustments.moveStep) < 0.0001)
        #expect(adjustments.offset(for: shirt).dy == 0)
        adjustments.step(shirt, .left); adjustments.step(shirt, .left)
        #expect(adjustments.offset(for: shirt).dx < 0)
        adjustments.reset()
        adjustments.step(shirt, .down)
        #expect(adjustments.offset(for: shirt).dy > 0)
        adjustments.step(shirt, .up); adjustments.step(shirt, .up)
        #expect(adjustments.offset(for: shirt).dy < 0)
        adjustments.reset()
        adjustments.step(shirt, .larger)
        #expect(abs(adjustments.scale(for: shirt) - (1 + MannequinAdjustments.scaleStep)) < 0.0001)
        adjustments.step(shirt, .smaller); adjustments.step(shirt, .smaller)
        #expect(abs(adjustments.scale(for: shirt) - (1 - MannequinAdjustments.scaleStep)) < 0.0001)
    }

    @Test func ac7RepeatedSmallerStopsAtTheMinimum() {
        var adjustments = MannequinAdjustments()
        for _ in 0..<40 { adjustments.step(shirt, .smaller) }
        #expect(adjustments.scale(for: shirt) == 0.5)
    }

    @Test func ac11DroppingTheAccessoryOnTheFigureTakesItOutOfTheTrayUntilReset() throws {
        let base = layout()
        var adjustments = MannequinAdjustments()
        #expect(base.trayIDs(adjustments: adjustments) == [belt])
        #expect(base.frame(of: belt, adjustments: adjustments) == nil)
        adjustments.drop(belt, atX: 0.5, y: 0.45)
        #expect(base.trayIDs(adjustments: adjustments).isEmpty)
        let frame = try #require(base.frame(of: belt, adjustments: adjustments))
        #expect(abs((frame.x + frame.width / 2) - 0.5) < 0.0001)
        #expect(abs((frame.y + frame.height / 2) - 0.45) < 0.0001)
        adjustments.drag(belt, dx: 0.05, dy: 0)
        #expect(try #require(base.frame(of: belt, adjustments: adjustments)).x > frame.x)
        adjustments.reset()
        #expect(base.trayIDs(adjustments: adjustments) == [belt])
        #expect(base.frame(of: belt, adjustments: adjustments) == nil)
    }

    @Test func ac11DropNearAnEdgeKeepsTheAccessoryInsideTheFigure() throws {
        let base = layout()
        var adjustments = MannequinAdjustments()
        adjustments.drop(belt, atX: 5, y: -3)
        let frame = try #require(base.frame(of: belt, adjustments: adjustments))
        #expect(frame.x >= 0 && frame.y >= 0 && frame.x + frame.width <= 1.0001 && frame.y + frame.height <= 1.0001)
    }
}
