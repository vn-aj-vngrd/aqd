import SwiftUI

struct LocalEraseView: View {
    @Bindable var model: LocalRestoreModel
    let onCancel: () -> Void
    let onInstall: (PieceStore, LocalDataCoordinator, Int) -> Void
    var embedded = false
    @State private var phrase = ""
    @State private var confirm = false
    @State private var showsImpact = true
    @FocusState private var confirmationFocused: Bool
    var body: some View {
        container {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                switch model.phase {
                case .choose, .validating, .committing:
                    EmptyView()
                case .review:
                    reviewContent
                case .complete:
                    Text("AQD is ready for a fresh start.").font(.title2)
                    Text("Return to Welcome to begin onboarding. AQD will finish its file cleanup after you continue; recovery is available in Settings.")
                case .failed, .newer:
                    Text("Reset wasn’t completed").font(.title2)
                    Text(model.error ?? "Your previous local records are retained.").foregroundStyle(AppTheme.error)
                case .unknown:
                    Text("Check the reset outcome").font(.title2)
                    Text(model.error ?? "Check the same operation before resetting again. A completed switch cannot be undone by cancelling.")
                }
            }.padding(AppSpacing.screen) }.scrollDismissesKeyboard(.interactively).background(AppTheme.canvas)
                .overlay { loadingState }
                .navigationTitle("Reset data").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if model.phase != .choose && model.phase != .validating && model.phase != .committing {
                        ActionFooter {
                            switch model.phase {
                            case .review:
                                PrimaryAction(title: "Reset data", role: .destructive) { confirmationFocused = false; confirm = true }
                                    .disabled(phrase != "RESET")
                            case .complete:
                                PrimaryAction(title: "Return to Welcome") { if let store = model.installed { onInstall(store, model.coordinator, 0) } }
                            case .failed, .newer:
                                if model.review != nil { PrimaryAction(title: "Review current impact again") { model.refresh(); phrase = "" } }
                                else { PrimaryAction(title: "Prepare review again", action: model.prepareErase) }
                            case .unknown: PrimaryAction(title: "Check same operation", action: model.checkOutcome)
                            case .choose, .validating, .committing: EmptyView()
                            }
                        }
                    }
                }
                .toolbar { ToolbarItem(placement: .cancellationAction) { if !embedded && model.phase != .complete {
                    Button { if model.cancel() { onCancel() } } label: { Image(systemName: "xmark") }.buttonBorderShape(.circle).accessibilityLabel("Cancel").disabled(model.phase == .committing)
                } } }
                .appConfirmation("Reset all AQD data?", isPresented: $confirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset data", role: .destructive) { model.resetData(confirmation: phrase) }
                } message: { Text("Permanently replaces all local AQD records and schedules AQD-only file cleanup. Original Photos and exported archives stay. No automatic recovery.") }
        }.tint(AppTheme.ink).onAppear { if model.phase == .review { model.refresh() } else { model.prepareErase() } }
            .onChange(of: model.review?.version) { _, _ in phrase = "" }
            .interactiveDismissDisabled(model.review != nil || model.phase == .committing || model.phase == .validating)
    }

    /// Pushed from Settings it is a page with the system back button; elsewhere it brings its own stack.
    @ViewBuilder private func container(@ViewBuilder _ content: () -> some View) -> some View {
        if embedded {
            content().navigationBarBackButtonHidden(model.phase == .validating || model.phase == .committing)
        } else { NavigationStack { content() } }
    }

    /// Centered like every other waiting page, instead of a spinner stranded at the top of a scroll view.
    @ViewBuilder private var loadingState: some View {
        switch model.phase {
        case .choose, .validating:
            LoadingStatePage(title: "Preparing reset review", description: Text("Counting what a reset would remove. Nothing changes yet."))
                .background(AppTheme.canvas)
        case .committing:
            LoadingStatePage(title: "Resetting local data", description: Text("Keep AQD open while your local data resets."))
                .background(AppTheme.canvas)
        default: EmptyView()
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Start fresh").font(AppTypography.detailTitle)
                Text("Delete all data in AQD and restart onboarding.")
                    .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                DisclosureGroup(isExpanded: $showsImpact) {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("Your closet, outfits, plans, wear history, fits, chats, feedback, profile, settings, drafts and AQD photo copies will be removed. iPhone permission settings stay unchanged.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        if let summary = model.review?.originalSummary { LocalDataSummaryView(summary: summary) }
                        else {
                            Text("The exact counts couldn’t be read. Reset still removes all local AQD data.")
                                .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }
                    }.padding(.bottom, AppSpacing.medium)
                } label: {
                    Text("What will be deleted").font(AppTypography.body).foregroundStyle(AppTheme.ink)
                        .frame(minHeight: AppControlMetrics.minimumTarget)
                }.padding(.horizontal, AppControlMetrics.fieldPadding)

                Divider().padding(.horizontal, AppControlMetrics.fieldPadding)
                NavigationLink { LocalExportView().navigationTitle("Export before reset").secondaryPage() } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(AppTheme.controlIcon).accessibilityHidden(true)
                        Text("Export a copy first")
                        Spacer(minLength: AppSpacing.medium)
                        Image(systemName: "chevron.forward").font(AppTypography.disclosure)
                            .foregroundStyle(AppTheme.ink).accessibilityHidden(true)
                    }.font(AppTypography.body).foregroundStyle(AppTheme.ink)
                        .frame(minHeight: AppControlMetrics.minimumTarget)
                        .padding(.horizontal, AppControlMetrics.fieldPadding)
                        .padding(.vertical, AppSpacing.xSmall)
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))

            Text("Your original Photos and exported copies stay.")
                .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Type RESET to confirm").font(AppTypography.fieldLabel)
                TextField("RESET", text: $phrase)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .focused($confirmationFocused).submitLabel(.done)
                    .onSubmit { confirmationFocused = false }
                    .font(AppTypography.body).padding(AppControlMetrics.fieldPadding)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                    .accessibilityLabel("Type RESET to confirm")
                Text("This can’t be undone. There is no automatic backup.")
                    .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
            }
        }
    }
}
