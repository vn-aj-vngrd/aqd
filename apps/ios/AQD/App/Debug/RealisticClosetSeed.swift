#if DEBUG
import AQDCore
import Foundation
import UIKit

/// Debug-only owner preview for internal testing: Angelika Domingo, a woman in her mid twenties, with a full closet, outfits,
/// themes, a planned week and trip, two weeks of wear, fit memories, a profile and complete style preferences.
/// It first writes a backup archive, then empties the closet (pieces, outfits, themes, plans, wear and fits) and replaces the
/// profile and style answers. Settings, chats and onboarding progress stay. The app itself always starts empty.
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
    private static func plain(_ hex: UInt32, _ material: A.Material = .cotton) -> A.Style { A.Style(color: A.rgb(hex), material: material) }
    private static func made(_ hex: UInt32, _ pattern: A.Pattern, _ ink: UInt32, _ material: A.Material = .cotton) -> A.Style { A.Style(color: A.rgb(hex), pattern: pattern, patternColor: A.rgb(ink), material: material) }

    /// A woman's wardrobe in her mid twenties across every category. Seven items use the bundled illustrations; the rest are drawn.
    private static let specs: [PieceSpec] = [
        // Shirts
        PieceSpec(key: "tee", name: "Classic white tee", category: .tops, group: "tops", color: "White", brand: "Uniqlo", material: "Cotton jersey", season: "All year", tags: ["basic", "casual", "work"], look: .gen(.tee, plain(0xF4F1EA)), fit: "Regular"),
        PieceSpec(key: "breton", name: "Breton striped tee", category: .tops, group: "tops", color: "Navy and white", brand: "Saint James", material: "Cotton", season: "Spring and summer", tags: ["casual", "weekend", "vacation"], look: .gen(.tee, made(0xF4F1EA, .stripes, 0x24365E)), fit: "Regular"),
        PieceSpec(key: "blouseCream", name: "Cream poplin blouse", category: .tops, group: "tops", color: "Cream", brand: "COS", material: "Cotton poplin", season: "All year", tags: ["work", "formal", "brunch"], look: .gen(.blouse, plain(0xF2E6D8)), fit: "Relaxed", notes: "Steam before wearing."),
        PieceSpec(key: "blouseSage", name: "Sage linen blouse", category: .tops, group: "tops", color: "Sage", brand: "Mango", material: "Linen", season: "Spring and summer", tags: ["brunch", "vacation", "weekend"], look: .gen(.blouse, plain(0x9DB59A, .linen)), fit: "Relaxed"),
        PieceSpec(key: "cropGingham", name: "Gingham crop top", category: .tops, group: "tops", color: "Blue gingham", brand: "Zara", material: "Cotton", season: "Summer", tags: ["casual", "beach", "sunday"], look: .gen(.crop, made(0xF2EEE6, .gingham, 0x3E6FA8)), fit: "Cropped"),
        // Camis and tanks
        PieceSpec(key: "tank", name: "Black fitted tank", category: .tops, group: "camis", color: "Black", brand: "Skims", material: "Stretch cotton", season: "All year", tags: ["basic", "layering", "vacation"], look: .gen(.tank, plain(0x1E1E20)), fit: "Fitted"),
        PieceSpec(key: "camiBlush", name: "Blush silk cami", category: .tops, group: "camis", color: "Blush", brand: "& Other Stories", material: "Silk", season: "All year", tags: ["date night", "formal", "layering"], look: .gen(.cami, plain(0xD9B8A8, .satin)), fit: "Slim", notes: "Hand wash."),
        PieceSpec(key: "camiLilac", name: "Lilac satin cami", category: .tops, group: "camis", color: "Lilac", brand: "Reformation", material: "Satin", season: "All year", tags: ["event", "night out", "birthday"], look: .gen(.cami, plain(0xB9A3D6, .satin)), fit: "Slim"),
        // Knitwear
        PieceSpec(key: "knit", name: "Ivory ribbed knit", category: .tops, group: "knitwear", color: "Ivory", brand: "COS", material: "Merino wool", season: "Autumn and winter", tags: ["cozy", "sunday", "layering"], look: .art("knit"), fit: "Fitted", notes: "Hand wash cold and dry flat."),
        PieceSpec(key: "cropRed", name: "Red cropped knit", category: .tops, group: "knitwear", color: "Red", brand: "Zara", material: "Cotton blend", season: "Autumn", tags: ["night out", "casual", "event"], look: .gen(.crop, plain(0xC85A6B, .knit)), fit: "Cropped"),
        // Bottoms
        PieceSpec(key: "trousersWide", name: "Wide-leg trousers", category: .bottoms, group: "bottoms", color: "Charcoal", brand: "Zara", material: "Wool blend", season: "All year", tags: ["work", "formal", "tailored"], look: .gen(.pants(.wide), plain(0x4A4B50, .wool)), fit: "Wide leg", notes: "Dry clean only."),
        PieceSpec(key: "trousersBlack", name: "Black straight trousers", category: .bottoms, group: "bottoms", color: "Black", brand: "COS", material: "Crepe", season: "All year", tags: ["work", "formal", "travel"], look: .gen(.pants(.straight), plain(0x1E1E20, .wool)), fit: "Straight"),
        PieceSpec(key: "linen", name: "Linen trousers", category: .bottoms, group: "bottoms", color: "Sand", brand: "Mango", material: "Linen", season: "Summer", tags: ["brunch", "vacation", "beach"], look: .art("linen"), fit: "Wide leg", notes: "Steam before wearing."),
        PieceSpec(key: "shorts", name: "Tailored shorts", category: .bottoms, group: "bottoms", color: "Beige", brand: "H&M", material: "Cotton twill", season: "Summer", tags: ["vacation", "casual", "beach"], look: .gen(.shorts, plain(0xD9CBB3, .linen)), fit: "Regular"),
        // Denim
        PieceSpec(key: "jeans", name: "Indigo straight jeans", category: .bottoms, group: "denim", color: "Indigo", brand: "Levi's", material: "Denim", season: "All year", tags: ["casual", "everyday", "weekend"], look: .art("jeans"), fit: "High rise, straight"),
        PieceSpec(key: "jeansBlack", name: "Black skinny jeans", category: .bottoms, group: "denim", color: "Black", brand: "Zara", material: "Stretch denim", season: "All year", tags: ["casual", "night out", "travel"], look: .gen(.pants(.skinny), made(0x242428, .denim, 0x111111, .denim)), fit: "Skinny"),
        PieceSpec(key: "denimSkirt", name: "Denim mini skirt", category: .bottoms, group: "denim", color: "Light blue", brand: "Levi's", material: "Denim", season: "Spring and summer", tags: ["casual", "night out", "weekend"], look: .gen(.skirt(.mini, pleated: false), made(0x6C8DB2, .denim, 0x3F618F, .denim)), fit: "A-line"),
        // Skirts
        PieceSpec(key: "midiSkirt", name: "Pleated midi skirt", category: .bottoms, group: "skirts", color: "Champagne", brand: "& Other Stories", material: "Satin", season: "All year", tags: ["event", "birthday", "formal"], look: .gen(.skirt(.midi, pleated: true), plain(0xC9B79C, .satin)), fit: "Flowy"),
        // Dresses
        PieceSpec(key: "dressCream", name: "Cream midi dress", category: .dresses, group: "dresses", color: "Cream", brand: "& Other Stories", material: "Cotton blend", season: "Spring and summer", tags: ["weekend", "date night", "event"], look: .art("dress"), fit: "A-line", notes: "Wear with a slip underneath."),
        PieceSpec(key: "dressBlack", name: "Little black dress", category: .dresses, group: "dresses", color: "Black", brand: "Reformation", material: "Crepe", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.dress(.mini, sleeves: false), plain(0x1A1A1D)), fit: "Fitted"),
        PieceSpec(key: "dressFloral", name: "Floral maxi dress", category: .dresses, group: "dresses", color: "Pink floral", brand: "Rouje", material: "Viscose", season: "Summer", tags: ["vacation", "beach", "sunday"], look: .gen(.dress(.maxi, sleeves: false), made(0xF4EFE6, .floral, 0xD0678A)), fit: "Flowy"),
        PieceSpec(key: "dressWine", name: "Wine wrap dress", category: .dresses, group: "dresses", color: "Wine", brand: "Mango", material: "Crepe", season: "Autumn and winter", tags: ["formal", "event", "wedding guest"], look: .gen(.dress(.midi, sleeves: true), plain(0x8A2F45, .satin)), fit: "Wrap"),
        PieceSpec(key: "dressGingham", name: "Gingham sundress", category: .dresses, group: "dresses", color: "Blue gingham", brand: "Zara", material: "Cotton", season: "Summer", tags: ["sunday", "market", "vacation"], look: .gen(.dress(.midi, sleeves: false), made(0xF2EEE6, .gingham, 0x3E6FA8)), fit: "A-line"),
        PieceSpec(key: "dressSage", name: "Sage slip dress", category: .dresses, group: "dresses", color: "Sage", brand: "Realisation Par", material: "Satin", season: "All year", tags: ["wedding guest", "event", "vacation"], look: .gen(.dress(.midi, sleeves: false), plain(0x9DB59A, .satin)), fit: "Slip"),
        PieceSpec(key: "dressShirt", name: "Navy shirt dress", category: .dresses, group: "dresses", color: "Navy", brand: "Massimo Dutti", material: "Cotton poplin", season: "All year", tags: ["work", "tailored"], look: .gen(.dress(.midi, sleeves: true), plain(0x24365E)), fit: "Relaxed"),
        // Layers
        PieceSpec(key: "trench", name: "Navy trench coat", category: .layers, group: "layers", color: "Navy", brand: "Mango", material: "Cotton gabardine", season: "Spring and autumn", tags: ["rain", "work", "travel"], look: .art("coat"), fit: "Relaxed", notes: "The belt is detachable."),
        PieceSpec(key: "blazerBlack", name: "Black blazer", category: .layers, group: "layers", color: "Black", brand: "Zara", material: "Wool blend", season: "All year", tags: ["work", "formal", "event"], look: .gen(.blazer, plain(0x2A2C33, .wool)), fit: "Tailored"),
        PieceSpec(key: "blazerBeige", name: "Oatmeal linen blazer", category: .layers, group: "layers", color: "Oatmeal", brand: "Massimo Dutti", material: "Linen blend", season: "Spring and summer", tags: ["work", "brunch", "formal"], look: .gen(.blazer, plain(0xD9C7A8, .linen)), fit: "Relaxed"),
        PieceSpec(key: "cardigan", name: "Camel cardigan", category: .layers, group: "layers", color: "Camel", brand: "COS", material: "Wool", season: "Autumn and winter", tags: ["cozy", "work", "travel"], look: .gen(.cardigan, A.Style(color: A.rgb(0xCDB79E), pattern: .ribbed, material: .knit)), fit: "Relaxed"),
        PieceSpec(key: "denimJacket", name: "Light denim jacket", category: .layers, group: "layers", color: "Light blue", brand: "Levi's", material: "Denim", season: "Spring", tags: ["casual", "weekend", "travel"], look: .gen(.jacket, made(0x6C8DB2, .denim, 0x3F618F, .denim)), fit: "Cropped"),
        PieceSpec(key: "leather", name: "Black leather jacket", category: .layers, group: "layers", color: "Black", brand: "AllSaints", material: "Leather", season: "Autumn and winter", tags: ["night out", "date night", "event"], look: .gen(.jacket, plain(0x1C1B1B, .leather)), fit: "Fitted"),
        PieceSpec(key: "coverUp", name: "White linen cover-up", category: .layers, group: "layers", color: "White", brand: "Zara", material: "Linen", season: "Summer", tags: ["beach", "vacation", "pool"], look: .gen(.blouse, plain(0xF4F1EA, .linen)), fit: "Oversized"),
        // Shoes
        PieceSpec(key: "sneakers", name: "Ivory sneakers", category: .shoes, group: "shoes", color: "Ivory", brand: "Veja", material: "Leather", season: "All year", tags: ["casual", "walking", "travel"], look: .art("sneakers"), fit: "True to size", notes: "Wipe clean after rain."),
        PieceSpec(key: "flats", name: "Black ballet flats", category: .shoes, group: "shoes", color: "Black", brand: "Sam Edelman", material: "Leather", season: "All year", tags: ["work", "formal"], look: .gen(.flats, plain(0x2B2A2A, .leather)), fit: "True to size"),
        PieceSpec(key: "heels", name: "Burgundy block heels", category: .shoes, group: "shoes", color: "Burgundy", brand: "Steve Madden", material: "Suede", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.heels, plain(0xB23A48, .suede)), fit: "True to size"),
        PieceSpec(key: "boots", name: "Brown ankle boots", category: .shoes, group: "shoes", color: "Brown", brand: "Dr. Martens", material: "Leather", season: "Autumn and winter", tags: ["casual", "city", "rain"], look: .gen(.boots, plain(0x3A2A22, .leather)), fit: "True to size"),
        // Sandals
        PieceSpec(key: "sandals", name: "Tan strappy sandals", category: .shoes, group: "sandals", color: "Tan", brand: "Steve Madden", material: "Leather", season: "Spring and summer", tags: ["sunday", "brunch", "vacation"], look: .gen(.sandal, plain(0xC08A55, .leather)), fit: "True to size"),
        PieceSpec(key: "slides", name: "White slides", category: .shoes, group: "sandals", color: "White", brand: "Birkenstock", material: "Rubber", season: "Summer", tags: ["beach", "pool", "vacation"], look: .gen(.sandal, plain(0xF4F1EA, .rubber)), fit: "True to size"),
        PieceSpec(key: "goldSandals", name: "Gold flat sandals", category: .shoes, group: "sandals", color: "Gold", brand: "Havaianas", material: "Leather", season: "Summer", tags: ["event", "vacation", "wedding guest"], look: .gen(.sandal, plain(0xD9B45A, .leather)), fit: "True to size"),
        // Bags
        PieceSpec(key: "crossbody", name: "Tan crossbody bag", category: .accessories, group: "bags", color: "Tan", brand: "Cuyana", material: "Leather", season: "All year", tags: ["everyday", "casual", "travel"], look: .art("bag"), notes: "Fits phone, wallet and keys."),
        PieceSpec(key: "tote", name: "Straw tote bag", category: .accessories, group: "bags", color: "Natural", brand: "Mango", material: "Straw", season: "Summer", tags: ["beach", "vacation", "market"], look: .gen(.tote, plain(0xD9B88A, .straw))),
        PieceSpec(key: "clutch", name: "Black evening clutch", category: .accessories, group: "bags", color: "Black", brand: "Charles & Keith", material: "Satin", season: "All year", tags: ["formal", "event", "night out"], look: .gen(.clutch, plain(0x24212A, .satin))),
        // Jewelry
        PieceSpec(key: "hoops", name: "Gold hoop earrings", category: .accessories, group: "jewelry", color: "Gold", brand: "Mejuri", material: "Gold vermeil", season: "All year", tags: ["everyday", "event", "formal"], look: .gen(.hoops, plain(0xCDA64E, .metal))),
        PieceSpec(key: "necklace", name: "Pendant necklace", category: .accessories, group: "jewelry", color: "Gold", brand: "Mejuri", material: "Gold vermeil", season: "All year", tags: ["formal", "event", "date night"], look: .gen(.necklace, plain(0xCDA64E, .metal))),
        PieceSpec(key: "watch", name: "Gold dress watch", category: .accessories, group: "jewelry", color: "Gold and brown", brand: "Daniel Wellington", material: "Stainless steel", season: "All year", tags: ["work", "formal"], look: .gen(.watch, plain(0x3A2A22, .leather))),
        // Hats and sunglasses
        PieceSpec(key: "hat", name: "Wide-brim sun hat", category: .accessories, group: "sunwear", color: "Straw", brand: "Lack of Color", material: "Straw", season: "Summer", tags: ["beach", "vacation", "sunday"], look: .gen(.sunHat, plain(0xE2C98F, .straw))),
        PieceSpec(key: "sunglasses", name: "Black sunglasses", category: .accessories, group: "sunwear", color: "Black", brand: "Ray-Ban", material: "Acetate", season: "All year", tags: ["everyday", "beach", "vacation"], look: .gen(.sunglasses, plain(0x2A2523, .rubber))),
        // Accessories
        PieceSpec(key: "belt", name: "Brown leather belt", category: .accessories, group: "accessories", color: "Brown", brand: "Everlane", material: "Leather", season: "All year", tags: ["work", "casual"], look: .gen(.belt, plain(0x6A3F2A, .leather))),
        PieceSpec(key: "scarf", name: "Polka dot silk scarf", category: .accessories, group: "accessories", color: "Coral", brand: "Furla", material: "Silk", season: "All year", tags: ["work", "travel", "event"], look: .gen(.scarf, made(0xD76E5A, .dots, 0xF7E8D0))),
        // Swimwear
        PieceSpec(key: "onePiece", name: "Navy one-piece swimsuit", category: .dresses, group: "swimwear", color: "Navy", brand: "Hunza G", material: "Stretch nylon", season: "Summer", tags: ["pool", "beach", "vacation"], look: .gen(.onePiece, plain(0x1F4E79)), fit: "Fitted"),
        PieceSpec(key: "bikini", name: "Coral bikini set", category: .tops, group: "bikinis", color: "Coral", brand: "Seafolly", material: "Stretch nylon", season: "Summer", tags: ["beach", "vacation", "island"], look: .gen(.bikini, plain(0xE56B4E)), fit: "Adjustable")
    ]


    /// The rest of a real closet: more colorways of the staples, activewear, loungewear and a full set of accessories.
    private static let extraSpecs: [PieceSpec] = [
        // Tops
        PieceSpec(key: "teeBlack", name: "Black crew tee", category: .tops, group: "tops", color: "Black", brand: "Uniqlo", material: "Cotton jersey", season: "All year", tags: ["basic", "casual", "travel"], look: .gen(.tee, plain(0x1E1E20)), fit: "Regular"),
        PieceSpec(key: "teeGrey", name: "Heather grey tee", category: .tops, group: "tops", color: "Grey", brand: "Everlane", material: "Cotton", season: "All year", tags: ["basic", "weekend", "lounge"], look: .gen(.tee, plain(0x9A9A9E)), fit: "Relaxed"),
        PieceSpec(key: "teeOlive", name: "Olive boxy tee", category: .tops, group: "tops", color: "Olive", brand: "COS", material: "Heavy cotton", season: "All year", tags: ["casual", "weekend"], look: .gen(.tee, plain(0x6B6B47)), fit: "Boxy"),
        PieceSpec(key: "teeStripeRed", name: "Red striped tee", category: .tops, group: "tops", color: "Cream and red", brand: "Armor Lux", material: "Cotton", season: "Spring and summer", tags: ["casual", "vacation"], look: .gen(.tee, made(0xF4F1EA, .stripes, 0xB23A48)), fit: "Regular"),
        PieceSpec(key: "blouseWhite", name: "White button-down shirt", category: .tops, group: "tops", color: "White", brand: "Uniqlo", material: "Oxford cotton", season: "All year", tags: ["work", "classic", "travel"], look: .gen(.blouse, plain(0xF7F5F0)), fit: "Relaxed"),
        PieceSpec(key: "blouseBlue", name: "Blue striped shirt", category: .tops, group: "tops", color: "Blue stripe", brand: "J.Crew", material: "Cotton poplin", season: "All year", tags: ["work", "weekend"], look: .gen(.blouse, made(0xEEF2F7, .stripes, 0x5C7FB0)), fit: "Oversized"),
        PieceSpec(key: "blouseSilk", name: "Ivory silk blouse", category: .tops, group: "tops", color: "Ivory", brand: "Equipment", material: "Silk", season: "All year", tags: ["work", "formal", "date night"], look: .gen(.blouse, plain(0xF1E9DA, .satin)), fit: "Relaxed", notes: "Dry clean only."),
        PieceSpec(key: "blouseFloral", name: "Ditsy floral blouse", category: .tops, group: "tops", color: "Navy floral", brand: "Rouje", material: "Viscose", season: "Spring and summer", tags: ["brunch", "date night"], look: .gen(.blouse, made(0x24365E, .floral, 0xE8B4C0)), fit: "Fitted"),
        PieceSpec(key: "blouseDot", name: "Polka dot blouse", category: .tops, group: "tops", color: "Black and white", brand: "Zara", material: "Crepe", season: "All year", tags: ["work", "brunch"], look: .gen(.blouse, made(0x1E1E20, .dots, 0xF4F1EA)), fit: "Relaxed"),
        PieceSpec(key: "cropWhite", name: "White eyelet crop top", category: .tops, group: "tops", color: "White", brand: "H&M", material: "Cotton eyelet", season: "Summer", tags: ["vacation", "beach", "brunch"], look: .gen(.crop, plain(0xF7F5F0)), fit: "Cropped"),
        PieceSpec(key: "cropDenim", name: "Chambray crop shirt", category: .tops, group: "tops", color: "Chambray", brand: "Madewell", material: "Chambray", season: "Spring and summer", tags: ["casual", "weekend"], look: .gen(.crop, made(0x8FA8C8, .denim, 0x5F7EA4, .denim)), fit: "Cropped"),
        PieceSpec(key: "tankWhite", name: "White ribbed tank", category: .tops, group: "camis", color: "White", brand: "Skims", material: "Rib cotton", season: "All year", tags: ["basic", "layering"], look: .gen(.tank, A.Style(color: A.rgb(0xF7F5F0), pattern: .ribbed, material: .knit)), fit: "Fitted"),
        PieceSpec(key: "tankMocha", name: "Mocha ribbed tank", category: .tops, group: "camis", color: "Mocha", brand: "Aritzia", material: "Rib cotton", season: "All year", tags: ["basic", "layering", "weekend"], look: .gen(.tank, A.Style(color: A.rgb(0x7B5E4E), pattern: .ribbed, material: .knit)), fit: "Fitted"),
        PieceSpec(key: "camiBlack", name: "Black satin cami", category: .tops, group: "camis", color: "Black", brand: "Aritzia", material: "Satin", season: "All year", tags: ["night out", "date night", "layering"], look: .gen(.cami, plain(0x1E1E20, .satin)), fit: "Slim"),
        PieceSpec(key: "camiChampagne", name: "Champagne lace cami", category: .tops, group: "camis", color: "Champagne", brand: "Reformation", material: "Silk and lace", season: "All year", tags: ["event", "wedding guest"], look: .gen(.cami, plain(0xDCC7A8, .satin)), fit: "Slim", notes: "Hand wash only."),
        // Knitwear
        PieceSpec(key: "knitNavy", name: "Navy merino crewneck", category: .tops, group: "knitwear", color: "Navy", brand: "Uniqlo", material: "Merino wool", season: "Autumn and winter", tags: ["work", "travel", "layering"], look: .gen(.cardigan, A.Style(color: A.rgb(0x24365E), pattern: .ribbed, material: .knit)), fit: "Regular"),
        PieceSpec(key: "knitCream", name: "Cream cable knit sweater", category: .tops, group: "knitwear", color: "Cream", brand: "Massimo Dutti", material: "Wool blend", season: "Winter", tags: ["cozy", "travel", "baguio"], look: .gen(.cardigan, A.Style(color: A.rgb(0xEFE6D6), pattern: .ribbed, material: .knit)), fit: "Oversized"),
        PieceSpec(key: "knitGrey", name: "Grey cashmere sweater", category: .tops, group: "knitwear", color: "Grey", brand: "Naadam", material: "Cashmere", season: "Autumn and winter", tags: ["cozy", "work"], look: .gen(.cardigan, A.Style(color: A.rgb(0xA3A3A6), pattern: .ribbed, material: .knit)), fit: "Relaxed", notes: "Store folded, never hung."),
        PieceSpec(key: "cardiBlack", name: "Black cropped cardigan", category: .layers, group: "layers", color: "Black", brand: "& Other Stories", material: "Knit", season: "All year", tags: ["layering", "office", "date night"], look: .gen(.cardigan, A.Style(color: A.rgb(0x1E1E20), pattern: .ribbed, material: .knit)), fit: "Cropped"),
        PieceSpec(key: "cardiSage", name: "Sage knit cardigan", category: .layers, group: "layers", color: "Sage", brand: "Sezane", material: "Cotton knit", season: "Spring", tags: ["brunch", "weekend", "layering"], look: .gen(.cardigan, A.Style(color: A.rgb(0x9DB59A), pattern: .ribbed, material: .knit)), fit: "Relaxed"),
        // Bottoms
        PieceSpec(key: "trousersCream", name: "Cream pleated trousers", category: .bottoms, group: "bottoms", color: "Cream", brand: "Massimo Dutti", material: "Wool blend", season: "All year", tags: ["work", "formal", "tailored"], look: .gen(.pants(.wide), plain(0xEDE3D1, .wool)), fit: "Wide leg"),
        PieceSpec(key: "trousersNavy", name: "Navy cigarette trousers", category: .bottoms, group: "bottoms", color: "Navy", brand: "Theory", material: "Stretch wool", season: "All year", tags: ["work", "tailored"], look: .gen(.pants(.straight), plain(0x24365E, .wool)), fit: "Slim straight"),
        PieceSpec(key: "trousersOlive", name: "Olive cargo trousers", category: .bottoms, group: "bottoms", color: "Olive", brand: "Zara", material: "Cotton twill", season: "All year", tags: ["casual", "travel", "weekend"], look: .gen(.pants(.wide), plain(0x6B6B47)), fit: "Relaxed"),
        PieceSpec(key: "trousersLinenWhite", name: "White linen pants", category: .bottoms, group: "bottoms", color: "White", brand: "H&M", material: "Linen", season: "Summer", tags: ["vacation", "beach", "brunch"], look: .gen(.pants(.wide), plain(0xF7F5F0, .linen)), fit: "Wide leg"),
        PieceSpec(key: "shortsDenim", name: "Denim cut-off shorts", category: .bottoms, group: "denim", color: "Mid blue", brand: "Levi's", material: "Denim", season: "Summer", tags: ["beach", "casual", "vacation"], look: .gen(.shorts, made(0x6C8DB2, .denim, 0x3F618F, .denim)), fit: "High rise"),
        PieceSpec(key: "shortsLinen", name: "Black linen shorts", category: .bottoms, group: "bottoms", color: "Black", brand: "Mango", material: "Linen", season: "Summer", tags: ["vacation", "casual"], look: .gen(.shorts, plain(0x1E1E20, .linen)), fit: "Relaxed"),
        PieceSpec(key: "jeansWide", name: "Ecru wide-leg jeans", category: .bottoms, group: "denim", color: "Ecru", brand: "Agolde", material: "Denim", season: "Spring and summer", tags: ["casual", "brunch", "weekend"], look: .gen(.pants(.wide), made(0xEEE6D5, .denim, 0xC9BFA9, .denim)), fit: "Wide leg"),
        PieceSpec(key: "jeansLight", name: "Light wash mom jeans", category: .bottoms, group: "denim", color: "Light blue", brand: "Abercrombie", material: "Denim", season: "All year", tags: ["casual", "weekend", "errands"], look: .gen(.pants(.straight), made(0x8FA8C8, .denim, 0x5F7EA4, .denim)), fit: "Tapered"),
        PieceSpec(key: "skirtBlackMini", name: "Black leather mini skirt", category: .bottoms, group: "skirts", color: "Black", brand: "Zara", material: "Faux leather", season: "Autumn and winter", tags: ["night out", "date night"], look: .gen(.skirt(.mini, pleated: false), plain(0x1C1B1B, .leather)), fit: "A-line"),
        PieceSpec(key: "skirtSatinMidi", name: "Black satin slip skirt", category: .bottoms, group: "skirts", color: "Black", brand: "Aritzia", material: "Satin", season: "All year", tags: ["work", "event", "date night"], look: .gen(.skirt(.midi, pleated: false), plain(0x1E1E20, .satin)), fit: "Bias cut"),
        PieceSpec(key: "skirtLinenMaxi", name: "Linen maxi skirt", category: .bottoms, group: "skirts", color: "Oatmeal", brand: "Faithfull the Brand", material: "Linen", season: "Summer", tags: ["vacation", "beach", "sunday"], look: .gen(.skirt(.maxi, pleated: false), plain(0xD9C7A8, .linen)), fit: "Flowy"),
        PieceSpec(key: "skirtPleatGrey", name: "Grey pleated midi skirt", category: .bottoms, group: "skirts", color: "Grey", brand: "Uniqlo", material: "Polyester", season: "All year", tags: ["work", "classic"], look: .gen(.skirt(.midi, pleated: true), plain(0x8E8E92)), fit: "Pleated"),
        // Dresses
        PieceSpec(key: "dressWhiteLinen", name: "White linen mini dress", category: .dresses, group: "dresses", color: "White", brand: "Faithfull the Brand", material: "Linen", season: "Summer", tags: ["vacation", "beach", "brunch"], look: .gen(.dress(.mini, sleeves: false), plain(0xF7F5F0, .linen)), fit: "Relaxed"),
        PieceSpec(key: "dressEmerald", name: "Emerald satin midi", category: .dresses, group: "dresses", color: "Emerald", brand: "Reformation", material: "Satin", season: "All year", tags: ["wedding guest", "event", "formal"], look: .gen(.dress(.midi, sleeves: false), plain(0x1F6B4F, .satin)), fit: "Bias cut"),
        PieceSpec(key: "dressStripe", name: "Striped shirt dress", category: .dresses, group: "dresses", color: "Blue stripe", brand: "J.Crew", material: "Cotton", season: "Spring and summer", tags: ["work", "weekend"], look: .gen(.dress(.midi, sleeves: true), made(0xEEF2F7, .stripes, 0x5C7FB0)), fit: "Belted"),
        PieceSpec(key: "dressKnit", name: "Oat knit midi dress", category: .dresses, group: "dresses", color: "Oat", brand: "Aritzia", material: "Rib knit", season: "Autumn and winter", tags: ["cozy", "travel", "work"], look: .gen(.dress(.midi, sleeves: true), A.Style(color: A.rgb(0xD9C7A8), pattern: .ribbed, material: .knit)), fit: "Fitted"),
        PieceSpec(key: "dressRedMaxi", name: "Red halter maxi dress", category: .dresses, group: "dresses", color: "Red", brand: "Mango", material: "Viscose", season: "Summer", tags: ["vacation", "event", "date night"], look: .gen(.dress(.maxi, sleeves: false), plain(0xB23A48)), fit: "Halter"),
        PieceSpec(key: "dressDenim", name: "Denim pinafore dress", category: .dresses, group: "dresses", color: "Mid blue", brand: "Madewell", material: "Denim", season: "Spring", tags: ["casual", "weekend"], look: .gen(.dress(.mini, sleeves: false), made(0x6C8DB2, .denim, 0x3F618F, .denim)), fit: "A-line"),
        PieceSpec(key: "dressPolka", name: "Polka dot tea dress", category: .dresses, group: "dresses", color: "Navy dots", brand: "Rixo", material: "Silk crepe", season: "Spring and summer", tags: ["brunch", "wedding guest", "date night"], look: .gen(.dress(.midi, sleeves: true), made(0x24365E, .dots, 0xF4F1EA)), fit: "Flowy"),
        // Layers
        PieceSpec(key: "coatCamel", name: "Camel wool coat", category: .layers, group: "layers", color: "Camel", brand: "Max Mara", material: "Wool and cashmere", season: "Winter", tags: ["travel", "work", "baguio"], look: .gen(.blazer, plain(0xB98B5E, .wool)), fit: "Relaxed", notes: "Brush after wearing."),
        PieceSpec(key: "blazerNavy", name: "Navy double-breasted blazer", category: .layers, group: "layers", color: "Navy", brand: "Massimo Dutti", material: "Wool", season: "All year", tags: ["work", "formal"], look: .gen(.blazer, plain(0x24365E, .wool)), fit: "Tailored"),
        PieceSpec(key: "blazerCheck", name: "Grey check blazer", category: .layers, group: "layers", color: "Grey check", brand: "Zara", material: "Wool blend", season: "Autumn and winter", tags: ["work", "classic"], look: .gen(.blazer, made(0x8E8E92, .gingham, 0x5A5A5E, .wool)), fit: "Oversized"),
        PieceSpec(key: "bomber", name: "Olive bomber jacket", category: .layers, group: "layers", color: "Olive", brand: "Alpha Industries", material: "Nylon", season: "Autumn", tags: ["casual", "travel", "weekend"], look: .gen(.jacket, plain(0x6B6B47)), fit: "Relaxed"),
        PieceSpec(key: "puffer", name: "Black packable puffer", category: .layers, group: "layers", color: "Black", brand: "Uniqlo", material: "Down", season: "Winter", tags: ["travel", "baguio", "cold"], look: .gen(.jacket, plain(0x1E1E20)), fit: "Regular"),
        PieceSpec(key: "shacket", name: "Cream overshirt jacket", category: .layers, group: "layers", color: "Cream", brand: "Arket", material: "Wool blend", season: "Autumn", tags: ["casual", "layering", "weekend"], look: .gen(.jacket, plain(0xEDE3D1, .wool)), fit: "Oversized"),
        PieceSpec(key: "kimono", name: "Floral kimono", category: .layers, group: "layers", color: "Pink floral", brand: "Free People", material: "Viscose", season: "Summer", tags: ["beach", "vacation"], look: .gen(.cardigan, made(0xF4EFE6, .floral, 0xD0678A)), fit: "Flowy"),
        // Activewear
        PieceSpec(key: "sportsBra", name: "Black sports bra", category: .tops, group: "activewear", color: "Black", brand: "Lululemon", material: "Nulu", season: "All year", tags: ["gym", "pilates", "active"], look: .gen(.crop, plain(0x1E1E20)), fit: "Medium support"),
        PieceSpec(key: "sportsBraSage", name: "Sage sports bra", category: .tops, group: "activewear", color: "Sage", brand: "Alo", material: "Airlift", season: "All year", tags: ["gym", "pilates", "active"], look: .gen(.crop, plain(0x9DB59A)), fit: "Light support"),
        PieceSpec(key: "runTee", name: "White running tee", category: .tops, group: "activewear", color: "White", brand: "Nike", material: "Dri-FIT", season: "All year", tags: ["gym", "run", "active"], look: .gen(.tee, plain(0xF7F5F0)), fit: "Regular"),
        PieceSpec(key: "leggings", name: "Black high-rise leggings", category: .bottoms, group: "activeBottoms", color: "Black", brand: "Lululemon", material: "Nulu", season: "All year", tags: ["gym", "pilates", "travel"], look: .gen(.pants(.skinny), plain(0x1E1E20)), fit: "25 inch"),
        PieceSpec(key: "leggingsMocha", name: "Mocha flare leggings", category: .bottoms, group: "activeBottoms", color: "Mocha", brand: "Alo", material: "Airbrush", season: "All year", tags: ["pilates", "errands"], look: .gen(.pants(.wide), plain(0x7B5E4E)), fit: "Flare"),
        PieceSpec(key: "bikeShorts", name: "Navy bike shorts", category: .bottoms, group: "activeBottoms", color: "Navy", brand: "Girlfriend Collective", material: "Recycled nylon", season: "Summer", tags: ["gym", "run", "active"], look: .gen(.shorts, plain(0x24365E)), fit: "6 inch"),
        PieceSpec(key: "trainers", name: "Grey running shoes", category: .shoes, group: "shoes", color: "Grey", brand: "On", material: "Mesh", season: "All year", tags: ["gym", "run", "walking"], look: .gen(.sneakers, plain(0xA3A3A6, .rubber)), fit: "Half size up"),
        // Loungewear
        PieceSpec(key: "sweatsGrey", name: "Grey sweatpants", category: .bottoms, group: "loungewear", color: "Grey", brand: "Aritzia", material: "Fleece", season: "All year", tags: ["lounge", "travel", "sunday"], look: .gen(.pants(.straight), plain(0x9A9A9E)), fit: "Relaxed"),
        PieceSpec(key: "hoodie", name: "Oat zip hoodie", category: .layers, group: "layers", color: "Oat", brand: "Aritzia", material: "Fleece", season: "All year", tags: ["lounge", "travel", "gym"], look: .gen(.jacket, plain(0xD9C7A8)), fit: "Oversized"),
        PieceSpec(key: "sweatshirt", name: "Navy college sweatshirt", category: .tops, group: "tops", color: "Navy", brand: "Champion", material: "Fleece", season: "All year", tags: ["lounge", "weekend"], look: .gen(.tee, plain(0x24365E)), fit: "Oversized"),
        // Shoes
        PieceSpec(key: "loafers", name: "Black leather loafers", category: .shoes, group: "shoes", color: "Black", brand: "G.H. Bass", material: "Leather", season: "All year", tags: ["work", "classic", "travel"], look: .gen(.flats, plain(0x1E1E20, .leather)), fit: "True to size"),
        PieceSpec(key: "pumps", name: "Nude pointed pumps", category: .shoes, group: "shoes", color: "Nude", brand: "Charles & Keith", material: "Patent leather", season: "All year", tags: ["work", "formal", "event"], look: .gen(.heels, plain(0xD9B8A0, .leather)), fit: "True to size"),
        PieceSpec(key: "heelsBlack", name: "Black strappy heels", category: .shoes, group: "shoes", color: "Black", brand: "Steve Madden", material: "Leather", season: "All year", tags: ["night out", "formal", "date night"], look: .gen(.heels, plain(0x1E1E20, .leather)), fit: "True to size"),
        PieceSpec(key: "mules", name: "Tan heeled mules", category: .shoes, group: "shoes", color: "Tan", brand: "Mango", material: "Suede", season: "Spring and summer", tags: ["brunch", "work", "date night"], look: .gen(.heels, plain(0xC08A55, .suede)), fit: "True to size"),
        PieceSpec(key: "sneakersBlack", name: "Black canvas sneakers", category: .shoes, group: "shoes", color: "Black", brand: "Converse", material: "Canvas", season: "All year", tags: ["casual", "travel", "night out"], look: .gen(.sneakers, plain(0x1E1E20)), fit: "Half size down"),
        PieceSpec(key: "sneakersRetro", name: "Retro suede sneakers", category: .shoes, group: "shoes", color: "Green and cream", brand: "Adidas", material: "Suede", season: "All year", tags: ["casual", "weekend"], look: .gen(.sneakers, plain(0x2F6B4F, .suede)), fit: "True to size"),
        PieceSpec(key: "kneeBoots", name: "Black knee-high boots", category: .shoes, group: "shoes", color: "Black", brand: "Stuart Weitzman", material: "Leather", season: "Autumn and winter", tags: ["date night", "travel", "baguio"], look: .gen(.boots, plain(0x1E1E20, .leather)), fit: "True to size"),
        PieceSpec(key: "flatsNude", name: "Beige slingback flats", category: .shoes, group: "shoes", color: "Beige", brand: "Chanel", material: "Leather", season: "All year", tags: ["work", "brunch", "classic"], look: .gen(.flats, plain(0xD9C7A8, .leather)), fit: "True to size", notes: "Wear with care; keep the dust bag."),
        PieceSpec(key: "sandalsBlack", name: "Black slide sandals", category: .shoes, group: "sandals", color: "Black", brand: "Birkenstock", material: "Leather", season: "Summer", tags: ["casual", "errands", "vacation"], look: .gen(.sandal, plain(0x1E1E20, .leather)), fit: "Narrow"),
        PieceSpec(key: "espadrilles", name: "Cream espadrille wedges", category: .shoes, group: "sandals", color: "Cream", brand: "Castañer", material: "Canvas and jute", season: "Summer", tags: ["vacation", "brunch", "wedding guest"], look: .gen(.sandal, plain(0xEDE3D1, .straw)), fit: "True to size"),
        // Bags
        PieceSpec(key: "toteLeather", name: "Black leather work tote", category: .accessories, group: "bags", color: "Black", brand: "Cuyana", material: "Leather", season: "All year", tags: ["work", "travel"], look: .gen(.tote, plain(0x1E1E20, .leather)), notes: "Fits a 14 inch laptop."),
        PieceSpec(key: "shoulderBag", name: "Brown shoulder bag", category: .accessories, group: "bags", color: "Brown", brand: "Polène", material: "Leather", season: "All year", tags: ["everyday", "work", "brunch"], look: .gen(.crossbody, plain(0x6A3F2A, .leather))),
        PieceSpec(key: "miniBag", name: "Cream mini bag", category: .accessories, group: "bags", color: "Cream", brand: "Charles & Keith", material: "Faux leather", season: "All year", tags: ["date night", "event", "brunch"], look: .gen(.clutch, plain(0xEDE3D1, .leather))),
        PieceSpec(key: "beltBag", name: "Black belt bag", category: .accessories, group: "bags", color: "Black", brand: "Lululemon", material: "Nylon", season: "All year", tags: ["travel", "gym", "errands"], look: .gen(.crossbody, plain(0x1E1E20))),
        PieceSpec(key: "clutchGold", name: "Gold chain clutch", category: .accessories, group: "bags", color: "Gold", brand: "Mango", material: "Metallic leather", season: "All year", tags: ["wedding guest", "event", "formal"], look: .gen(.clutch, plain(0xCDA64E, .metal))),
        // Jewelry
        PieceSpec(key: "pearls", name: "Pearl drop earrings", category: .accessories, group: "jewelry", color: "Pearl", brand: "Mejuri", material: "Freshwater pearl", season: "All year", tags: ["formal", "wedding guest", "work"], look: .gen(.hoops, plain(0xF1EADF, .metal))),
        PieceSpec(key: "silverHoops", name: "Silver huggie hoops", category: .accessories, group: "jewelry", color: "Silver", brand: "Pandora", material: "Sterling silver", season: "All year", tags: ["everyday", "gym"], look: .gen(.hoops, plain(0xC6C7CB, .metal))),
        PieceSpec(key: "chain", name: "Layered gold chain", category: .accessories, group: "jewelry", color: "Gold", brand: "Mejuri", material: "Gold vermeil", season: "All year", tags: ["everyday", "date night"], look: .gen(.necklace, plain(0xCDA64E, .metal))),
        PieceSpec(key: "smartwatch", name: "Black smartwatch", category: .accessories, group: "jewelry", color: "Black", brand: "Apple", material: "Aluminum", season: "All year", tags: ["gym", "everyday", "travel"], look: .gen(.watch, plain(0x1E1E20, .rubber))),
        // Hats, sunglasses and small accessories
        PieceSpec(key: "cap", name: "Navy baseball cap", category: .accessories, group: "sunwear", color: "Navy", brand: "New Era", material: "Cotton", season: "All year", tags: ["gym", "travel", "beach"], look: .gen(.sunHat, plain(0x24365E))),
        PieceSpec(key: "bucketHat", name: "Cream bucket hat", category: .accessories, group: "sunwear", color: "Cream", brand: "Kangol", material: "Cotton", season: "Summer", tags: ["beach", "vacation", "casual"], look: .gen(.sunHat, plain(0xEDE3D1))),
        PieceSpec(key: "catEye", name: "Tortoise cat-eye sunglasses", category: .accessories, group: "sunwear", color: "Tortoise", brand: "Le Specs", material: "Acetate", season: "All year", tags: ["vacation", "brunch", "beach"], look: .gen(.sunglasses, plain(0x6A3F2A, .rubber))),
        PieceSpec(key: "beltBlack", name: "Black skinny belt", category: .accessories, group: "accessories", color: "Black", brand: "Everlane", material: "Leather", season: "All year", tags: ["work", "formal"], look: .gen(.belt, plain(0x1E1E20, .leather))),
        PieceSpec(key: "scarfWool", name: "Camel wool scarf", category: .accessories, group: "accessories", color: "Camel", brand: "Acne Studios", material: "Wool", season: "Winter", tags: ["travel", "baguio", "cold"], look: .gen(.scarf, plain(0xB98B5E, .wool))),
        PieceSpec(key: "scarfSilkNavy", name: "Navy silk square scarf", category: .accessories, group: "accessories", color: "Navy", brand: "Massimo Dutti", material: "Silk", season: "All year", tags: ["work", "travel"], look: .gen(.scarf, made(0x24365E, .dots, 0xF4F1EA))),
        // Swimwear
        PieceSpec(key: "bikiniBlack", name: "Black triangle bikini", category: .tops, group: "bikinis", color: "Black", brand: "Triangl", material: "Neoprene", season: "Summer", tags: ["beach", "pool", "vacation"], look: .gen(.bikini, plain(0x1E1E20)), fit: "Adjustable"),
        PieceSpec(key: "bikiniStripe", name: "Striped bandeau bikini", category: .tops, group: "bikinis", color: "Navy stripe", brand: "Solid & Striped", material: "Stretch nylon", season: "Summer", tags: ["beach", "island"], look: .gen(.bikini, made(0xF4F1EA, .stripes, 0x24365E)), fit: "Bandeau"),
        PieceSpec(key: "onePieceRed", name: "Red scoop swimsuit", category: .dresses, group: "swimwear", color: "Red", brand: "Hunza G", material: "Crinkle stretch", season: "Summer", tags: ["pool", "beach"], look: .gen(.onePiece, plain(0xB23A48)), fit: "Fitted"),
        PieceSpec(key: "rashGuard", name: "Navy long-sleeve rash guard", category: .tops, group: "tops", color: "Navy", brand: "Roxy", material: "Lycra", season: "Summer", tags: ["snorkel", "island", "sun"], look: .gen(.tee, plain(0x1F4E79)), fit: "Fitted")
    ]

    private static let extraLooks: [(name: String, keys: [String], occasion: String, mood: String)] = [
        ("Monday focus", ["blouseWhite", "trousersNavy", "loafers", "toteLeather", "watch"], "Work", "Focused"),
        ("Board review", ["blouseSilk", "blazerNavy", "trousersCream", "pumps", "pearls"], "Work", "Polished"),
        ("Hybrid day", ["knitNavy", "jeansLight", "loafers", "shoulderBag"], "Work", "Easy"),
        ("Midweek layers", ["tankWhite", "blazerCheck", "skirtPleatGrey", "flatsNude", "beltBlack"], "Work", "Classic"),
        ("Rainy commute", ["blouseBlue", "trousersBlack", "trench", "boots", "toteLeather"], "Work", "Practical"),
        ("Friday drinks", ["camiBlack", "trousersWide", "blazerBlack", "mules", "chain"], "Work", "Relaxed"),
        ("Satin and knit", ["knitGrey", "skirtSatinMidi", "kneeBoots", "miniBag"], "Work", "Soft"),
        ("Shirt dress Tuesday", ["dressStripe", "flatsNude", "shoulderBag", "watch"], "Work", "Fresh"),
        ("Cozy office", ["dressKnit", "kneeBoots", "coatCamel", "toteLeather"], "Work", "Warm"),
        ("Morning pilates", ["sportsBraSage", "leggingsMocha", "hoodie", "trainers", "beltBag"], "Active", "Energized"),
        ("Gym session", ["sportsBra", "leggings", "runTee", "trainers", "smartwatch"], "Active", "Strong"),
        ("Sunday run", ["runTee", "bikeShorts", "trainers", "cap", "smartwatch"], "Active", "Fresh"),
        ("Errands in leggings", ["sweatshirt", "leggings", "sneakersRetro", "beltBag", "cap"], "Casual", "Comfortable"),
        ("Lazy Sunday", ["teeGrey", "sweatsGrey", "sandalsBlack"], "Lounge", "Cozy"),
        ("Long-haul flight", ["teeBlack", "sweatsGrey", "hoodie", "trainers", "beltBag"], "Travel", "Comfortable"),
        ("Airport chic", ["knitCream", "trousersOlive", "sneakers", "coatCamel", "toteLeather"], "Travel", "Put together"),
        ("Weekend denim", ["teeOlive", "jeansWide", "sneakersRetro", "crossbody"], "Weekend", "Easy"),
        ("Farmers market", ["blouseFloral", "jeansLight", "espadrilles", "tote", "catEye"], "Weekend", "Sunny"),
        ("Gallery afternoon", ["teeStripeRed", "skirtPleatGrey", "loafers", "shoulderBag"], "Weekend", "Curious"),
        ("Picnic in the park", ["dressDenim", "teeStripeRed", "sneakers", "bucketHat", "tote"], "Weekend", "Playful"),
        ("Brunch in linen", ["cropWhite", "trousersLinenWhite", "mules", "miniBag", "catEye"], "Weekend", "Breezy"),
        ("Bookshop date", ["cardiSage", "tankWhite", "jeansWide", "flatsNude"], "Date night", "Sweet"),
        ("Dinner downtown", ["camiChampagne", "skirtBlackMini", "heelsBlack", "miniBag", "chain"], "Date night", "Confident"),
        ("Rooftop drinks", ["dressRedMaxi", "heelsBlack", "clutchGold", "hoops"], "Night out", "Bold"),
        ("Concert night", ["teeBlack", "skirtBlackMini", "leather", "sneakersBlack", "beltBag"], "Night out", "Edgy"),
        ("Karaoke night", ["cropDenim", "jeansBlack", "boots", "crossbody"], "Night out", "Fun"),
        ("Garden wedding", ["dressPolka", "espadrilles", "clutchGold", "pearls"], "Event", "Romantic"),
        ("Evening wedding", ["dressEmerald", "pumps", "clutchGold", "pearls"], "Event", "Elegant"),
        ("Engagement party", ["blouseSilk", "skirtSatinMidi", "heels", "miniBag", "chain"], "Event", "Celebratory"),
        ("Baby shower", ["dressGingham", "cardiSage", "flatsNude", "shoulderBag"], "Event", "Warm"),
        ("Baguio morning", ["knitCream", "jeans", "puffer", "boots", "scarfWool"], "Travel", "Crisp"),
        ("Baguio night market", ["sweatshirt", "trousersOlive", "puffer", "sneakersBlack", "beltBag"], "Travel", "Cozy"),
        ("Pine forest walk", ["knitNavy", "leggings", "bomber", "trainers", "cap"], "Travel", "Outdoorsy"),
        ("Snorkel day", ["rashGuard", "bikiniBlack", "shortsDenim", "slides", "bucketHat"], "Beach", "Adventurous"),
        ("Beach club", ["bikiniStripe", "skirtLinenMaxi", "kimono", "goldSandals", "catEye"], "Beach", "Golden"),
        ("Resort dinner", ["dressWhiteLinen", "espadrilles", "miniBag", "hoops"], "Beach", "Effortless"),
        ("Poolside lunch", ["onePieceRed", "shortsLinen", "slides", "hat", "sunglasses"], "Beach", "Lazy"),
        ("Coffee and laptop", ["blouseDot", "jeansBlack", "loafers", "toteLeather"], "Work", "Steady"),
        ("Autumn layers", ["teeBlack", "shacket", "jeans", "kneeBoots", "scarfSilkNavy"], "Casual", "Layered"),
        ("Mall run", ["tankMocha", "trousersOlive", "sneakersRetro", "shoulderBag", "silverHoops"], "Casual", "Easy")
    ]

    private static let extraThemes: [(name: String, text: String, looks: [String])] = [
        ("Active", "Pilates, gym and Sunday runs.", ["Morning pilates", "Gym session", "Sunday run", "Errands in leggings"]),
        ("Lounge", "Soft clothes for slow days.", ["Lazy Sunday", "Long-haul flight"]),
        ("Baguio weekend", "Warm layers for the cool mountain air.", ["Baguio morning", "Baguio night market", "Pine forest walk", "Airport chic"]),
        ("Wedding season", "Guest looks for every dress code.", ["Garden wedding", "Evening wedding", "Engagement party", "Wedding guest"]),
        ("Office essentials", "The rotation that gets her through the week.", ["Monday focus", "Board review", "Hybrid day", "Midweek layers", "Rainy commute", "Shirt dress Tuesday", "Coffee and laptop", "Cozy office"]),
        ("Resort", "Pool, beach club and dinners by the sea.", ["Snorkel day", "Beach club", "Resort dinner", "Poolside lunch"]),
        ("Friends and parties", "Birthdays, karaoke and showers.", ["Karaoke night", "Baby shower", "Rooftop drinks", "Concert night", "Friday drinks"]),
        ("Weekend favorites", "Easy looks she reaches for again and again.", ["Weekend denim", "Farmers market", "Gallery afternoon", "Picnic in the park", "Brunch in linen", "Mall run"]),
        ("Autumn edit", "Knits, boots and layers.", ["Autumn layers", "Satin and knit", "City layers", "Cozy office"])
    ]

    /// Outfits marked as favorites.
    private static let favorites = ["Office day", "Brunch with friends", "Date night", "Weekend denim", "Garden wedding", "Morning pilates", "Beach club", "Monday focus", "Coffee run", "Rooftop drinks", "Airport chic"]
    /// Pieces she has put away, in the wash or lent out.
    private static let archivedKeys = ["cropRed", "dressDenim", "sweatshirt"]
    private static let laundryKeys = ["tee", "leggings", "sportsBra", "jeans"]
    private static let unavailableKeys = ["dressEmerald"]

    private static var allSpecs: [PieceSpec] { specs + extraSpecs }
    private static var allLooks: [(name: String, keys: [String], occasion: String, mood: String)] { looks + extraLooks }

    private static let newCategories: [WardrobeCategory] = [
        WardrobeCategory(id: "camis", name: "Camis and tanks", type: .tops), WardrobeCategory(id: "knitwear", name: "Knitwear", type: .tops),
        WardrobeCategory(id: "denim", name: "Denim", type: .bottoms), WardrobeCategory(id: "skirts", name: "Skirts", type: .bottoms),
        WardrobeCategory(id: "sandals", name: "Sandals and slides", type: .shoes), WardrobeCategory(id: "bags", name: "Bags", type: .accessories),
        WardrobeCategory(id: "jewelry", name: "Jewelry and watches", type: .accessories), WardrobeCategory(id: "sunwear", name: "Hats and sunglasses", type: .accessories),
        WardrobeCategory(id: "swimwear", name: "Swimsuits", type: .dresses), WardrobeCategory(id: "bikinis", name: "Bikinis", type: .tops),
        WardrobeCategory(id: "activewear", name: "Activewear", type: .tops), WardrobeCategory(id: "activeBottoms", name: "Leggings and active", type: .bottoms),
        WardrobeCategory(id: "loungewear", name: "Loungewear", type: .bottoms)
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
            for (index, spec) in allSpecs.enumerated() {
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
            let pieces = allSpecs.compactMap { piecesByKey[$0.key] }

            stage = "outfits"
            var outfitsByName: [String: Outfit] = [:]
            for look in allLooks {
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
            for theme in themes + extraThemes {
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

            stage = "routines"
            // Office on Monday, Wednesday and Friday and the gym on Tuesday and Thursday, for the three weeks after this one.
            let routines: [(name: String, weekdays: [Int], occasion: String, looks: [String])] = [
                ("Office days", [2, 4, 6], "Office", ["Monday focus", "Board review", "Midweek layers", "Coffee and laptop", "Shirt dress Tuesday", "Rainy commute"]),
                ("Pilates and gym", [3, 5], "Pilates or gym", ["Morning pilates", "Gym session"])
            ]
            for routine in routines {
                let preferred = routine.looks.compactMap { outfitsByName[$0]?.id }
                var draft = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: routine.name, start: try day(7), end: try day(27),
                                                                       routine: RoutineConfiguration(weekdays: routine.weekdays, occasion: routine.occasion, preferredOutfitIDs: preferred)))
                for index in draft.slots.indices { draft.slots[index].outfit = outfitsByName[routine.looks[index % routine.looks.count]] }
                draft.reviewing = true
                try store.savePlanAuthoringDraft(draft)
                receipt.plans.append(try store.savePlanAuthoring(draft).plan.id)
                try store.finishPlanAuthoring(draft)
            }

            stage = "more plans"
            let baguio: [(occasion: String, look: String)] = [("Drive up and night market", "Baguio night market"), ("Burnham Park and cafés", "Baguio morning"), ("Pine forest walk and drive home", "Pine forest walk")]
            var baguioPlan = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Baguio weekend", start: try day(40), end: try day(42),
                                                                         trip: TripConfiguration(destination: "Baguio", activities: ["Cafés", "Night market", "Forest walk"])))
            for (index, entry) in baguio.enumerated() where index < baguioPlan.slots.count { baguioPlan.slots[index].occasion = entry.occasion; baguioPlan.slots[index].outfit = outfitsByName[entry.look] }
            baguioPlan.reviewing = true
            try store.savePlanAuthoringDraft(baguioPlan)
            receipt.plans.append(try store.savePlanAuthoring(baguioPlan).plan.id)
            try store.finishPlanAuthoring(baguioPlan)

            var wedding = try PlanAuthoringDraft(plan: PlanDefinition(ownerID: owner, name: "Ana and Paolo’s wedding", start: try day(49), end: try day(49)))
            wedding.slots[0].occasion = "Garden ceremony in Tagaytay"; wedding.slots[0].outfit = outfitsByName["Garden wedding"]
            wedding.reviewing = true
            try store.savePlanAuthoringDraft(wedding)
            receipt.plans.append(try store.savePlanAuthoring(wedding).plan.id)
            try store.finishPlanAuthoring(wedding)

            stage = "wear"
            // Two months of real days: the named ones above, then an everyday rotation with a few days off.
            let rotation = ["Monday focus", "Coffee run", "Hybrid day", "Gym session", "Weekend denim", "Errands day", "Coffee and laptop", "Morning pilates",
                            "Farmers market", "Midweek layers", "Lazy Sunday", "Shirt dress Tuesday", "Autumn layers", "Mall run", "Sunday run", "Board review"]
            var history = worn
            let named = Set(worn.map(\.daysAgo))
            for daysAgo in 13...60 where !named.contains(daysAgo) && daysAgo % 6 != 0 {
                history.append((daysAgo, rotation[(daysAgo * 7) % rotation.count]))
            }
            history.append((21, "Engagement party")); history.append((35, "Karaoke night")); history.append((44, "Bookshop date"))
            for entry in history {
                guard let outfit = outfitsByName[entry.look], let look = allLooks.first(where: { $0.name == entry.look }) else { continue }
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
                ("Blazer and wide trousers for the client meeting.", "Client meeting", nil, 8),
                ("The satin cami finally got its night out. Champagne toasts all round.", "Engagement party", nil, 21),
                ("Sang three songs in the cropped chambray and black jeans.", "Karaoke night", nil, 35),
                ("Ecru jeans and the olive tee, my favorite easy weekend.", "Weekend denim", nil, 16),
                ("Pilates class, then coffee. The mocha flares are so comfortable.", "Morning pilates", nil, 18),
                ("Navy blazer and cream trousers for the board review. Felt sharp.", "Board review", nil, 25),
                ("Floral blouse and espadrilles at the Legazpi market.", "Farmers market", nil, 31),
                ("Cardigan and wide jeans for a slow date at the bookshop.", "Bookshop date", nil, 44)
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

            stage = "favorites and status"
            let latest = try store.outfits()
            for name in favorites {
                guard let id = outfitsByName[name]?.id, let outfit = latest.first(where: { $0.id == id }), !outfit.isFavorite else { continue }
                _ = try store.applyOutfitMutation(OutfitMutationRequest(outfit: outfit, action: .favorite(true)))
            }
            // Pieces in the wash, lent out or put away, so availability and archive views have something to show.
            for (keys, value) in [(laundryKeys, PieceAvailability.laundry), (unavailableKeys, .unavailable)] {
                for key in keys {
                    guard let id = piecesByKey[key]?.id, let piece = try store.pieces().first(where: { $0.id == id }) else { continue }
                    _ = try store.setAvailability(id: id, value: value, expectedRevision: piece.revision, operationID: UUID())
                }
            }
            for key in archivedKeys {
                guard let id = piecesByKey[key]?.id, let piece = try store.pieces().first(where: { $0.id == id }) else { continue }
                _ = try store.setArchived(id: id, archived: true, expectedRevision: piece.revision, operationID: UUID())
            }

            stage = "profile"
            try await seedIdentity(store: store, owner: owner, preparer: preparer)

            stage = "style"
            try seedStyle(store: store)
        } catch let failure as Failure { throw failure } catch { throw Failure.seedFailed("\(stage): \(error)") }

        // Widgets for every Today card: a saved note, a saved photo, themes, fit journal and the rest.
        _ = try? await PreviewSampleContent.addAllWidgets(store: store, outputDirectory: outputDirectory)

        try LocalArchiveIO.write(try JSONEncoder().encode(receipt), to: receiptURL(outputDirectory))
        return receipt
    }

    static let ownerName = "Angelika Domingo"

    /// Name, caption and a fit photo as the avatar. Any unfinished profile edit is discarded first.
    private static func seedIdentity(store: PieceStore, owner: UUID, preparer: PhotoPreparer) async throws {
        if let open = try store.identityDraft() { try store.finishIdentityDraft(open, discarding: true) }
        var draft = LocalIdentityDraft(ownerID: owner, base: try store.localIdentity())
        draft.name = ownerName
        draft.caption = "Neutrals, linen and a good blazer."
        if let url = Foundation.Bundle.main.url(forResource: "tour-fit-street", withExtension: "jpg") {
            draft.photoID = try store.acceptPhoto(try await preparer.prepare(data: Data(contentsOf: url)))
            draft.photoRecipe = .fitOriginal
        }
        try store.saveIdentityDraft(draft)
        _ = try store.saveIdentity(draft)
        try store.finishIdentityDraft(draft)
    }

    /// Every questionnaire step answered, as she would: goals, occasions, style, fit, body details she chose to share, colors.
    private static func seedStyle(store: PieceStore) throws {
        let experience = try store.localExperience()
        if let receipt = experience.pendingStyleReceipt { try store.acknowledgeStyleReceipt(operationID: receipt.operationID) }
        if let open = try store.localExperience().styleDraft { try store.discardStyleDraft(id: open.id) }
        var answers = StylePreferences()
        for (step, choices) in [(0, ["Plan outfits faster", "Try new combinations"]), (1, ["Everyday", "Work", "Evenings", "Travel"]),
                                (2, ["Classic", "Minimal"]), (3, ["Regular", "Relaxed"])] {
            for choice in choices { answers.choose(choice, at: step) }
        }
        answers.comfort = "Breathable fabrics; nothing tight at the waist."
        answers.body.response = .provided
        answers.body.heightCM = 163
        answers.body.shape = "Hourglass"
        answers.body.useForSuggestions = true
        answers.colors.preferredColors = "Cream, Black, Navy, Beige"
        answers.colors.avoidedColors = "Orange"
        answers.colors.preferredPatterns = "Solid, Stripes"
        answers.colors.avoidedPatterns = "Animal print"
        var style = StylePreferenceDraft(source: .settings, baseRevision: try store.localExperience().style?.revision ?? 0, answers: answers)
        style.page = 6
        try store.saveStyleDraft(style)
        _ = try store.saveStylePreferences(style)
        try store.acknowledgeStyleReceipt(operationID: style.operationID)
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
