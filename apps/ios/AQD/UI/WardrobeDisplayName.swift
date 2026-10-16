import AQDCore
import Foundation

/// Keep seed provenance in storage while presenting natural item names.
private func wardrobeDisplayName(_ name: String, id: UUID) -> String {
    let prefix = "Sample · "
    let key = id.uuidString.uppercased()
    guard key.hasPrefix("A0D51000-0000-4000-8000-"),
          let number = Int(key.suffix(12)),
          (1...12).contains(number) || (101...106).contains(number) || (201...204).contains(number),
          name.hasPrefix(prefix), name.count > prefix.count else { return name }
    return String(name.dropFirst(prefix.count))
}

extension WardrobePiece { var displayName: String { wardrobeDisplayName(name, id: id) } }
extension Outfit { var displayName: String { wardrobeDisplayName(name, id: id) } }
extension OutfitTheme { var displayName: String { wardrobeDisplayName(name, id: id) } }
extension WearPieceSnapshot { var displayName: String { wardrobeDisplayName(name, id: id) } }
extension FitOutfitSnapshot { var displayName: String { wardrobeDisplayName(name, id: id) } }
