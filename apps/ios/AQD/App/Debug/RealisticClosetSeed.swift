#if DEBUG
import AQDCore
import Foundation
import UIKit

/// Debug-only owner preview: a closet, outfits, themes, one planned week and a week of wear for a woman in her mid twenties.
/// It first empties the closet (pieces, outfits, themes, plans, wear and fits) after writing a backup archive; the profile and settings stay.
@MainActor enum RealisticClosetSeed {
    struct Receipt: Codable {
        var pieces: [UUID] = [], outfits: [UUID] = [], themes: [UUID] = [], plans: [UUID] = [], wear: [UUID] = [], fits: [UUID] = []
        var backup = ""
    }

    private enum Look { case art(String), gen(GarmentArt.Shape, GarmentArt.Style) }

    private struct PieceSpec {
        let key: String, name: String, category: PieceCategory, group: String, color: String, brand: String
        let material: String, season: String, tags: [String], look: Look
        var fit = "", notes = ""
    }

    private typealias A = GarmentArt
    private static func plain(_ hex: UInt32) -> A.Style { A.Style(color: A.rgb(hex)) }
    private static func made(_ hex: UInt32, _ pattern: A.Pattern, _ ink: UInt32) -> A.Style { A.Style(color: A.rgb(hex), pattern: pattern, patternColor: A.rgb(ink)) }

    /// A woman's wardrobe in her mid twenties across every category. Seven items use the bundled illustrations; the rest are drawn.
    private static let specs: [PieceSpec] = [
        // Shirts
        PieceSpec(key: "tee", name: "Classic white tee", category: .tops, group: "tops", color: "White", brand: "Uniqlo", material: "Cotton jersey", season: "All year", tags: ["basic", "casual", "work"], look: .gen(.tee, plain(0xF4F1EA)), fit: "Regular"),
        PieceSpec(key: "breton", name: "Breton striped tee", category: .tops, group: "tops", color: "Navy and white", brand: "Saint James", material: "Cotton", season: "Spring and summer", tags: ["casual", "weekend", "vacation"], look: .gen(.tee, made(0xF4F1EA, .stripes, 0x24365E)), fit: "Regular"),
        PieceSpec(key: "blouseCream", name: "Cream poplin blouse", category: .tops, group: "tops", color: "Cream", brand: "COS", material: "Cotton poplin", season: "All year", tags: ["work", "formal", "brunch"], look: .gen(.blouse, plain(0xF2E6D8)), fit: "Relaxed", notes: "Steam before wearing."),
        PieceSpec(key: "blouseSage", name: "Sage linen blouse", category: .tops, group: "tops", color: "Sage", brand: "Mango", material: "Linen", season: "Spring and summer", tags: ["brunch", "vacation", "weekend"], look: .gen(.blouse, plain(0x9DB59A)), fit: "Relaxed"),
        PieceSpec(key: "cropGingham", name: "Gingham crop top", category: .tops, group: "tops", color: "Blue gingham", brand: "Zara", material: "Cotton", season: "Summer", tags: ["casual", "beach", "sunday"], look: .gen(.crop, made(0xF2EEE6, .gingham, 0x3E6FA8)), fit: "Cropped"),
        // Camis and tanks
        PieceSpec(key: "tank", name: "Black fitted tank", category: .tops, group: "camis", color: "Black", brand: "Skims", material: "Stretch cotton", season: "All year", tags: ["basic", "layering", "vacation"], look: .gen(.tank, plain(0x1E1E20)), fit: "Fitted"),
        PieceSpec(key: "camiBlush", name: "Blush silk cami", category: .tops, group: "camis", color: "Blush", brand: "& Other Stories", material: "Silk", season: "All year", tags: ["date night", "formal", "layering"], look: .gen(.cami, plain(0xD9B8A8)), fit: "Slim", notes: "Hand wash."),
        PieceSpec(key: "camiLilac", name: "Lilac satin cami", category: .tops, group: "camis", color: "Lilac", brand: "Reformation", material: "Satin", season: "All year", tags: ["event", "night out", "birthday"], look: .gen(.cami, plain(0xB9A3D6)), fit: "Slim"),
        // Knitwear
        PieceSpec(key: "knit", name: "Ivory ribbed knit", category: .tops, group: "knitwear", color: "Ivory", brand: "COS", material: "Merino wool", season: "Autumn and winter", tags: ["cozy", "sunday", "layering"], look: .art("knit"), fit: "Fitted", notes: "Hand wash cold and dry flat."),
        PieceSpec(key: "cropRed", name: "Red cropped knit", category: .tops, group: "knitwear", color: "Red", brand: "Zara", material: "Cotton blend", season: "Autumn", tags: ["night out", "casual", "event"], look: .gen(.crop, plain(0xC85A6B)), fit: "Cropped"),
        // Bottoms
        PieceSpec(key: "trousersWide", name: "Wide-leg trousers", category: .bottoms, group: "bottoms", color: "Charcoal", brand: "Zara", material: "Wool blend", season: "All year", tags: ["work", "formal", "tailored"], look: .gen(.pants(.wide), plain(0x4A4B50)), fit: "Wide leg", notes: "Dry clean only."),
        PieceSpec(key: "trousersBlack", name: "Black straight trousers", category: .bottoms, group: "bottoms", color: "Black", brand: "COS", material: "Crepe", season: "All year", tags: ["work", "formal", "travel"], look: .gen(.pants(.straight), plain(0x1E1E20)), fit: "Straight"),
        PieceSpec(key: "linen", name: "Linen trousers", category: .bottoms, group: "bottoms", color: "Sand", brand: "Mango", material: "Linen", season: "Summer", tags: ["brunch", "vacation", "beach"], look: .art("linen"), fit: "Wide leg", notes: "Steam before wearing."),
        PieceSpec(key: "shorts", name: "Tailored shorts", category: .bottoms, group: "bottoms", color: "Beige", brand: "H&M", material: "Cotton twill", season: "Summer", tags: ["vacation", "casual", "beach"], look: .gen(.shorts, plain(0xD9CBB3)), fit: "Regular"),
        // Denim
        PieceSpec(key: "jeans", name: "Indigo straight jeans", category: .bottoms, group: "denim", color: "Indigo", brand: "Levi's", material: "Denim", season: "All year", tags: ["casual", "everyday", "weekend"], look: .art("jeans"), fit: "High rise, straight"),
        PieceSpec(key: "jeansBlack", name: "Black skinny jeans", category: .bottoms, group: "denim", color: "Black", brand: "Zara", material: "Stretch denim", season: "All year", tags: ["casual", "night out", "travel"], look: .gen(.pants(.skinny), made(0x242428, .denim, 0x111111)), fit: "Skinny"),
        PieceSpec(key: "denimSkirt", name: "Denim mini skirt", category: .bottoms, group: "denim", color: "Light blue", brand: "Levi's", material: "Denim", season: "Spring and summer", tags: ["casual", "night out", "weekend"], look: .gen(.skirt(.mini, pleated: false), made(0x6C8DB2, .denim, 0x3F618F)), fit: "A-line"),
        // Skirts
        PieceSpec(key: "midiSkirt", name: "Pleated midi skirt", category: .bottoms, group: "skirts", color: "Champagne", brand: "& Other Stories", material: "Satin", season: "All year", tags: ["event", "birthday", "formal"], look: .gen(.skirt(.midi, pleated: true), plain(0xC9B79C)), fit: "Flowy"),
        // Dresses
        PieceSpec(key: "dressCream", name: "Cream midi dress", category: .dresses, group: "dresses", color: "Cream", brand: "& Other Stories", material: "Cotton blend", season: "Spring and summer", tags: ["weekend", "date night", "event"], look: .art("dress"), fit: "A-line", notes: "Wear with a slip underneath."),
        PieceSpec(key: "dressBlack", name: "Little black dress", category: .dresses, group: "dresses", color: "Black", brand: "Reformation", material: "Crepe", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.dress(.mini, sleeves: false), plain(0x1A1A1D)), fit: "Fitted"),
        PieceSpec(key: "dressFloral", name: "Floral maxi dress", category: .dresses, group: "dresses", color: "Pink floral", brand: "Rouje", material: "Viscose", season: "Summer", tags: ["vacation", "beach", "sunday"], look: .gen(.dress(.maxi, sleeves: false), made(0xF4EFE6, .floral, 0xD0678A)), fit: "Flowy"),
        PieceSpec(key: "dressWine", name: "Wine wrap dress", category: .dresses, group: "dresses", color: "Wine", brand: "Mango", material: "Crepe", season: "Autumn and winter", tags: ["formal", "event", "wedding guest"], look: .gen(.dress(.midi, sleeves: true), plain(0x8A2F45)), fit: "Wrap"),
        PieceSpec(key: "dressGingham", name: "Gingham sundress", category: .dresses, group: "dresses", color: "Blue gingham", brand: "Zara", material: "Cotton", season: "Summer", tags: ["sunday", "market", "vacation"], look: .gen(.dress(.midi, sleeves: false), made(0xF2EEE6, .gingham, 0x3E6FA8)), fit: "A-line"),
        PieceSpec(key: "dressSage", name: "Sage slip dress", category: .dresses, group: "dresses", color: "Sage", brand: "Realisation Par", material: "Satin", season: "All year", tags: ["wedding guest", "event", "vacation"], look: .gen(.dress(.midi, sleeves: false), plain(0x9DB59A)), fit: "Slip"),
        PieceSpec(key: "dressShirt", name: "Navy shirt dress", category: .dresses, group: "dresses", color: "Navy", brand: "Massimo Dutti", material: "Cotton poplin", season: "All year", tags: ["work", "tailored"], look: .gen(.dress(.midi, sleeves: true), plain(0x24365E)), fit: "Relaxed"),
        // Layers
        PieceSpec(key: "trench", name: "Navy trench coat", category: .layers, group: "layers", color: "Navy", brand: "Mango", material: "Cotton gabardine", season: "Spring and autumn", tags: ["rain", "work", "travel"], look: .art("coat"), fit: "Relaxed", notes: "The belt is detachable."),
        PieceSpec(key: "blazerBlack", name: "Black blazer", category: .layers, group: "layers", color: "Black", brand: "Zara", material: "Wool blend", season: "All year", tags: ["work", "formal", "event"], look: .gen(.blazer, plain(0x2A2C33)), fit: "Tailored"),
        PieceSpec(key: "blazerBeige", name: "Oatmeal linen blazer", category: .layers, group: "layers", color: "Oatmeal", brand: "Massimo Dutti", material: "Linen blend", season: "Spring and summer", tags: ["work", "brunch", "formal"], look: .gen(.blazer, plain(0xD9C7A8)), fit: "Relaxed"),
        PieceSpec(key: "cardigan", name: "Camel cardigan", category: .layers, group: "layers", color: "Camel", brand: "COS", material: "Wool", season: "Autumn and winter", tags: ["cozy", "work", "travel"], look: .gen(.cardigan, A.Style(color: A.rgb(0xCDB79E), pattern: .ribbed)), fit: "Relaxed"),
        PieceSpec(key: "denimJacket", name: "Light denim jacket", category: .layers, group: "layers", color: "Light blue", brand: "Levi's", material: "Denim", season: "Spring", tags: ["casual", "weekend", "travel"], look: .gen(.jacket, made(0x6C8DB2, .denim, 0x3F618F)), fit: "Cropped"),
        PieceSpec(key: "leather", name: "Black leather jacket", category: .layers, group: "layers", color: "Black", brand: "AllSaints", material: "Leather", season: "Autumn and winter", tags: ["night out", "date night", "event"], look: .gen(.jacket, plain(0x1C1B1B)), fit: "Fitted"),
        PieceSpec(key: "coverUp", name: "White linen cover-up", category: .layers, group: "layers", color: "White", brand: "Zara", material: "Linen", season: "Summer", tags: ["beach", "vacation", "pool"], look: .gen(.blouse, plain(0xF4F1EA)), fit: "Oversized"),
        // Shoes
        PieceSpec(key: "sneakers", name: "Ivory sneakers", category: .shoes, group: "shoes", color: "Ivory", brand: "Veja", material: "Leather", season: "All year", tags: ["casual", "walking", "travel"], look: .art("sneakers"), fit: "True to size", notes: "Wipe clean after rain."),
        PieceSpec(key: "flats", name: "Black ballet flats", category: .shoes, group: "shoes", color: "Black", brand: "Sam Edelman", material: "Leather", season: "All year", tags: ["work", "formal"], look: .gen(.flats, plain(0x2B2A2A)), fit: "True to size"),
        PieceSpec(key: "heels", name: "Burgundy block heels", category: .shoes, group: "shoes", color: "Burgundy", brand: "Steve Madden", material: "Suede", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.heels, plain(0xB23A48)), fit: "True to size"),
        PieceSpec(key: "boots", name: "Brown ankle boots", category: .shoes, group: "shoes", color: "Brown", brand: "Dr. Martens", material: "Leather", season: "Autumn and winter", tags: ["casual", "city", "rain"], look: .gen(.boots, plain(0x3A2A22)), fit: "True to size"),
        // Sandals
        PieceSpec(key: "sandals", name: "Tan strappy sandals", category: .shoes, group: "sandals", color: "Tan", brand: "Steve Madden", material: "Leather", season: "Spring and summer", tags: ["sunday", "brunch", "vacation"], look: .gen(.sandal, plain(0xC08A55)), fit: "True to size"),
        PieceSpec(key: "slides", name: "White slides", category: .shoes, group: "sandals", color: "White", brand: "Birkenstock", material: "Rubber", season: "Summer", tags: ["beach", "pool", "vacation"], look: .gen(.sandal, plain(0xF4F1EA)), fit: "True to size"),
        PieceSpec(key: "goldSandals", name: "Gold flat sandals", category: .shoes, group: "sandals", color: "Gold", brand: "Havaianas", material: "Leather", season: "Summer", tags: ["event", "vacation", "wedding guest"], look: .gen(.sandal, plain(0xD9B45A)), fit: "True to size"),
        // Bags
        PieceSpec(key: "crossbody", name: "Tan crossbody bag", category: .accessories, group: "bags", color: "Tan", brand: "Cuyana", material: "Leather", season: "All year", tags: ["everyday", "casual", "travel"], look: .art("bag"), notes: "Fits phone, wallet and keys."),
        PieceSpec(key: "tote", name: "Straw tote bag", category: .accessories, group: "bags", color: "Natural", brand: "Mango", material: "Straw", season: "Summer", tags: ["beach", "vacation", "market"], look: .gen(.tote, plain(0xD9B88A))),
        PieceSpec(key: "clutch", name: "Black evening clutch", category: .accessories, group: "bags", color: "Black", brand: "Charles & Keith", material: "Satin", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.clutch, plain(0x24212A))),
        // Jewelry
        PieceSpec(key: "hoops", name: "Gold hoop earrings", category: .accessories, group: "jewelry", color: "Gold", brand: "Mejuri", material: "Gold vermeil", season: "All year", tags: ["everyday", "event", "formal"], look: .gen(.hoops, plain(0xCDA64E))),
        PieceSpec(key: "necklace", name: "Pendant necklace", category: .accessories, group: "jewelry", color: "Gold", brand: "Mejuri", material: "Gold vermeil", season: "All year", tags: ["formal", "event", "date night"], look: .gen(.necklace, plain(0xCDA64E))),
        PieceSpec(key: "watch", name: "Gold dress watch", category: .accessories, group: "jewelry", color: "Gold and brown", brand: "Daniel Wellington", material: "Stainless steel", season: "All year", tags: ["work", "formal"], look: .gen(.watch, plain(0x3A2A22))),
        // Hats and sunglasses
        PieceSpec(key: "hat", name: "Wide-brim sun hat", category: .accessories, group: "sunwear", color: "Straw", brand: "Lack of Color", material: "Straw", season: "Summer", tags: ["beach", "vacation", "sunday"], look: .gen(.sunHat, plain(0xE2C98F))),
        PieceSpec(key: "sunglasses", name: "Black sunglasses", category: .accessories, group: "sunwear", color: "Black", brand: "Ray-Ban", material: "Acetate", season: "All year", tags: ["everyday", "beach", "vacation"], look: .gen(.sunglasses, plain(0x2A2523))),
        // Accessories
        PieceSpec(key: "belt", name: "Brown leather belt", category: .accessories, group: "accessories", color: "Brown", brand: "Everlane", material: "Leather", season: "All year", tags: ["work", "casual"], look: .gen(.belt, plain(0x6A3F2A))),
        PieceSpec(key: "scarf", name: "Polka dot silk scarf", category: .accessories, group: "accessories", color: "Coral", brand: "Furla", material: "Silk", season: "All year", tags: ["work", "travel", "event"], look: .gen(.scarf, made(0xD76E5A, .dots, 0xF7E8D0))),
        // Swimwear
        PieceSpec(key: "onePiece", name: "Navy one-piece swimsuit", category: .dresses, group: "swimwear", color: "Navy", brand: "Hunza G", material: "Stretch nylon", season: "Summer", tags: ["pool", "beach", "vacation"], look: .gen(.onePiece, plain(0x1F4E79)), fit: "Fitted"),
        PieceSpec(key: "bikini", name: "Coral bikini set", category: .tops, group: "bikinis", color: "Coral", brand: "Seafolly", material: "Stretch nylon", season: "Summer", tags: ["beach", "vacation", "island"], look: .gen(.bikini, plain(0xE56B4E)), fit: "Adjustable")
    ]

    private static let newCategories: [WardrobeCategory] = [
        WardrobeCategory(id: "camis", name: "Camis and tanks", type: .tops), WardrobeCategory(id: "knitwear", name: "Knitwear", type: .tops),
        WardrobeCategory(id: "denim", name: "Denim", type: .bottoms), WardrobeCategory(id: "skirts", name: "Skirts", type: .bottoms),
        WardrobeCategory(id: "sandals", name: "Sandals and slides", type: .shoes), WardrobeCategory(id: "bags", name: "Bags", type: .accessories),
        WardrobeCategory(id: "jewelry", name: "Jewelry and watches", type: .accessories), WardrobeCategory(id: "sunwear", name: "Hats and sunglasses", type: .accessories),
        WardrobeCategory(id: "swimwear", name: "Swimsuits", type: .dresses), WardrobeCategory(id: "bikinis", name: "Bikinis", type: .tops)
    ]

    private static let looks: [(name: String, keys: [String], occasion: String, mood: String)] = [
        ("Office day", ["blouseCream", "trousersWide", "flats", "belt", "tote"], "Work", "Polished"),
        ("Client meeting", ["blazerBlack", "tee", "trousersBlack", "heels", "watch"], "Work", "Confident"),
        ("Presentation day", ["dressShirt", "blazerBeige", "flats", "watch"], "Work", "Sharp"),
        ("Casual Friday", ["breton", "jeans", "sneakers", "crossbody"], "Work", "Relaxed"),
        ("Formal dinner", ["dressBlack", "heels", "clutch", "hoops"], "Formal", "Elegant"),
        ("Black tie optional", ["dressWine", "heels", "clutch", "necklace"], "Formal", "Refined"),
        ("Wedding guest", ["dressSage", "goldSandals", "clutch", "hoops"], "Event", "Celebratory"),
        ("Cocktail night", ["dressBlack", "blazerBlack", "heels", "clutch", "necklace"], "Event", "Glamorous"),
        ("Birthday dinner", ["camiLilac", "midiSkirt", "heels", "clutch", "hoops"], "Event", "Festive"),
        ("Coffee run", ["tee", "jeans", "sneakers", "crossbody", "sunglasses"], "Casual", "Easy"),
        ("Errands day", ["tank", "jeansBlack", "sneakers", "tote"], "Casual", "Comfortable"),
        ("City layers", ["knit", "trench", "jeans", "boots", "crossbody"], "Casual", "Cozy"),
        ("Park walk", ["cropGingham", "shorts", "sneakers", "hat"], "Casual", "Sunny"),
        ("Weekend ease", ["dressCream", "sneakers", "crossbody"], "Weekend", "Relaxed"),
        ("Brunch with friends", ["blouseSage", "linen", "goldSandals", "tote", "sunglasses"], "Weekend", "Fresh"),
        ("Sunday market", ["dressGingham", "sandals", "tote", "hat"], "Sunday", "Laid back"),
        ("Slow Sunday", ["knit", "jeans", "sneakers"], "Sunday", "Cozy"),
        ("Beach walk", ["bikini", "coverUp", "hat", "sunglasses", "slides", "tote"], "Beach", "Breezy"),
        ("Beach sunset dinner", ["dressFloral", "goldSandals", "hoops", "crossbody"], "Beach", "Golden hour"),
        ("Pool day", ["onePiece", "coverUp", "hat", "sunglasses", "slides"], "Beach", "Easy"),
        ("Island hopping", ["bikini", "shorts", "coverUp", "hat", "sunglasses", "slides"], "Vacation", "Adventurous"),
        ("Boracay arrival", ["dressSage", "slides", "tote", "sunglasses"], "Vacation", "Excited"),
        ("Travel day", ["tee", "jeansBlack", "sneakers", "cardigan", "tote"], "Travel", "Comfortable"),
        ("Girls night out", ["cropRed", "denimSkirt", "heels", "clutch", "hoops"], "Night out", "Playful"),
        ("Date night", ["dressCream", "leather", "heels", "clutch", "necklace"], "Date night", "Romantic"),
        ("Rainy day", ["breton", "trench", "jeans", "boots"], "Casual", "Practical")
    ]

    private static let themes: [(name: String, text: String, looks: [String])] = [
        ("Work week", "Polished looks for the office.", ["Office day", "Client meeting", "Presentation day", "Casual Friday"]),
        ("Formal", "Dressed up for dinners and evenings.", ["Formal dinner", "Black tie optional"]),
        ("Events", "Weddings, parties and cocktails.", ["Wedding guest", "Cocktail night", "Birthday dinner"]),
        ("Casual", "Everyday looks that need no thought.", ["Coffee run", "Errands day", "City layers", "Park walk", "Rainy day"]),
        ("Weekend", "Easy looks for time off.", ["Weekend ease", "Brunch with friends"]),
        ("Sundays", "Slow mornings and the market.", ["Sunday market", "Slow Sunday"]),
        ("Beach", "Light layers for sand and sunsets.", ["Beach walk", "Beach sunset dinner", "Pool day"]),
        ("Boracay trip", "Everything for the island holiday.", ["Boracay arrival", "Island hopping", "Beach walk", "Beach sunset dinner", "Pool day", "Travel day"]),
        ("Travel capsule", "Layers that mix for a short trip.", ["Travel day", "City layers", "Rainy day"]),
        ("Night out", "Dressier looks for after dark.", ["Girls night out", "Date night", "Cocktail night"]),
        ("Date night", "Romantic evenings.", ["Date night", "Formal dinner"]),
        ("Ideas to collect", "Looks to try next.", [])
    ]

    /// Occasion and look for each day of the planned week, starting today.
    private static let week: [(occasion: String, look: String)] = [
        ("Team stand-up and design review", "Office day"), ("Coffee with Maya", "Coffee run"), ("Client presentation", "Presentation day"), ("Errands and pharmacy", "Errands day"),
        ("Birthday dinner", "Birthday dinner"), ("Brunch with friends", "Brunch with friends"), ("Sunday market and park", "Sunday market")
    ]

    /// The island trip a month from now.
    private static let trip: [(occasion: String, look: String)] = [
        ("Flight to Caticlan", "Travel day"), ("Boat transfer and beach walk", "Boracay arrival"), ("Island hopping", "Island hopping"),
        ("Pool morning and spa", "Pool day"), ("Sunset dinner at White Beach", "Beach sunset dinner"), ("Flight home", "Travel day")
    ]

    /// Past days and the look worn on each, so wear history and insights have a fortnight behind them.
    private static let worn: [(daysAgo: Int, look: String)] = [
        (1, "Office day"), (2, "Rainy day"), (3, "Casual Friday"), (4, "Weekend ease"), (5, "Brunch with friends"), (6, "Slow Sunday"),
        (8, "Client meeting"), (9, "Coffee run"), (10, "Girls night out"), (12, "Park walk")
    ]

    enum Failure: Error { case missingArtwork, seedFailed(String) }

    private static func receiptURL(_ directory: URL) -> URL { directory.appendingPathComponent("AQD-week-seed.json") }

    static func run(store: PieceStore, outputDirectory: URL, now: Date = Date(), timeZone: TimeZone = .current) async throws -> Receipt {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let backupName = "AQD-before-week-seed-\(UUID().uuidString).aqdarchive"
        let archive = try await LocalArchiveService.create(store: store)
        try LocalArchiveIO.write(archive.data, to: outputDirectory.appendingPathComponent(backupName))
        do { try wipeCloset(store: store) } catch { throw Failure.seedFailed("cleanup: \(error)") }

        var receipt = Receipt(backup: backupName)
        let owner = try store.todayConfiguration().ownerID
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        func day(_ offset: Int) throws -> LocalPlanDay {
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { throw Failure.seedFailed("date") }
            return LocalPlanDay(date: date, timeZone: timeZone)
        }
        var stage = "categories"
        do {
            let current = try store.localExperience().pieceCategories ?? WardrobeCategory.defaults
            let known = Set(current.map(\.id))
            try store.savePieceCategories(current + newCategories.filter { !known.contains($0.id) }, expected: current)

            stage = "pieces"
            let preparer = PhotoPreparer()
            var piecesByKey: [String: WardrobePiece] = [:]
            for (index, spec) in specs.enumerated() {
                let imageData: Data
                switch spec.look {
                case .art(let key):
                    guard let data = WelcomeGarments.images[key]?.pngData() else { throw Failure.missingArtwork }
                    imageData = data
                case .gen(let shape, let style): imageData = GarmentArt.png(shape, style)
                }
                let photoID = try store.acceptPhoto(try await preparer.prepare(data: imageData))
                let size: String = {
                    switch spec.category {
                    case .shoes: return "EU 38"
                    case .accessories: return spec.group == "bags" || spec.group == "sunwear" || spec.group == "jewelry" ? "One size" : "S"
                    case .bottoms: return spec.group == "denim" ? "26" : "S"
                    default: return "S"
                    }
                }()
                var details = PieceDetails(color: spec.color, brand: spec.brand, size: size, fit: spec.fit, material: spec.material, season: spec.season,
                                           condition: index % 4 == 0 ? "Like new" : "Good", ownershipAge: ["6 months", "1 year", "2 years", "3 years"][index % 4],
                                           tags: spec.tags, notes: spec.notes, priorWearCount: 4 + (index * 7) % 40)
                details.organizationCategoryID = spec.group
                let piece = try store.savePiece(PieceDraft(name: spec.name, category: spec.category, photoID: photoID, details: details), operationID: UUID())
                piecesByKey[spec.key] = piece; receipt.pieces.append(piece.id)
            }
            let pieces = specs.compactMap { piecesByKey[$0.key] }

            stage = "outfits"
            var outfitsByName: [String: Outfit] = [:]
            for look in looks {
                var draft = OutfitDraft(ownerID: owner)
                draft.name = look.name; draft.occasion = look.occasion; draft.mood = look.mood
                for key in look.keys { guard let piece = piecesByKey[key] else { throw Failure.seedFailed("missing piece \(key)") }; draft.select(piece.id) }
                try draft.reviewCurrentPieces(pieces)
                try store.saveOutfitDraft(draft)
                let outfit = try store.saveOutfit(draft)
                try store.acknowledgeOutfitReceipt(draft)
                outfitsByName[look.name] = outfit; receipt.outfits.append(outfit.id)
            }

            stage = "themes"
            for theme in themes {
                var draft = ThemeDraft(ownerID: owner)
                draft.name = theme.name; draft.description = theme.text
                draft.outfitIDs = try theme.looks.map { name in guard let outfit = outfitsByName[name] else { throw Failure.seedFailed("missing outfit \(name)") }; return outfit.id }
                try store.saveThemeDraft(draft)
                let saved = try store.saveTheme(draft)
                try store.finishThemeDraft(draft)
                receipt.themes.append(saved.id)
            }
            // Saving themes can bump outfit revisions; plans, wear and fits must reference the current ones.
            let currentOutfits = try store.outfits()
            for (name, outfit) in outfitsByName { outfitsByName[name] = currentOutfits.first(where: { $0.id == outfit.id }) ?? outfit }

            stage = "plan"
            var plan = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "This week", start: try day(0), end: try day(6)))
            for (index, entry) in week.enumerated() where index < plan.slots.count { plan.slots[index].occasion = entry.occasion; plan.slots[index].outfit = outfitsByName[entry.look] }
            plan.reviewing = true
            try store.savePlanAuthoringDraft(plan)
            receipt.plans.append(try store.savePlanAuthoring(plan).plan.id)
            try store.finishPlanAuthoring(plan)

            var tripPlan = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Boracay trip", start: try day(30), end: try day(30 + trip.count - 1),
                                                                        trip: TripConfiguration(destination: "Boracay", activities: ["Beach", "Island hopping", "Sunset dinner"])))
            for (index, entry) in trip.enumerated() where index < tripPlan.slots.count { tripPlan.slots[index].occasion = entry.occasion; tripPlan.slots[index].outfit = outfitsByName[entry.look] }
            tripPlan.reviewing = true
            try store.savePlanAuthoringDraft(tripPlan)
            receipt.plans.append(try store.savePlanAuthoring(tripPlan).plan.id)
            try store.finishPlanAuthoring(tripPlan)

            stage = "wear"
            for entry in worn {
                guard let outfit = outfitsByName[entry.look], let look = looks.first(where: { $0.name == entry.look }) else { continue }
                let wearPieces = look.keys.compactMap { piecesByKey[$0] }
                let draft = OutfitWearDraft(ownerID: owner, outfitID: outfit.id, pieces: wearPieces, day: try day(-entry.daysAgo))
                try store.saveWearDraft(draft)
                receipt.wear.append(try store.saveWear(draft).id)
                try store.finishWearDraft(draft)
            }

            stage = "fits"
            let fitNotes: [(String, String, String?, Int)] = [
                ("Light blue coat over a dress for a drizzly city walk.", "Rainy day", "tour-fit-blue-coat", 3),
                ("Burgundy layers and sunglasses for a shopping afternoon.", "City layers", "tour-fit-street", 5),
                ("Linen and sandals for a long brunch in the sun.", "Brunch with friends", nil, 4),
                ("Satin and heels for a birthday dinner.", "Birthday dinner", nil, 9),
                ("Blazer and wide trousers for the client meeting.", "Client meeting", nil, 8)
            ]
            for (note, lookName, photo, daysAgo) in fitNotes {
                guard let outfit = outfitsByName[lookName] else { continue }
                var fit = FitDraft(ownerID: owner)
                if let photo, let url = Foundation.Bundle.main.url(forResource: photo, withExtension: "jpg") {
                    fit.value.photoID = try store.acceptPhoto(try await preparer.prepare(data: Data(contentsOf: url)))
                }
                fit.value.outfit = try FitOutfitSnapshot(outfit: outfit, pieces: pieces)
                fit.value.note = note; fit.value.day = try day(-daysAgo)
                try store.saveFitDraft(fit)
                receipt.fits.append(try store.saveFit(fit).id)
                try store.finishFitDraft(fit)
            }

            // Style answers are saved once; a repeat run keeps what is already there.
            do {
                var answers = StylePreferences()
                for (step, choices) in [(0, ["Plan outfits faster", "Try new combinations"]), (1, ["Work", "Evenings", "Travel"]), (2, ["Classic", "Minimal"]), (3, ["Regular", "Relaxed"])] {
                    for choice in choices { answers.choose(choice, at: step) }
                }
                answers.body.decline(); answers.colors.declined = true
                var style = StylePreferenceDraft(source: .settings, answers: answers); style.page = 6
                try store.saveStyleDraft(style)
                _ = try store.saveStylePreferences(style)
                try store.acknowledgeStyleReceipt(operationID: style.operationID)
            } catch { /* optional content; the closet seed does not depend on it */ }
        } catch let failure as Failure { throw failure } catch { throw Failure.seedFailed("\(stage): \(error)") }

        // Widgets for every Today card: a saved note, a saved photo, themes, fit journal and the rest.
        _ = try? await PreviewSampleContent.addAllWidgets(store: store, outputDirectory: outputDirectory)

        try LocalArchiveIO.write(try JSONEncoder().encode(receipt), to: receiptURL(outputDirectory))
        return receipt
    }

    /// Empties the closet in dependency order: wear, plans, fits, themes, outfits, then pieces. The profile, settings and chats stay.
    private static func wipeCloset(store: PieceStore) throws {
        for record in try store.wearRecords() { try store.applyHistoryMutation(HistoryMutation(action: .undoWear(record))) }
        let entries = try store.planEntries()
        for plan in try store.planDefinitions() {
            try store.applyHistoryMutation(HistoryMutation(action: .deletePlan(plan, entries.filter { $0.planID == plan.id })))
        }
        for entry in try store.planEntries() { try store.deletePlanEntry(PlanEntryDeletionRequest(entry: entry)) }
        for memory in try store.fitMemories() { try store.deleteFit(FitDeletionRequest(memory: memory)) }
        for theme in try store.themes() { try store.deleteTheme(ThemeDeletionRequest(theme: theme)) }
        for outfit in try store.outfits() { _ = try store.applyOutfitMutation(try store.outfitDeletionReview(id: outfit.id)) }
        for piece in try store.pieces() + store.pieces(archived: true) {
            try store.deletePiece(id: piece.id, expectedRevision: piece.revision, operationID: UUID(), impact: try store.pieceDeletionImpact(id: piece.id))
        }
    }
}
#endif
