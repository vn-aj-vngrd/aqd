import Foundation
import Testing
@testable import AQDCore

struct AgentShowQueryTests {
    @Test func readsKindColorCategoryAndNameFilters() {
        #expect(AgentShowQuery.parse("Show my black pieces") == AgentShowQuery(kind: .piece, color: "black"))
        #expect(AgentShowQuery.parse("Show all my tops").category == "Tops" && AgentShowQuery.parse("Show all my tops").query.isEmpty)
        let sneakers = AgentShowQuery.parse("Show my white sneakers")
        #expect(sneakers.color == "white" && sneakers.category == "Shoes" && sneakers.query == "sneaker")
        let shoes = AgentShowQuery.parse("Which shoes do I have available?")
        #expect(shoes.category == "Shoes" && shoes.availability == "available" && shoes.query.isEmpty)
        #expect(AgentShowQuery.parse("show my jackets").query == "jacket" && AgentShowQuery.parse("show my jeans").query == "jeans")
        #expect(AgentShowQuery.parse("list my linen pieces").query == "linen")
        #expect(AgentShowQuery.parse("pieces in the laundry").availability == "laundry")
    }
    @Test func otherKindsAreRecognised() {
        #expect(AgentShowQuery.parse("List my outfits").kind == .outfit && AgentShowQuery.parse("Show my themes").kind == .theme)
        #expect(AgentShowQuery.parse("Show my plans").kind == .plan && AgentShowQuery.parse("show my beach outfits").kind == .outfit)
    }
    @Test func occasionsAreReadFromTheEndOfARequest() {
        #expect(AgentShowQuery.occasion(in: "Suggest an outfit for brunch") == "brunch")
        #expect(AgentShowQuery.occasion(in: "Put together something for a date night") == "date night")
        #expect(AgentShowQuery.occasion(in: "I need an outfit for a wedding.") == "wedding")
        #expect(AgentShowQuery.occasion(in: "Style my Black blazer for work") == "work")
        #expect(AgentShowQuery.occasion(in: "Suggest an outfit with my Cream poplin blouse") == nil)
        #expect(AgentShowQuery.occasion(in: "What should I wear today?") == nil && AgentShowQuery.occasion(in: "Dress me for tonight") == nil)
    }
    @Test func daysAndMonthsAreRead() {
        #expect(AgentShowQuery.dayOffset("What should I wear tomorrow?") == 1 && AgentShowQuery.dayOffset("Tonight's look") == 0)
        #expect(AgentShowQuery.wantsLastMonth("what did I wear most last month") && !AgentShowQuery.wantsLastMonth("this month"))
    }
    @Test func indexFindsPiecesNamedInAPrompt() {
        let index = AgentRecordIndex([.init(kind: .piece, id: UUID(), name: "Ivory sneakers", revision: 1), .init(kind: .piece, id: UUID(), name: "Black blazer", revision: 1), .init(kind: .outfit, id: UUID(), name: "Office day", revision: 1)])
        #expect(index.mentions(in: "How many times did I wear the Ivory sneakers this month?").map(\.name) == ["Ivory sneakers"])
        #expect(index.mentions(in: "wore the Office day look with my black blazer", kinds: [.piece]).map(\.name) == ["Black blazer"])
        #expect(index.mentions(in: "nothing here").isEmpty)
    }

    private let closet = AgentRecordIndex([
        .init(kind: .piece, id: UUID(), name: "Navy trench coat", revision: 1, attributes: ["Layers", "Navy", "Cotton gabardine"]),
        .init(kind: .piece, id: UUID(), name: "Gold hoop earrings", revision: 1, attributes: ["Accessories", "Gold"]),
        .init(kind: .piece, id: UUID(), name: "Gold flat sandals", revision: 1, attributes: ["Shoes", "Gold"]),
        .init(kind: .piece, id: UUID(), name: "Gold dress watch", revision: 1, attributes: ["Accessories", "Gold and brown"]),
        .init(kind: .piece, id: UUID(), name: "Sage linen blouse", revision: 1, attributes: ["Tops", "Sage", "Linen"]),
        .init(kind: .piece, id: UUID(), name: "Linen trousers", revision: 1, attributes: ["Bottoms", "Sand", "Linen"]),
        .init(kind: .piece, id: UUID(), name: "Black blazer", revision: 1, attributes: ["Layers", "Black"])])

    @Test func searchFindsRecordsThatMatchEveryWord() {
        #expect(closet.search("Do I own a trench coat?").map(\.name) == ["Navy trench coat"])
        #expect(Set(closet.search("Which of my pieces are made of linen?").map(\.name)) == ["Sage linen blouse", "Linen trousers"])
        #expect(Set(closet.search("Find my gold jewelry").map(\.name)) == ["Gold hoop earrings", "Gold dress watch"])
        #expect(closet.search("Tell me about the Black blazer").map(\.name) == ["Black blazer"])
    }
    @Test func searchIsEmptyWhenNothingMatchesAndPartialOnlyAsAFallback() {
        #expect(closet.search("Do I have a purple tuxedo?").isEmpty)
        #expect(closet.search("Do I own a red blazer").map(\.name) == ["Black blazer"])
        #expect(closet.search("Find my").isEmpty)
    }
}
