import AQDCore
import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(Date.now, format: .dateTime.weekday(.abbreviated).day())
                        .font(.subheadline).foregroundStyle(AppTheme.secondary)
                    if let error = state.todayError {
                        Text(error).font(.subheadline).foregroundStyle(AppTheme.error)
                        Button("Retry Today") { state.reloadToday() }.frame(minHeight: 44)
                    }
                    if let configuration = state.today {
                        ForEach(configuration.instances) { instance in
                            stockCard(instance.kind.title, message: message(for: instance.kind))
                                .accessibilityIdentifier("today.widget.\(instance.id.uuidString)")
                        }
                    }
                    PrimaryAction(title: "Add piece") { state.addPiece() }
                    Text("Native baseline: piece capture is available. Today customization, outfits and wear are still being implemented.")
                        .font(.footnote).foregroundStyle(AppTheme.secondary)
                }.padding(20)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Today")
        }.tint(AppTheme.actionText)
    }

    private func message(for kind: TodayWidgetKind) -> String {
        switch kind {
        case .todayLook: "Outfit planning is being implemented. Your saved Today widget stays here."
        case .weekInWear: "Wear recording is being implemented. Plans never count as wear."
        case .closetInUse: "Wear insights need recorded history; this baseline doesn’t calculate them yet."
        default: "This saved widget’s capability is being implemented. Its placement has not been removed."
        }
    }

    private func stockCard(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.weight(.medium))
            Text(message).font(.subheadline).foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PendingLocalView: View {
    let title: String
    let symbol: String
    var body: some View {
        NavigationStack {
            ContentUnavailableView("\(title) is being implemented", systemImage: symbol,
                                   description: Text("This source baseline is not complete V1. Your saved pieces remain private and usable in Closet."))
                .background(AppTheme.canvas)
                .navigationTitle(title)
        }
    }
}

struct BaselineAgentView: View {
    @Environment(AppState.self) private var state
    let close: () -> Void
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Local Agent conversations aren’t implemented yet.").font(.title2.weight(.medium))
                Text("This baseline doesn’t send chat or wardrobe data anywhere. You can still add and manage pieces manually.")
                    .foregroundStyle(AppTheme.secondary)
                Button("Open Closet") { state.selection = 1; close() }.frame(minHeight: 44)
                Spacer()
            }.padding(20).background(AppTheme.canvas)
                .navigationTitle("Agent").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Back", action: close) } }
        }.tint(AppTheme.actionText)
    }
}
