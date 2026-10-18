import Foundation
import Testing
@testable import AQDCore

struct AgentCommandTests {
    @Test func renamesAnyRecord() {
        #expect(AgentCommand.parse("Rename the Office day outfit to Monday uniform") == .rename(target: "Office day outfit", to: "Monday uniform"))
        #expect(AgentCommand.parse("rename my Classic white tee to White basic tee.") == .rename(target: "Classic white tee", to: "White basic tee"))
        #expect(AgentCommand.parse("Rename my blazer to “Work blazer”") == .rename(target: "blazer", to: "Work blazer"))
        #expect(AgentCommand.parse("Rename it") == nil)
    }
    @Test func availabilityChanges() {
        #expect(AgentCommand.parse("Mark my Black ballet flats as laundry") == .setAvailability(target: "Black ballet flats", value: "laundry"))
        #expect(AgentCommand.parse("Mark my dress as unavailable") == .setAvailability(target: "dress", value: "unavailable"))
        #expect(AgentCommand.parse("Set my sneakers as available!") == .setAvailability(target: "sneakers", value: "available"))
        #expect(AgentCommand.parse("Put the Camel cardigan in the laundry") == .setAvailability(target: "Camel cardigan", value: "laundry"))
    }
    @Test func pieceAndOutfitFields() {
        #expect(AgentCommand.parse("Change the color of the Camel cardigan to tan") == .setPieceField(target: "Camel cardigan", field: "color", value: "tan"))
        #expect(AgentCommand.parse("Update the brand of my trench coat to Mango") == .setPieceField(target: "trench coat", field: "brand", value: "Mango"))
        #expect(AgentCommand.parse("Set the occasion of Rainy day to Commute") == .setOutfitField(target: "Rainy day", field: "occasion", value: "Commute"))
        #expect(AgentCommand.parse("Change the mood of Date night to Elegant") == .setOutfitField(target: "Date night", field: "mood", value: "Elegant"))
    }
    @Test func recordedWear() {
        #expect(AgentCommand.parse("Log that I wore the Office day outfit yesterday") == .recordWear(subjects: ["Office day outfit"], dayOffset: -1))
        #expect(AgentCommand.parse("Record that I wore my Ivory sneakers today") == .recordWear(subjects: ["Ivory sneakers"], dayOffset: 0))
        #expect(AgentCommand.parse("I wore the Black blazer and the Ivory sneakers") == .recordWear(subjects: ["Black blazer", "Ivory sneakers"], dayOffset: 0))
        #expect(AgentCommand.parse("Record what I wore") == nil)
    }
    @Test func profileEdits() {
        #expect(AgentCommand.parse("Change my profile caption to Dressing slow") == .setProfile(field: "caption", value: "Dressing slow"))
        #expect(AgentCommand.parse("Set my name to Van") == .setProfile(field: "name", value: "Van"))
        #expect(AgentCommand.parse("Update my bio to Everyday looks.") == .setProfile(field: "caption", value: "Everyday looks"))
    }
    @Test func themeCreation() {
        #expect(AgentCommand.parse("Make a theme from my beach outfits") == .createTheme(name: nil, about: "beach"))
        #expect(AgentCommand.parse("Create a theme called Summer from my vacation looks") == .createTheme(name: "Summer", about: "vacation"))
        #expect(AgentCommand.parse("Create a new theme") == .createTheme(name: nil, about: nil))
    }
    @Test func planningTheNextDays() {
        #expect(AgentCommand.parse("Plan my outfits for the next 5 days") == .planDays(count: 5))
        #expect(AgentCommand.parse("Plan outfits for the next three days.") == .planDays(count: 3))
        #expect(AgentCommand.parse("Plan my week") == .planDays(count: 7))
        #expect(AgentCommand.parse("Plan outfits for the week") == .planDays(count: 7))
        #expect(AgentCommand.parse("Plan my outfits for the next 30 days") == nil)
        #expect(AgentCommand.parse("Plan outfits for Monday to Wednesday") == nil)
    }
    @Test func requestsThatAreNotCompleteCommandsFallThroughToTheModel() {
        for prompt in ["Show my black pieces", "What should I wear today?", "Suggest an outfit for brunch", "Plan a vacation", "Mark it", "hello", "Plan a trip for me"] {
            #expect(AgentCommand.parse(prompt) == nil, "\(prompt)")
        }
    }
}
