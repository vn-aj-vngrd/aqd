import Foundation
import Testing
@testable import AQDCore

struct AgentReplyPolishTests {
    @Test func fillerOpenersAndClosersAreStripped() {
        #expect(AgentReplyPolish.polish("Sure! The Black blazer works well here. Let me know if you want another option!") == "The Black blazer works well here.")
        #expect(AgentReplyPolish.polish("Of course! Wear the Ivory sneakers. Hope this helps!") == "Wear the Ivory sneakers.")
    }
    @Test func realContentIsNeverRemoved() {
        let text = "Sure, the Black blazer pairs with the Ivory sneakers and a white tee. Feel free to swap the tee for a tank when it is warm."
        #expect(AgentReplyPolish.polish(text) == text)
        #expect(AgentReplyPolish.polish("Sure!") == "Sure!")
        #expect(AgentReplyPolish.polish("Great! Try the Black blazer.") == "Try the Black blazer.")
    }
    @Test func listsThatRepeatTheCardsAreDropped() {
        let reply = "Here are your black pieces:\n- Black blazer\n- Black ballet flats\n- Little black dress\nWant a look built from them?"
        let polished = AgentReplyPolish.polish(reply, cardTitles: ["Black blazer", "Black ballet flats", "Little black dress"])
        #expect(!polished.contains("- Black") && polished.contains("Here are your black pieces") && polished.contains("Want a look"))
    }
    @Test func listsThatAddInformationStay() {
        let reply = "Tips:\n- Steam the blouse first\n- Roll the sleeves\n"
        #expect(AgentReplyPolish.polish(reply, cardTitles: ["Black blazer", "Cream poplin blouse"]) == reply.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect(AgentReplyPolish.polish("- Black blazer\n", cardTitles: ["Black blazer"]).contains("Black blazer"))
    }
    @Test func middleDotSeparatorsBecomeCommas() {
        #expect(AgentReplyPolish.polish("Tops · Bottoms · Shoes") == "Tops, Bottoms, Shoes")
        #expect(!AgentReplyPolish.polish("A·B").contains("·"))
    }

    @Test func polishingAlsoRemovesIdentifiers() {
        #expect(AgentReplyPolish.polish("Black blazer works well. The app shows photos of p3. Should we explore more from o2?") == "Black blazer works well.")
        #expect(AgentReplyPolish.polish("Only p3 here") == "Only here")
    }
    @Test func repeatedHandlesAndIdsAreScrubbedButNamesStay() {
        #expect(AgentReplyPolish.scrubIdentifiers("The trip includes Beach sunset dinner (o5 Boracay arrival) and p12 Black blazer.") == "The trip includes Beach sunset dinner (Boracay arrival) and Black blazer.")
        #expect(AgentReplyPolish.scrubIdentifiers("Wear o9 today , then pl1.") == "Wear today, then.")
        #expect(AgentReplyPolish.scrubIdentifiers("Plan 2 pm and 10 outfits") == "Plan 2 pm and 10 outfits")
        #expect(AgentReplyPolish.scrubIdentifiers("Linen top (revision 3) is fine") == "Linen top is fine")
    }
}
