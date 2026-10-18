import Testing
@testable import AQDCore

struct AgentCatalogTextTests {
    let items = (1...20).map { "p\($0) Piece number \($0)" }
    @Test func fullListWhenItFits() {
        let text = AgentCatalogText.fit(label: "Pieces", items: Array(items.prefix(3)), limit: 500)
        #expect(text == "Pieces: p1 Piece number 1; p2 Piece number 2; p3 Piece number 3")
    }
    @Test func shrinksFromTheEndAndSaysHowManyAreHidden() throws {
        let text = try #require(AgentCatalogText.fit(label: "Pieces", items: items, limit: 120))
        #expect(text.count <= 120 && text.hasPrefix("Pieces: p1 Piece number 1") && text.contains("more (use findRecords)") && !text.contains("p20"))
    }
    @Test func nothingWhenThereIsNoRoomOrNoItems() {
        #expect(AgentCatalogText.fit(label: "Pieces", items: [], limit: 500) == nil)
        #expect(AgentCatalogText.fit(label: "Pieces", items: items, limit: 12) == nil)
    }
}
