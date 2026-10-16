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

extension PieceDraft { var displayName: String { wardrobeDisplayName(name, id: itemID) } }
extension OutfitDraft { var displayName: String { wardrobeDisplayName(name, id: outfitID) } }
extension ThemeDraft { var displayName: String { wardrobeDisplayName(name, id: themeID) } }

private func seedDisplayText(_ text: String, id: UUID) -> String {
    let key = id.uuidString.uppercased()
    guard key.hasPrefix("A0D51000-0000-4000-8000-"), let number = Int(key.suffix(12)),
          (1...12).contains(number) || (101...106).contains(number) || (201...204).contains(number) || (401...408).contains(number) else { return text }
    if text.hasPrefix("Sample preview · ") { return String(text.dropFirst("Sample preview · ".count)) }
    if text == "Sample preview artwork. This is not a personal wardrobe upload." { return "Preview artwork. This is not a personal wardrobe upload." }
    if text == "Sample collection for previewing the app." { return "A private outfit collection." }
    if text == "Sample fit memory for preview only. This does not represent your photo or recorded wear." { return "Illustrative fit memory. This does not represent your photo or recorded wear." }
    return text
}
extension WardrobePiece { var displayNotes: String { seedDisplayText(details.notes, id: id) } }
extension PieceDraft { var displayNotes: String { seedDisplayText(details.notes, id: itemID) } }
extension OutfitTheme { var displayDescription: String { seedDisplayText(description, id: id) } }
extension ThemeDraft { var displayDescription: String { seedDisplayText(description, id: themeID) } }
extension FitMemory { var displayNote: String { seedDisplayText(note, id: id) } }
