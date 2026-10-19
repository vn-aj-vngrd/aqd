import Foundation
import Testing
@testable import AQDCore

struct AgentRecordIndexTests {
    static func piece(_ name: String, _ color: String, _ category: String, tags: [String] = []) -> AgentRecordIndex.Draft {
        .init(kind: .piece, id: UUID(), name: name, revision: 3, attributes: [color, category] + tags)
    }
    let index = AgentRecordIndex([
        piece("Cream poplin blouse", "Cream", "Tops", tags: ["work"]), piece("Sage linen blouse", "Sage", "Tops"), piece("Black blazer", "Black", "Layers"),
        piece("Oatmeal linen blazer", "Oatmeal", "Layers"), piece("Wide-leg trousers", "Charcoal", "Bottoms"), piece("Linen trousers", "Sand", "Bottoms"),
        piece("Tan strappy sandals", "Tan", "Shoes"), piece("Gold flat sandals", "Gold", "Shoes"), piece("Ivory sneakers", "Ivory", "Shoes"),
        .init(kind: .outfit, id: UUID(), name: "Office day", revision: 2, attributes: ["Work"]), .init(kind: .outfit, id: UUID(), name: "Rainy day", revision: 1),
        .init(kind: .theme, id: UUID(), name: "Beach", revision: 4), .init(kind: .plan, id: UUID(), name: "Boracay trip", revision: 1)])

    func name(_ reference: String, _ kinds: [AgentRecordKind] = AgentRecordKind.allCases) -> String? {
        if case .found(let entry) = index.resolve(reference, kinds: kinds) { return entry.name }; return nil
    }
    func candidates(_ reference: String) -> [String] {
        if case .ambiguous(let list) = index.resolve(reference) { return list.map(\.name) }; return []
    }

    @Test func handlesAreShortKindPrefixedAndStableByNameOrder() {
        #expect(index.entries(of: .piece).map(\.handle) == (1...9).map { "p\($0)" })
        #expect(index.entries(of: .outfit).map(\.handle) == ["o1", "o2"] && index.entries(of: .theme).first?.handle == "t1" && index.entries(of: .plan).first?.handle == "pl1")
        #expect(index.entry(handle: "p1")?.name == "Black blazer")
        let reordered = AgentRecordIndex(index.entries.reversed().map { .init(kind: $0.kind, id: $0.id, name: $0.name, revision: $0.revision, attributes: $0.attributes) })
        #expect(reordered.entries.map(\.handle) == index.entries.map(\.handle))
    }
    @Test func handleResolvesAndIsRestrictedToTheAskedKinds() {
        #expect(name("p1") == "Black blazer" && name("P1") == "Black blazer" && name(" [o2] ") == "Rainy day")
        #expect(name("o1", [.piece]) == nil && name("p99") == nil)
    }
    @Test func exactNameIgnoresCaseAccentsAndPunctuation() {
        #expect(name("cream poplin blouse") == "Cream poplin blouse" && name("Wide leg trousers!") == "Wide-leg trousers")
        #expect(name("“Office day”") == "Office day" && name("the Office day outfit") == "Office day")
    }
    @Test func looseReferencesNeedToCoverEveryWordAndBeUnique() {
        #expect(name("the cream top") == "Cream poplin blouse")
        #expect(name("my linen blazer") == "Oatmeal linen blazer")
        #expect(name("sage blouse") == "Sage linen blouse")
        #expect(name("ivory shoes") == "Ivory sneakers")
        #expect(name("striped scarf") == nil && name("") == nil && name("purple tuxedo") == nil)
    }
    @Test func ambiguityReturnsTwoToFourCandidates() {
        #expect(Set(candidates("blazer")) == ["Black blazer", "Oatmeal linen blazer"])
        #expect(Set(candidates("sandals")) == ["Tan strappy sandals", "Gold flat sandals"])
        #expect(Set(candidates("linen")) == ["Sage linen blouse", "Oatmeal linen blazer", "Linen trousers"])
        #expect(candidates("blouse").count == 2)
    }
    @Test func kindsNarrowTheSearchAndDuplicatesAreAmbiguous() {
        #expect(name("beach", [.theme]) == "Beach" && name("beach", [.piece]) == nil)
        let twin = AgentRecordIndex([.init(kind: .piece, id: UUID(), name: "Tee", revision: 1), .init(kind: .piece, id: UUID(), name: "Tee", revision: 2)])
        if case .ambiguous(let both) = twin.resolve("Tee") { #expect(both.count == 2) } else { Issue.record("expected ambiguity") }
    }
    @Test func entriesCarryTheCurrentRevisionAndMapBackToTheID() {
        let entry = index.entry(handle: "o1")
        #expect(entry?.revision == 2 && entry.flatMap { index.handle(for: $0.id) } == "o1")
    }
}
