import Foundation

/// Entry/tour metadata only; illustrative content never enters wardrobe records.
public struct PrivateEntryState: Codable, Equatable, Sendable {
    public static let tourStepCount = 7
    /// Tours saved by earlier builds had eight steps; they still load and finish cleanly.
    private static let legacyTourStepCount = 8
    public enum Page: String, Codable, Sendable { case welcome, introduction, privacy, ready, main }
    public enum TourSource: String, Codable, Sendable { case welcome, introduction, settings, preview }
    public enum TourOutcome: String, Codable, Sendable { case skipped, finished }
    public enum ValidationError: Error { case invalidState }
    public struct Tour: Codable, Equatable, Sendable {
        public let id: UUID
        public let source: TourSource
        public var step: Int
    }
    public var version = 1
    public var page: Page
    public var welcomeSeen = false
    public var tour: Tour?
    public var tourOutcome: TourOutcome?
    public var readyTourSource: TourSource?

    public init(alreadyEntered: Bool) { page = alreadyEntered ? .main : .welcome }
    public func validated() throws {
        guard version == 1 else { throw ValidationError.invalidState }
        if let tour {
            guard (0..<Self.legacyTourStepCount).contains(tour.step), matches(tour.source) else { throw ValidationError.invalidState }
        }
    }
    private func matches(_ source: TourSource) -> Bool {
        switch source {
        case .welcome: page == .welcome
        case .introduction: page == .introduction
        case .settings: page == .main
        case .preview: true
        }
    }
    public mutating func startTour(from source: TourSource) throws {
        guard tour == nil, matches(source) else { throw ValidationError.invalidState }
        tour = Tour(id: UUID(), source: source, step: 0)
    }
    public mutating func backInTour() {
        guard let current = tour else { return }
        if current.step == 0 { tour = nil }
        else { tour?.step -= 1 }
    }
    public mutating func nextInTour() {
        guard let current = tour else { return }
        if current.step < Self.tourStepCount - 1 { tour?.step += 1 }
        else {
            tour = nil; tourOutcome = tourOutcome ?? .finished
            // Finishing the first-run tour opens the app itself, so the owner starts using it straight away.
            if current.source != .settings && current.source != .preview { page = .main }
        }
    }
    public mutating func skipTour() {
        guard tour != nil else { return }
        let preservesPage = tour?.source == .preview
        tour = nil; tourOutcome = tourOutcome ?? .skipped
        if !preservesPage { page = .main }
    }
    public mutating func openMain() { tour = nil; page = .main }
    public mutating func reviewTourFromReady() {
        guard page == .ready, tour == nil else { return }
        let source = readyTourSource == .welcome ? TourSource.welcome : .introduction
        page = source == .welcome ? .welcome : .introduction
        tour = Tour(id: UUID(), source: source, step: Self.tourStepCount - 1)
    }
}
