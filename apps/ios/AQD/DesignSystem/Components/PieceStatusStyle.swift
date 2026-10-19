import AQDCore
import SwiftUI

/// One color per piece status, used by every chip, badge and row that shows it.
extension PieceStatus {
    var tint: Color {
        switch self {
        case .available: AppTheme.statusAvailable
        case .unavailable: AppTheme.error
        case .laundry: AppTheme.statusLaundry
        case .archived: AppTheme.secondary
        }
    }
}

extension PieceAvailability {
    var tint: Color {
        switch self {
        case .available: AppTheme.statusAvailable
        case .unavailable: AppTheme.error
        case .laundry: AppTheme.statusLaundry
        }
    }
    var symbol: String {
        switch self {
        case .available: "checkmark.circle"
        case .unavailable: "xmark.circle"
        case .laundry: "washer"
        }
    }
}
