import Testing
@testable import AQDCore

struct AgentEditRoutingTests {
    @Test func changesInsideSavedRecordsRouteToTheirOwnIntent() {
        let cases: [(String, AgentIntent)] = [
            ("Add my Gold dress watch to the Office day outfit", .editOutfit), ("Add the Gold dress watch to Office day", .editOutfit),
            ("Remove the Brown leather belt from Office day", .editOutfit), ("Swap the Black ballet flats for my Ivory sneakers in Office day", .editOutfit),
            ("Replace the belt in Office day with the Gold dress watch", .editOutfit),
            ("Add Beach walk to my Resort theme", .editTheme), ("Take Poolside lunch out of the Resort theme", .editTheme),
            ("Change Wednesday in This week to the Rainy day outfit", .editPlan), ("Put the Rainy day outfit on Friday in my This week plan", .editPlan)
        ]
        for (prompt, intent) in cases { #expect(AgentIntent.classify(prompt) == intent, "\(prompt)") }
    }

    @Test func requestsThatLookSimilarStayWhereTheyWere() {
        #expect(AgentIntent.classify("Put together an outfit for dinner in Boracay") != .editOutfit)
        #expect(AgentIntent.classify("Put on something warm for the rain") != .editOutfit)
        #expect(AgentIntent.classify("Add this to my closet") == .addPiece)
        #expect(AgentIntent.classify("Remove the old tee from my closet") == .tidy)
        #expect(AgentIntent.classify("Plan my week of outfits") == .planDays)
        #expect(AgentIntent.classify("Rename my Beach theme to Summer") == .relabel)
        #expect(AgentIntent.classify("Mark my Black ballet flats as laundry") == .editPiece)
        #expect(AgentIntent.allCases.allSatisfy { $0.tools(weatherAvailable: true).count <= 3 })
    }

    @Test func plainEditsBecomeCommandsTheAppCanCarryOut() {
        #expect(AgentCommand.parse("Add my Gold dress watch to the Office day outfit") == .addTo(subjects: ["Gold dress watch"], container: "Office day"))
        #expect(AgentCommand.parse("Add Beach walk and Snorkel day to my Resort theme") == .addTo(subjects: ["Beach walk", "Snorkel day"], container: "Resort"))
        #expect(AgentCommand.parse("Remove the Brown leather belt from Office day") == .removeFrom(subjects: ["Brown leather belt"], container: "Office day"))
        #expect(AgentCommand.parse("Take Poolside lunch out of the Resort theme") == .removeFrom(subjects: ["Poolside lunch"], container: "Resort"))
        #expect(AgentCommand.parse("Swap the Black ballet flats for my Ivory sneakers in Office day") == .swapIn(old: "Black ballet flats", new: "Ivory sneakers", container: "Office day"))
        #expect(AgentCommand.parse("Replace the belt in Office day with the Gold dress watch") == .swapIn(old: "belt", new: "Gold dress watch", container: "Office day"))
        #expect(AgentCommand.parse("Change Wednesday in This week to the Rainy day outfit") == .setPlanDay(plan: "This week", day: "wednesday", outfit: "Rainy day"))
        #expect(AgentCommand.parse("Put the Rainy day outfit on Friday in my This week plan") == .setPlanDay(plan: "This week", day: "friday", outfit: "Rainy day"))
    }

    @Test func aClosetTidyIsNeverReadAsAnEditInsideARecord() {
        #expect(AgentCommand.parse("Remove my Straw tote bag from my closet") == .tidy(op: .archive, subjects: ["Straw tote bag"]))
        #expect(AgentCommand.parse("Delete my Black ballet flats from my closet") == .tidy(op: .delete, subjects: ["Black ballet flats"]))
        #expect(AgentCommand.parse("Add this to my closet") == nil)
        #expect(AgentCommand.parse("Put together an outfit for dinner") == nil)
    }
}
