import AQDCore
import SwiftUI

struct FitMemoryArtwork: View {
    let memory: FitMemory
    var thumbnail = false
    @Environment(AppState.self) private var state
    var body: some View {
        if thumbnail {
            GeometryReader { geometry in
                thumbnailContent(size: geometry.size)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(AppTheme.surface).clipped()
            }.aspectRatio(3 / 4, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: AppRadius.group))
        } else {
            Group {
                if let id = memory.photoID {
                    if let data = photoData(id), let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit().accessibilityLabel("Private fit photo")
                    } else { unavailable }
                } else if let snapshot = memory.outfit {
                    OutfitComposition(pieceIDs: snapshot.pieces.map(\.id), pieceHeight: 110)
                } else { Text("No fit content") }
            }.frame(maxWidth: .infinity).background(AppTheme.surface)
        }
    }
    @ViewBuilder private func thumbnailContent(size: CGSize) -> some View {
        if let id = memory.photoID {
            if let data = photoData(id), let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else { unavailable }
        } else if let snapshot = memory.outfit {
            let pieces = Array(snapshot.pieces.prefix(4))
            let rows = max(1, (pieces.count + 1) / 2)
            let cellWidth = max(1, (size.width - 20) / 2)
            let cellHeight = max(1, (size.height - 16 - CGFloat(rows - 1) * 4) / CGFloat(rows))
            VStack(spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(Array(pieces.dropFirst(row * 2).prefix(2)), id: \.id) { piece in
                            Group {
                                if let saved = state.ownedPieces.first(where: { $0.id == piece.id }) {
                                    PieceThumbnail(photoID: saved.photoID, recipe: saved.photoRecipe, ground: .clear)
                                } else {
                                    Image(systemName: "photo.badge.exclamationmark").foregroundStyle(AppTheme.secondary)
                                }
                            }
                            .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }.padding(8)
        } else { unavailable }
    }
    private var unavailable: some View {
        Label("Photo unavailable", systemImage: "photo.badge.exclamationmark")
            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
    }
    private func photoData(_ id: UUID) -> Data? {
        guard let store = state.store else { return nil }
        return try? thumbnail ? store.photoThumbnail(id: id, recipe: memory.photoRecipe) : store.photoRendition(id: id, recipe: memory.photoRecipe)
    }
}

enum FitJournalTab: String, CaseIterable {
    case all = "All fits", photos = "Photos", outfits = "Outfits"
}

struct FitJournalGrid: View {
    @State private var openedMemoryID: UUID?
    @Binding var tab: FitJournalTab
    @Binding var query: FitJournalQuery
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: AppSpacing.small, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 3) }
    private var memories: [FitMemory] {
        FitJournalQuery(content: tab == .photos ? .photos : .all, sort: query.sort).apply(to: state.fitMemories)
    }
    private var sections: [FitMonthSection] { FitJournalPresentation.sections(memories) }
    /// Outfits grouped by the month they were last updated, in the same order the fits use.
    private var outfitSections: [(title: String, outfits: [Outfit])] {
        let ordered = state.outfits.sorted { query.sort == .newest ? $0.updatedAt > $1.updatedAt : $0.updatedAt < $1.updatedAt }
        var result: [(title: String, outfits: [Outfit])] = []
        for outfit in ordered {
            let title = outfit.updatedAt.formatted(.dateTime.month(.wide).year())
            if let last = result.indices.last, result[last].title == title { result[last].outfits.append(outfit) }
            else { result.append((title, [outfit])) }
        }
        return result
    }
    private func monthTitle(_ section: FitMonthSection) -> String {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        guard let date = calendar.date(from: DateComponents(year: section.year, month: section.month, day: 1)) else { return section.id }
        return date.formatted(Date.FormatStyle(timeZone: calendar.timeZone).month(.wide).year())
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabs
            if let error = state.fitError, tab != .outfits {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    SemanticFeedback(role: .danger, message: error)
                    Button("Retry journal") { state.reloadFits() }.frame(minHeight: 44)
                }.padding(AppSpacing.screen)
            } else if tab == .outfits {
                if let error = state.outfitError {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        SemanticFeedback(role: .danger, message: error)
                        Button("Retry outfits") { state.reloadOutfits() }.frame(minHeight: 44)
                    }.padding(AppSpacing.screen)
                } else if state.outfits.isEmpty {
                    AppEmptyState("No outfits yet", systemImage: "hanger", description: Text("Use Add outfit (+) above to build a look from your pieces."), fillsAvailableSpace: false)
                        .frame(maxWidth: .infinity).padding(AppSpacing.screen)
                } else {
                    orderRow(count: state.outfits.count, singular: "saved outfit", plural: "saved outfits")
                    ForEach(outfitSections, id: \.title) { section in
                        Text(section.title).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.medium).padding(.bottom, AppSpacing.small)
                            .accessibilityAddTraits(.isHeader)
                        LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                            ForEach(section.outfits) { outfit in OutfitCollectionCard(outfit: outfit, gallery: true) }
                        }.padding(.horizontal, AppSpacing.screen)
                    }
                }
            } else if memories.isEmpty {
                emptyState.padding(.horizontal, AppSpacing.screen).padding(.vertical, AppSpacing.section)
            } else {
                orderRow(count: memories.count, singular: "fit", plural: "fits")
                ForEach(sections) { section in
                    Text(monthTitle(section)).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        .padding(.horizontal, AppSpacing.screen).padding(.top, AppSpacing.medium).padding(.bottom, AppSpacing.small)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                    ForEach(section.memories) { memory in
                        NavigationLink { FitMemoryDetailView(id: memory.id).secondaryPage() } label: {
                            FitMemoryArtwork(memory: memory, thumbnail: true)
                        }.buttonStyle(.plain).id(memory.id)
                            .contextMenu {
                                AccessoryButton("Open fit", systemImage: "arrow.up.forward.square") { openedMemoryID = memory.id }
                                AccessoryButton("Edit fit", systemImage: AppSymbols.edit) { state.openFit(memory) }
                                AccessoryButton("Record wear", systemImage: "checkmark.circle") { state.recordWear(from: memory) }
                            } preview: {
                                CollectionContextPreview(title: memory.outfit?.displayName ?? "Fit", detail: memory.day.displayDate) {
                                    FitMemoryArtwork(memory: memory, thumbnail: memory.photoID == nil)
                                        .frame(height: 360).clipped()
                                }.environment(state)
                            }
                            .accessibilityLabel("\(memory.day.display(.full)), \(memory.photoID == nil ? "outfit composition" : "photo"), \(memory.outfit?.displayName ?? "unlinked"), \(memory.displayNote)")
                    }
                    }.padding(.horizontal, AppSpacing.screen)
                }
            }
        }.navigationDestination(isPresented: Binding(get: { openedMemoryID != nil }, set: { if !$0 { openedMemoryID = nil } })) {
            if let id = openedMemoryID { FitMemoryDetailView(id: id).secondaryPage() }
        }
    }
    /// Count and order on one quiet line, like Closet's collection summary.
    private func orderRow(count: Int, singular: String, plural: String) -> some View {
        HStack {
            Text("\(count) \(count == 1 ? singular : plural)").font(AppTypography.fieldLabel)
            Spacer(minLength: 12)
            Menu {
                Picker("Order", selection: $query.sort) {
                    ForEach(FitJournalQuery.Sort.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(query.sort.rawValue)
                    Image(systemName: "chevron.up.chevron.down").font(AppTypography.metadata).accessibilityHidden(true)
                }.font(AppTypography.metadata).foregroundStyle(AppTheme.secondary).frame(minHeight: 44)
            }.tint(AppTheme.ink).accessibilityLabel("Order \(plural)").accessibilityValue(query.sort.rawValue)
                .accessibilityIdentifier("profile.fits.order")
        }.padding(.horizontal, AppSpacing.screen)
    }
    /// The same glass segmented control Closet uses for its collections.
    private var tabs: some View {
        AppSegmentedControl(selection: Binding(get: { tab.rawValue }, set: { value in tab = FitJournalTab(rawValue: value) ?? .all }),
                            options: FitJournalTab.allCases.map(\.rawValue), accessibilityTitle: "Fit journal view", identifierPrefix: "profile.fits.tab")
            .padding(.horizontal, AppSpacing.screen).padding(.bottom, AppSpacing.small)
    }
    private var emptyState: some View {
        AppEmptyState(tab == .all ? "A little space for your style" : "No fit photos yet",
                      systemImage: "photo.stack",
                      description: Text(tab == .all ? "Use Add fit (+) above to keep a photo or outfit here. Memories stay private." : "Add a photo to a fit to see it here. Your other fits are in All fits."),
                      fillsAvailableSpace: false)
            .frame(maxWidth: .infinity).accessibilityIdentifier("profile.fits.empty")
    }
}

struct FitEditorView: View {
    private var confirmation: some View {
        ToolbarSaveAction(title: model.unknown ? "Check result" : "Save", isPending: model.pending) { Task { await model.save() } }.disabled(!model.unknown && !model.canSave)
    }

    @Bindable var model: FitEditorModel
    @State private var discard = false
    @State private var removePhoto = false
    @State private var timezone = false
    @State private var editingPhoto = false
    @State private var showDate = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if model.saved != nil {
                        Text("Fit saved").font(AppTypography.section)

                    } else {
                        mediaContent
                        LabeledField(title: "Private note", text: Binding(get: { model.draft.value.displayNote }, set: { value in model.update { $0.note = value } }),
                                     prompt: "What would you like to remember?", multiline: true, characterLimit: TextAreaLimits.fitNote)
                            .disabled(model.locked)
                        if model.draft.value.note.count > 500 { SemanticFeedback(role: .danger, message: "Keep the note within 500 characters. Your full text is retained.") }
                        dateDetails
                        wearNext
                        guidanceLine
                        Label("Private memory. Wear is recorded separately.", systemImage: "lock")
                            .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                    }
                    if let error = model.error { SemanticFeedback(role: .danger, message: error) }
                }.padding(20)
            }.background(AppTheme.canvas).onAppear { model.state.reloadOutfits(); model.state.reloadPieces() }.navigationTitle(model.draft.base == nil ? "Add fit" : "Edit fit").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                if model.saved == nil { confirmation }
            } }.tint(AppTheme.ink)
                .toolbar { ToolbarItem(placement: model.saved == nil ? .topBarLeading : .topBarTrailing) {
                    Button {
                        if model.saved != nil { model.finish() }
                        else if !model.hasUnsavedChanges { model.finish(discarding: true) }
                        else { discard = true }
                    } label: { if model.saved == nil { Image(systemName: "xmark") } else { Text("Done") } }.accessibilityLabel(model.saved == nil ? "Cancel fit" : "Done").disabled(model.pending || model.unknown)
                } }
                .editImportedPhoto(model, importing: model.importing, locked: model.locked, presented: $editingPhoto)
                .navigationDestination(isPresented: $editingPhoto) { PhotoEditorView(model: model).secondaryPage() }
                .navigationDestination(isPresented: $timezone) {
                    TimezoneChooser(current: model.draft.value.day.timeZoneID) { zone in model.update { $0.day.timeZoneID = zone }; return model.error == nil }
                }
                .appConfirmation("Remove this fit photo?", isPresented: $removePhoto) {
                    Button("Cancel", role: .cancel) {}
                    Button("Remove photo", role: .destructive) { model.removePhoto() }
                } message: { Text("Changes this draft only until Save. Keep an outfit link or add another photo to save the fit. Original Photos are unchanged.") }
        }.interactiveDismissDisabled().draftDiscardConfirmation(isPresented: $discard, title: "Discard fit changes?", message: "Your saved memory and original Photos stay unchanged. No wear is recorded.") {
                model.finish(discarding: true); if model.state.fitEditor == nil { discard = false }
            }
    }
    private func photoSource<Label: View>(@ViewBuilder label: @escaping () -> Label) -> some View {
        SharedPhotoSourceButton(title: model.draft.value.photoID == nil ? "Add fit photo" : "Change fit photo",
            selectionToken: model.importID, locked: model.locked,
            onEdit: model.draft.value.photoID == nil ? nil : { editingPhoto = true },
            onRemove: model.draft.value.photoID == nil ? nil : { removePhoto = true }, launch: $model.launch, onData: model.importPhoto, label: label)
    }

    private func sourceLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).compactControl()
    }

    private var mediaContent: some View {
        let hasMedia = model.draft.value.photoID != nil || model.draft.value.outfit != nil
        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Group {
                if hasMedia {
                    FitMemoryArtwork(memory: model.draft.value).padding(AppSpacing.small)
                } else {
                    VStack(spacing: AppSpacing.medium) {
                        Image(systemName: "camera").font(.system(size: 34, weight: .light))
                            .foregroundStyle(AppTheme.ink).accessibilityHidden(true)
                        Text("Add a photo").font(AppTypography.detailTitle)
                        Text("Or link an outfit below to keep a look you want to remember.")
                            .font(AppTypography.supporting).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
                        photoSource { sourceLabel("Add photo", systemImage: "photo.on.rectangle") }
                    }.padding(AppSpacing.large)
                }
            }
            .frame(maxWidth: .infinity).frame(minHeight: hasMedia ? 280 : 240, maxHeight: hasMedia ? 340 : 260)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
            .overlay(alignment: .bottomTrailing) {
                // A small, separate menu: the system glass menu morphs cleanly from a compact control.
                if model.draft.value.photoID != nil {
                    photoSource {
                        Image(systemName: "ellipsis").font(.body.weight(.medium)).foregroundStyle(AppTheme.ink)
                            .frame(width: AppControlMetrics.minimumTarget, height: AppControlMetrics.minimumTarget)
                            .glassControlSurface(Circle())
                    }.padding(AppSpacing.medium)
                }
            }
            .overlay { if model.importing { ProgressView().controlSize(.large) } }
            if model.importing {
                HStack {
                    OperationProgress(title: "Preparing photo…")
                    Spacer()
                    Button("Cancel import") { model.cancelImport() }.frame(minHeight: 44)
                }
            }
            HStack {
                Text("Outfit").font(AppTypography.fieldLabel).foregroundStyle(AppTheme.secondary)
                Spacer()
                AppChip(title: "No outfit", isSelected: model.draft.value.outfit == nil) { _ = model.link(nil) }.disabled(model.locked)
            }.padding(.bottom, -AppSpacing.small)
            if let planned = model.plannedOutfit {
                Button { _ = model.link(planned) } label: {
                    HStack {
                        Label("Planned for this day: \(planned.displayName)", systemImage: "calendar").font(AppTypography.supporting)
                        Spacer(minLength: 8)
                        Text("Use").font(AppTypography.fieldLabel)
                    }.foregroundStyle(AppTheme.ink).padding(.horizontal, 14).frame(minHeight: 48)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                }.buttonStyle(.plain).disabled(model.locked).accessibilityIdentifier("fit.usePlanned")
            }
            OutfitSelectionStrip(outfits: model.state.outfits, selectedID: model.draft.value.outfit?.id, locked: model.locked) { outfit in
                _ = model.link(outfit)
            }
        }
    }
    private var dateSummary: String {
        model.draft.value.day.display(.relative)
    }
    /// The date rarely changes, and the timezone almost never: both stay one tap away instead of crowding the capture.
    private var dateDetails: some View {
        DisclosureGroup(isExpanded: $showDate) {
            VStack(spacing: 0) {
                Divider()
                ThemedDatePicker("Date", selection: Binding(get: { (try? model.draft.value.day.date()) ?? Date() }, set: { date in
                    let zone = TimeZone(identifier: model.draft.value.day.timeZoneID) ?? .current
                    model.update { $0.day = LocalPlanDay(date: date, timeZone: zone) }
                }), displayedComponents: .date)
                    .environment(\.timeZone, TimeZone(identifier: model.draft.value.day.timeZoneID) ?? .current)
                    .frame(minHeight: 54)
                Divider()
                DisclosureRow(title: "Timezone", value: model.draft.value.day.timeZoneID) { timezone = true }
            }
        } label: {
            HStack { Text("Date").font(AppTypography.body); Spacer(); Text(dateSummary).foregroundStyle(AppTheme.secondary) }
                .frame(minHeight: 44)
        }.tint(AppTheme.ink).foregroundStyle(AppTheme.ink).padding(.horizontal, 14).padding(.vertical, 4)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card)).disabled(model.locked)
            .accessibilityIdentifier("fit.date")
    }
    /// Offered only with an outfit, since wear needs pieces. Saving never records wear; it opens Record wear to confirm.
    @ViewBuilder private var wearNext: some View {
        if model.draft.value.outfit != nil {
            Toggle(isOn: $model.recordWearNext) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Record wear next").font(AppTypography.body)
                    Text("Opens Record wear after saving. Nothing counts until you confirm there.")
                        .font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                }
            }.tint(AppTheme.primaryFill).disabled(model.locked).padding(.horizontal, 14).padding(.vertical, 8)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                .accessibilityIdentifier("fit.recordWearNext")
        }
    }
    /// One plain line for what is missing, never red: the first thing a new fit needs is content.
    @ViewBuilder private var guidanceLine: some View {
        if !model.locked, model.guidance == .needsContent {
            Text("Add a photo or choose an outfit to save.").font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                .accessibilityIdentifier("fit.guidance")
        }
    }
}

struct FitMemoryDetailView: View {
    let id: UUID
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false
    @State private var request: FitDeletionRequest?
    @State private var error: String?
    private var memory: FitMemory? { state.fitMemories.first { $0.id == id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let memory {
                    FitMemoryArtwork(memory: memory).frame(minHeight: memory.photoID == nil ? 0 : 240, maxHeight: memory.photoID == nil ? .infinity : 360)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                    VStack(alignment: .leading, spacing: 12) {
                        Text(memory.day.display(.full)).font(AppTypography.detailTitle)
                        if !memory.note.isEmpty { Text(memory.displayNote).font(AppTypography.body) }
                        Text("A fit memory. Wear is recorded separately.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                        DisclosureGroup("Memory details") {
                            Text(memory.day.timeZoneID).font(AppTypography.supporting).foregroundStyle(AppTheme.secondary)
                        }.font(AppTypography.supporting)
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                    if let snapshot = memory.outfit {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(snapshot.displayName).font(AppTypography.fieldLabel)
                                Text("\(snapshot.pieces.count) pieces in this memory").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }
                            ForEach(snapshot.pieces, id: \.id) { piece in
                                HStack(spacing: 12) {
                                    if let saved = state.ownedPieces.first(where: { $0.id == piece.id }) {
                                        PieceThumbnail(photoID: saved.photoID, recipe: saved.photoRecipe)
                                            .frame(width: 56, height: 64).background(AppTheme.imageGround)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(piece.displayName).font(AppTypography.supporting)
                                        Text(piece.category.rawValue.capitalized).font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            if !state.outfits.contains(where: { $0.id == snapshot.id }) {
                                Text("Linked outfit unavailable. The recorded snapshot is kept here.").font(AppTypography.metadata).foregroundStyle(AppTheme.secondary)
                            }
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
                    }
                } else { AppEmptyState("Memory unavailable", systemImage: "photo") }
                if let error { SemanticFeedback(role: .danger, message: error) }
            }.padding(20)
        }.background(AppTheme.canvas).navigationTitle("Fit memory").navigationBarTitleDisplayMode(.inline).tint(AppTheme.ink)
            .navigationDestination(for: ClosetRoute.self) { ClosetDestination(route: $0) }
            .onAppear { state.reloadFits(); state.reloadOutfits() }
            .toolbar { if memory != nil || request != nil { ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if request != nil {
                        AccessoryButton("Check deletion result", systemImage: "arrow.clockwise", action: delete)
                    } else if let memory {
                        AccessoryButton("Edit fit", systemImage: AppSymbols.edit) { state.openFit(memory) }
                        AccessoryButton("Record wear", systemImage: "checkmark.circle") { state.recordWear(from: memory) }
                        if let snapshot = memory.outfit, state.outfits.contains(where: { $0.id == snapshot.id }) {
                            NavigationLink(value: ClosetRoute.outfit(snapshot.id)) { AccessoryLabel("Open linked outfit", systemImage: "square.stack") }
                        }
                        Section {
                            DestructiveMenuButton("Delete memory") { request = FitDeletionRequest(memory: memory); confirming = true }
                        }
                    }
                } label: { Label("More", systemImage: "ellipsis") }
            } } }
            .deleteConfirmation("memory", isPresented: $confirming, message: "Removes only this local memory and unshared AQD photo copies. Your outfit, wear history, other memories and original Photos stay.",
                                cancel: { request = nil }, delete: delete)
    }
    private func delete() {
        guard let request else { return }
        do {
            guard let store = state.store else { throw PieceStore.StoreError.corruptStore }
            try store.deleteFit(request); state.reloadFits(); state.retryPhotoCleanup(); dismiss()
        } catch PieceStore.StoreError.staleRevision { self.request = nil; error = "This memory changed. Review the latest version before deleting."; state.reloadFits() }
        catch { self.error = "Deletion is not acknowledged. Check the same operation before changing this memory." }
    }
}
