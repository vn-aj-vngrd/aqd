import SwiftUI

struct PieceEditor: View {
  @Bindable var flow: EntryFlow
  let preparing: Bool
  let choosePhoto: () -> Void
  var body: some View {
    EntryPage(
      title: "Make it yours.",
      detail: "A name and category are all you need. This piece stays private."
    ) {
      if let file = flow.store.photoURL(flow.draft.photoFile),
        let photo = UIImage(contentsOfFile: file.path)
      {
        Image(uiImage: photo).resizable().scaledToFit().frame(maxHeight: 240).accessibilityLabel(
          "Selected piece photo")
      }
      Button(flow.draft.photoFile == nil ? "Add a photo" : "Change photo", action: choosePhoto)
        .frame(minHeight: 44)
      VStack(alignment: .leading, spacing: 8) {
        Text("Piece name").font(.subheadline)
        TextField("Name your piece", text: $flow.draft.name).textFieldStyle(.roundedBorder)
          .textInputAutocapitalization(.sentences).accessibilityLabel("Piece name")
          .accessibilityIdentifier("piece.name")
      }
      Picker("Category", selection: $flow.draft.category) {
        Text("Choose a category").tag(Optional<PieceCategory>.none)
        ForEach(PieceCategory.allCases) { Text($0.title).tag(Optional($0)) }
      }.pickerStyle(.menu).frame(minHeight: 44).accessibilityIdentifier("piece.category")
      InlineNotice(text: flow.message)
      PrimaryAction(title: "Save piece", busy: preparing, disabled: !flow.storageReadable) {
        do { try flow.savePiece() } catch { flow.message = error.localizedDescription }
      }.accessibilityIdentifier("piece.save")
      Text("Saving here does not upload or publish your photo.").font(.footnote).foregroundStyle(
        AQDColor.secondary)
    }.entryNavigationTitle("Add piece")
  }
}

struct PreferencesView: View {
  @Bindable var flow: EntryFlow
  var body: some View {
    EntryPage(
      title: "A little more you.",
      detail: "Optional details for future outfit suggestions. You can change them in Closet."
    ) {
      selection(
        "Your everyday", choices: ["Everyday", "Work", "Evenings", "Travel"],
        value: $flow.preferences.everyday)
      selection(
        "Your style", choices: ["Relaxed", "Minimal", "Classic", "Expressive"],
        value: $flow.preferences.styles)
      TextField("Comfort preferences (optional)", text: $flow.preferences.comfort, axis: .vertical)
        .textFieldStyle(.roundedBorder)
      InlineNotice(text: flow.message)
      PrimaryAction(title: "Save preferences") { save(false) }
    }.entryNavigationTitle("Style preferences")
      .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Skip") { save(true) } } }
  }
  private func save(_ dismissed: Bool) {
    do { try flow.savePreferences(dismissed: dismissed) } catch {
      flow.message = error.localizedDescription
    }
  }
  private func selection(_ title: String, choices: [String], value: Binding<Set<String>>)
    -> some View
  {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.headline)
      ForEach(choices, id: \.self) { choice in
        Button {
          if value.wrappedValue.contains(choice) {
            value.wrappedValue.remove(choice)
          } else {
            value.wrappedValue.insert(choice)
          }
        } label: {
          HStack {
            Text(choice).foregroundStyle(AQDColor.ink)
            Spacer()
            if value.wrappedValue.contains(choice) { Image(systemName: "checkmark") }
          }.frame(minHeight: 44)
        }.accessibilityAddTraits(value.wrappedValue.contains(choice) ? .isSelected : [])
      }
    }
  }
}
