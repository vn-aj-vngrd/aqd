import Foundation
import Testing
@testable import AQDCore

struct AgentIntentTests {
    static let table: [(String, AgentIntent)] = [
        // chat
        ("Hi", .chat), ("hello there", .chat), ("Good morning", .chat), ("Thanks!", .chat), ("What can you help me with?", .chat), ("What can you do?", .chat), ("who are you", .chat), ("ok", .chat), ("Hello, my closet is new.", .chat),
        // show
        ("Show my black pieces", .show), ("Show all my tops", .show), ("List my outfits", .show), ("Show me my dresses", .show), ("Show my themes", .show), ("Show my plans", .show),
        ("Which shoes do I have available?", .show), ("Display all my jackets", .show), ("What do I have in blue?", .show), ("see my sneakers", .show), ("Preview my accessories", .show), ("list all my skirts", .show),
        // find
        ("Do I own a trench coat?", .find), ("Which of my pieces are made of linen?", .find), ("Find my gold jewelry", .find), ("Tell me about the Cream poplin blouse", .find), ("Search for my denim", .find),
        ("Do I have a black blazer?", .find), ("Where is my camel cardigan", .find), ("look for my white sneakers", .find),
        // stats
        ("What did I wear most this month?", .stats), ("Which pieces have I never worn?", .stats), ("How many times did I wear the Ivory sneakers this month?", .stats), ("How many outfits do I have?", .stats),
        ("How many pieces are in my closet?", .stats), ("What did I wear last week", .stats), ("Rediscover my unworn pieces", .stats), ("how often do I wear my jeans", .stats), ("What's my least worn dress?", .stats), ("How many themes do I have", .stats),
        // what to wear
        ("What should I wear today?", .whatToWear), ("Tonight's look", .whatToWear), ("What should I wear tomorrow?", .whatToWear), ("what to wear tonight", .whatToWear), ("Will it rain tomorrow?", .whatToWear),
        ("Do I need an umbrella", .whatToWear), ("outfit for today please", .whatToWear), ("what's the weather like for my outfit", .whatToWear),
        // suggest outfit
        ("Suggest an outfit for brunch", .suggestOutfit), ("Put together something for a date night", .suggestOutfit), ("Style my Black blazer for work", .suggestOutfit), ("I need an outfit for a wedding", .suggestOutfit),
        ("Recommend something cozy", .suggestOutfit), ("What should I wear to a birthday dinner?", .suggestOutfit), ("What goes with my Ivory sneakers?", .suggestOutfit), ("Make me a casual look", .suggestOutfit),
        ("Suggest an outfit with my Cream poplin blouse", .suggestOutfit), ("Dress me for a client meeting", .suggestOutfit),
        // trips
        ("Plan outfits for 3 days in Boracay", .planTrip), ("Plan outfits for a 4 day trip to Tokyo", .planTrip), ("Pack for a weekend in Baguio", .planTrip), ("I'm going on a trip, help me pack", .planTrip),
        ("Plan a trip for me", .planTrip), ("Plan outfits for my trip to Cebu", .planTrip), ("What should I bring on my vacation to Bali?", .planTrip), ("honeymoon in Palawan for 5 days", .planTrip), ("Getaway outfits please", .planTrip),
        // plan days
        ("Plan my outfits for the next 5 days", .planDays), ("Plan my week", .planDays), ("Plan outfits for Monday to Wednesday", .planDays), ("Schedule my outfits for the week", .planDays), ("Plan my outfits", .planDays),
        // themes
        ("Make a theme from my beach outfits", .theme), ("Create a theme called Summer from my vacation looks", .theme), ("Group my work outfits into a collection", .theme), ("Create a new theme", .theme),
        // relabel
        ("Rename the Office day outfit to Monday uniform", .relabel), ("Set the occasion of Rainy day to Commute", .relabel), ("Rename my Beach theme to Summer", .relabel), ("Change the mood of Date night to Elegant", .relabel), ("Relabel the Boracay trip plan", .relabel),
        // edit piece
        ("Rename my Classic white tee to White basic tee", .editPiece), ("Mark my Black ballet flats as laundry", .editPiece), ("Change the color of the Camel cardigan to tan", .editPiece),
        ("Rename my blazer to Work blazer", .editPiece), ("Mark my dress as unavailable", .editPiece), ("Change the color of my sandals to brown", .editPiece), ("Set my sneakers as available", .editPiece), ("Update the brand of my trench coat to Mango", .editPiece),
        // record wear
        ("Log that I wore the Office day outfit yesterday", .recordWear), ("Record that I wore my Ivory sneakers today", .recordWear), ("Record what I wore", .recordWear), ("I wore the Rainy day look today", .recordWear), ("Log my outfit", .recordWear),
        // profile
        ("Change my profile caption to Dressing slow", .profile), ("Update my bio", .profile), ("Set my name to Van", .profile),
        // out of scope
        ("What's the capital of France?", .outOfScope), ("Write me a Python script to sort a list", .outOfScope), ("Book me a flight to Cebu", .outOfScope), ("Tell me a joke about cats", .outOfScope), ("Who won the world cup in 2018", .outOfScope), ("Solve 12 times 14", .outOfScope), ("What is the meaning of life", .outOfScope)
    ]

    @Test func tableOfPromptsClassifiesToTheExpectedIntent() {
        #expect(Self.table.count >= 80)
        var wrong: [String] = []
        for (prompt, expected) in Self.table where AgentIntent.classify(prompt) != expected { wrong.append("\(prompt) -> \(AgentIntent.classify(prompt)) (wanted \(expected))") }
        #expect(wrong.isEmpty, "\(wrong.joined(separator: "\n"))")
    }
    @Test func imagesAddAPiece() {
        #expect(AgentIntent.classify("add this to my closet", hasImage: true) == .addPiece)
        #expect(AgentIntent.classify("Add this piece") == .addPiece)
    }
    @Test func answersAndShortReplyInheritThePreviousIntent() {
        #expect(AgentIntent.classify("3 days", previous: .planTrip) == .planTrip)
        #expect(AgentIntent.classify("Work", previous: .suggestOutfit, answeringQuestion: true) == .suggestOutfit)
        #expect(AgentIntent.classify("Black blazer", previous: .editPiece, answeringQuestion: true) == .editPiece)
        #expect(AgentIntent.classify("You choose for me", previous: .planTrip, answeringQuestion: true) == .planTrip)
        #expect(AgentIntent.classify("yes", previous: .recordWear) == .recordWear)
        // A new request is not a follow-up, even right after a question.
        #expect(AgentIntent.classify("Show my black pieces", previous: .planTrip, answeringQuestion: true) == .show)
        #expect(AgentIntent.classify("3 days") == .chat)
        for steer in ["Show me a different option", "Make it dressier", "Make it more casual", "Swap the shoes", "Add a layer", "Use a different top"] {
            #expect(AgentIntent.classify(steer, previous: .suggestOutfit) == .suggestOutfit, "\(steer)")
        }
        #expect(AgentIntent.classify("Make it dressier", previous: .whatToWear) == .suggestOutfit)
        // Small talk never carries a tool intent forward.
        #expect(AgentIntent.classify("thanks", previous: .planTrip) == .chat)
    }
    @Test func conversationSuppliesThePreviousIntentAndOpenQuestion() {
        var conversation = AgentConversation(ownerID: UUID())
        var user = AgentMessage(role: .user, source: "Plan a trip for me", status: .complete)
        user.attachments = nil
        var reply = AgentMessage(role: .assistant, source: "How many days?", status: .complete, attemptID: UUID())
        var diagnostics = AgentResponseDiagnostics(included: 0, omitted: 0, inputCharacters: 10, sources: []); diagnostics.intent = "planTrip"
        reply.diagnostics = diagnostics
        reply.toolSteps = [AgentToolStep(tool: "askUser", summary: "Asked", question: AgentQuestion(prompt: "How many days?", options: ["3 days", "5 days"]))]
        conversation.messages = [user, reply]
        #expect(AgentIntent.classify("5 days", conversation: conversation) == .planTrip)
        #expect(AgentIntent.classify("What's the capital of France?", conversation: conversation) == .outOfScope)
    }
    @Test func everyIntentOffersAtMostThreeToolsAndTheRightLeadTool() {
        for intent in AgentIntent.allCases { for weather in [false, true] { #expect(intent.tools(weatherAvailable: weather).count <= 3) } }
        #expect(AgentIntent.planTrip.tools(weatherAvailable: false).first == .proposeTrip)
        #expect(AgentIntent.show.tools(weatherAvailable: false) == [.showRecords])
        #expect(AgentIntent.recordWear.tools(weatherAvailable: false).first == .recordWear)
        #expect(AgentIntent.outOfScope.tools(weatherAvailable: true).isEmpty && AgentIntent.chat.tools(weatherAvailable: true).isEmpty)
        #expect(AgentIntent.suggestOutfit.tools(weatherAvailable: true).contains(.weatherFor) && !AgentIntent.suggestOutfit.tools(weatherAvailable: false).contains(.weatherFor))
        #expect(AgentIntent.planTrip.responseTokens == 500 && AgentIntent.show.responseTokens == 300)
        #expect(AgentIntent.outOfScope.contextNeed == .none && AgentIntent.show.hasFastPath && !AgentIntent.planTrip.hasFastPath)
    }
}
