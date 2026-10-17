import SwiftUI
import UIKit

extension View {
    /// App-owned discard confirmation; callbacks retain the existing draft recovery.
    func draftDiscardConfirmation(isPresented: Binding<Bool>, title: String,
                                  message: String, discard: @escaping () -> Void) -> some View {
        modifier(DraftDiscardConfirmation(isPresented: isPresented, title: title,
                                          message: message, discard: discard))
    }
}

private struct DraftDiscardConfirmation: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let discard: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .disabled(isPresented)
            .accessibilityHidden(isPresented)
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.22).ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {} // An outside tap never discards or dismisses.
                            .accessibilityHidden(true)
                        let dialog = DraftDiscardCard(title: title, message: message,
                                         cancel: { isPresented = false },
                                         discard: {
                            // Match native alerts: close before invoking the operation.
                            // A failed discard remains in the editor with its error.
                            isPresented = false
                            discard()
                        })
                        ViewThatFits(in: .vertical) {
                            dialog.fixedSize(horizontal: false, vertical: true)
                            ScrollView { dialog }.scrollBounceBehavior(.basedOnSize)
                        }.padding(AppSpacing.section)
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isPresented)
    }
}

private struct DraftDiscardCard: View {
    let title: String
    let message: String
    let cancel: () -> Void
    let discard: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AccessibilityFocusState private var titleFocused: Bool

    private let shape = RoundedRectangle(cornerRadius: AppRadius.composer, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title).font(.headline).foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader).accessibilityFocused($titleFocused)
                Text(message).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(.horizontal, AppSpacing.medium)
            if typeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.small) { cancelButton; discardButton }
            } else {
                HStack(spacing: AppSpacing.small) { cancelButton; discardButton }
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: 340)
        .background {
            if reduceTransparency { shape.fill(AppTheme.surface) }
            else { shape.fill(.regularMaterial) }
        }
        .overlay(shape.stroke(AppTheme.glassEdge, lineWidth: 1))
        .shadow(color: AppTheme.controlShadow, radius: AppSpacing.section, y: AppSpacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, cancel)
        .onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            titleFocused = true
        }
    }

    private var cancelButton: some View {
        Button(role: .cancel, action: cancel) {
            buttonLabel("Keep editing", color: AppTheme.ink, emphasized: true)
        }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
    }

    private var discardButton: some View {
        Button(role: .destructive, action: discard) {
            buttonLabel("Discard draft", color: AppTheme.error, emphasized: false)
        }.buttonStyle(.plain)
    }

    private func buttonLabel(_ title: String, color: Color, emphasized: Bool) -> some View {
        Text(title).font(emphasized ? .body.weight(.semibold) : AppTypography.body)
            .foregroundStyle(color).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.medium).padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: AppControlMetrics.minimumTarget)
            .background(AppTheme.imageGround, in: Capsule())
            .contentShape(Capsule())
    }
}
