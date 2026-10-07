# Native iOS materials and component reference

## Current visual provenance follow-up

Initial resource403/kit-uninspected statements below are dated research findings, superseded by the completed [native repair](../design/evidence/native-dialog-repair.json). Six genuine Apple-linked27 kit PNGs and two generic public UIKit26.5 captures are imported into authority11H4-0. The historical38 public UIKit26.5 case captures are no longer product controls: [current vector repair](../design/evidence/native-dialog-vector-repair.json) hides every whole-phone replacement and restores editable original Paper hosts/title/body/actions with official27-kit-derived geometry. Engineering phone annotations stay hidden; exact original copy/IDs/guards stay retained. SDK26.5/iOS26.5 build23F77 is not SwiftUI/AQD/iOS27 runtime proof. [Dialog provenance](native-ios-dialogs.md) and [asset terms/source hashes](../design/assets/native-dialogs/README.md) own the distinction. Manual deployment18/build stableSDK27 remains the specification, with separate native acceptance.


Research checked **October 7, 2026** (tool/system date). Research only: no Paper changes, app implementation, native build, commit or push. This note proposes a handoff; it does not supersede the existing design contracts or certify their drawings.

Context read: [DESIGN](../../DESIGN.md), [native iOS](../design/native-ios.md), [presentations](../design/native-presentations.md), [Liquid Glass](../design/liquid-glass.md), [components](../design/components.md), [rules](../design/rules.md), [quality criteria](../design/quality-criteria.md), [V1 architecture](../architecture/v1.md) and [V1 release](../product/v1-release.md). Preserve the complete private/manual core, opaque content, existing confirmation risk policy and optional capability boundaries.

## Recommendation

Historical research recommendation, now adopted/superseded by [native iOS](../design/native-ios.md). Any “inspect/import later”, uninspected-kit, proposed Foundations or drawings-awaiting-replacement language below describes the initial research run, not current pending work. Current kit/source-derived geometry is recorded in the provenance links above; exact AQD/runtime execution remains unverified.

- **Deployment minimum: recommend iOS 18.0**, retaining the existing V1 planning target. The selected manual/native APIs fit it; this is not evidence that an iOS 18 baseline has been implemented or tested.
- **Build/reference target: published stable Xcode 27 / iOS 27 SDK**, not a guessed future SDK. iOS 26 introduced Liquid Glass; iOS 27 is now independently confirmed published. Use the latest stable maintenance release available when implementation begins; do not adopt a beta simply because live documentation includes one.
- Use actual SwiftUI/UIKit controls on every supported OS. iOS 18 gets its own native appearance; 26/27 get their OS-owned appearance. Guard custom glass and newer conveniences by API availability; never emulate 27 on 18.
- Centered critical decisions use native **alert**. Routine intentional choices use native **confirmationDialog/action sheet**. “Middle” and “bottom” describe reference layouts, not two custom glass renderers or a guarantee of native placement.
- **Important correction for future design work:** Apple's iOS 26 UIKit action sheets can originate inline from their trigger on **iPhone as well as iPad**, and an inline action sheet can omit visible Cancel. Do not promise that current native action sheets always sit at the bottom with a separate Cancel group. Preserve a safe no-write cancellation outcome; let the system own layout and supported dismissal. This note changes no existing file or product decision.

## 1. Published platform / SDK status, not inferred branding

| Item | Direct primary evidence retrieved | Conclusion / limit |
| --- | --- | --- |
| iOS 27 shipping status | Apple Newsroom [September 14, 2026 update](https://www.apple.com/newsroom/2026/09/major-updates-for-apples-software-platforms-are-now-available/) | Public release coverage exists; 27 is not an unsupported future assumption in this research. |
| iOS 27 SDK | [27 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes), Overview | “The iOS & iPadOS 27 SDK provides support … running iOS & iPadOS 27. The SDK comes bundled with Xcode 27.” |
| Xcode 27 | [Xcode 27 notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes), Overview | “Xcode 27 includes Swift 6.4 and SDKs for iOS 27…”; requires macOS Tahoe 26.6+. |
| Older deployment supported by newer build SDK | [Xcode support table](https://developer.apple.com/support/xcode/), Xcode 27 row | iOS/iPadOS deployment targets **15–27**, device/simulator support **17 or later**. iOS 18 is within these ranges. Host macOS, SDK and deployment OS are distinct. |
| Prerelease maintenance tracks | Same support table retrieved October 7 | Lists **27.1 RC** and **27.2 beta 2** above stable 27. The live 27 notes also link prerelease maintenance notes. Do not interpret those as stable releases, or as a perfectly frozen October 7 snapshot. |
| Official visual resources | [Apple Design Resources](https://developer.apple.com/design/resources/) labels **iOS 27 and iPadOS 27** and links [official Figma kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27) | Apple-hosted listing/link verified. Direct Figma retrieval returned 403; kit contents, revision date and exact alert/action-sheet variants were **not inspected** here. |
| Liquid Glass origin | [WWDC25 SwiftUI](https://developer.apple.com/videos/play/wwdc2025/323/), [UIKit](https://developer.apple.com/videos/play/wwdc2025/284/), [adoption guide](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass) | Introduced with iOS 26/Xcode 26. This is evidence for 26-origin mechanics, not permission to relabel an authored 26 screenshot as verified 27 UI. |

Search summaries were discovery only. Conclusions above were checked against fetched Apple page bodies or Apple DocC JSON. JavaScript-rendered documentation was read at `https://developer.apple.com/tutorials/data/documentation/<public-path>.json`; HIG at `https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<topic>.json`. Symbol availability below comes from `metadata.platforms`: `name: iOS`, `introducedAt`, `beta`, `deprecated`. These are public documentation metadata, not a locally compiled SDK/header audit. Live documentation can describe later prereleases; verify selected SDK declarations at build time.

App Store upload SDK requirements are a **separate time-dependent distribution rule**. Recheck Apple's [submission requirements](https://developer.apple.com/app-store/submitting/) before shipping; this research does not assert a new submission deadline or confuse it with deployment minimum.

## 2. Transparency and native ownership

Apple [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), Liquid Glass section, says:

> “Don’t use Liquid Glass in the content layer.”

It describes a functional controls/navigation layer over content, with standard materials remaining available for content separation. It also says:

> “Most system components use this variant. Use the regular variant … when components have a significant amount of text, such as alerts, sidebars, or popovers.”

Here “regular” is the **Liquid Glass variant**, not the identically named older standard material. Native components decide their actual appearance; this is not an instruction to paint an alert ourselves.

The [adoption guide](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), “See your app with Liquid Glass,” instructs building with the latest SDKs and running on the latest platforms. Standard SwiftUI/UIKit components pick up the new appearance. Its visual refresh section asks developers to reduce custom backgrounds that interfere with system effects. Its presentations section explicitly says sheets/action sheets adopt Liquid Glass and full-height sheets transition to **more opaque** appearance. The WWDC25 SwiftUI presentation demonstrates menus, alerts and popovers flowing from their controls and dialogs automatically morphing from presenting buttons.

| Layer | AQD obligation | What not to do |
| --- | --- | --- |
| Native navigation/tab/toolbar/search/menu/presentation chrome | Use standard component, semantic intent/tint where supported, system safe areas and source anchor. Build with current SDK; inspect actual OS result. | No extra blur/material/`glassEffect` behind or on the system component. No fixed alpha, refraction, corners or scrim contract. |
| Custom floating composer or genuinely custom functional control | At 26+, consider one `glassEffect`/`UIGlassEffect` shell; group related custom effects only when necessary. Transparent inner editor must remain readable. | No stacked glass shells; no glass applied to response prose, garment grids, every button or form group. |
| Ordinary content | Retain opaque semantic grouped surfaces, fields, photo grounds, review text, messages and solid primary/plain secondary actions. | Do not make the host screen or dialog body arbitrarily transparent to prove “glass compatibility.” |
| Older OS | Native bars/presentations retain older system materials. A custom floating shell can use standard SwiftUI `Material` (15+) or an opaque semantic fallback. | Standard `Material`/`UIBlurEffect` is not an iOS 27 glass emulation. |
| Accessibility | Respect Reduce Transparency, Increase Contrast, Reduce Motion, Dynamic Type and VoiceOver. Custom surfaces need an opaque/stronger-boundary/static equivalent. | Do not force native glass to remain transparent or substitute a custom native-alert fallback. OS owns native adaptations. |

`glassEffect`, `GlassEffectContainer`, `UIGlassEffect` and glass button styles require **26+**, even with SDK 27. `UIVisualEffectView` itself is **8+**; choosing `UIGlassEffect` inside it still requires 26+. Materials have no universal opacity percentage. Regular favors legibility; clear is restricted to suitably rich backgrounds. Test actual moving backgrounds, not only flat-color contrast ratios.

## 3. Critical centered alert vs routine action sheet

### Native centered critical alert

Use SwiftUI `alert` or `UIAlertController(preferredStyle: .alert)`. Keep global erase, replacing restore, account deletion and qualifying substantial unrecoverable loss as final short decisions **after** necessary impact/typed/authentication review. Never make a reference confirmation ID a pushed page. Provide explicit Cancel and deliberate destructive action using native roles; the system may reorder actions. Do not force a horizontal layout or rely on coordinates for button order.

[Alerts HIG](https://developer.apple.com/design/human-interface-guidelines/alerts) permits a title, informative text and up to three buttons, with text fields on iOS/iPadOS. [SwiftUI alert documentation](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)) says the system may reorder buttons based on role/prominence and does not supply a default cancel action when you provide alert actions: explicitly supply `.cancel`.

Typed input is possible, not a mandate: [iOS 16 release notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-16-release-notes), SwiftUI item **64819930**, says a `TextField` can be placed in an alert using ViewBuilder alert modifiers. UIKit [addTextField](https://developer.apple.com/documentation/uikit/uialertcontroller/addtextfield(configurationhandler:)) is **8+** and expressly supports **only `.alert`**, not `.actionSheet`. AQD's richer typed ERASE/impact tasks remain forms before the final alert; don't compress them into a dialog or require the keyboard to remain visible behind a centered alert. Native keyboard placement wins over reference geometry.

### Routine confirmation / action-sheet family

Use SwiftUI `confirmationDialog` or `UIAlertController(preferredStyle: .actionSheet)` for intentional bounded delete/remove/discard/source choices. A short command menu is `Menu`; a rich task chooser/editor is `sheet`; neither becomes an action sheet solely to achieve a bottom visual.

[Action sheets HIG](https://developer.apple.com/design/human-interface-guidelines/action-sheets) says “Use an action sheet — not an alert — to offer choices related to an intentional action.” Its iOS/iPadOS section warns against too many buttons. The explicit **four including Cancel** limit appears in its **watchOS** section; AQD's four-action cap is a conservative existing product rule, not a universal iPhone SDK limit.

**Native layout caveat:** [WWDC25 UIKit](https://developer.apple.com/videos/play/wwdc2025/284/), Presentations transcript, states:

> “Starting in iOS 26, they behave the same on iPhone, appearing directly over the originating view.”
>
> “Action sheets presented inline don’t have a cancel button because the cancel action is implicit by tapping anywhere else. If you don’t specify a source, the action sheet will be centered, and you will have a cancel button.”

Apple asks UIKit callers to set `popoverPresentationController.sourceItem` or `sourceView` regardless of device. Anchor correctly; on iPad supply the bar/source item or appropriate source rect as required. **Do not omit an anchor to force a bottom layout.** SwiftUI's [confirmationDialog docs](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)) independently document regular-size-class popover adaptation, outside dismissal and absence of the standard dismiss action. They do not guarantee a fixed compact placement on every release. Verify SwiftUI 27 separately rather than extrapolate UIKit geometry.

The current AQD “bottom group / separate Cancel” drawings remain historical grammar references until a later authorized design pass. Safe cancellation is required even where the OS does not render a visible Cancel button. An outside tap can cancel a supported action sheet, **never confirm deletion**; do not invent outside-dismiss behavior for critical alerts. Dismiss command menus before presenting a decision. No custom glass effect, hand-painted red buttons or nested modal renderer around these native presentations.

Both families retain target/revision/scope, draft, selection, scroll and invoking focus. Cancel/interruption performs no record write. A deliberate confirmation starts the authorized operation, not an assumed success; stale scope, failure and unknown completion use existing validation/reconciliation. Alert backdrop content can remain visible but is not independently interactive while the modal owns focus.

## 4. Product-relevant native component catalog

Coverage is the native UI needed by AQD's current private and connected references, not literally every SDK class. API links own availability. Numbers are **iOS introduction versions for the linked SwiftUI symbol/overload**, unless explicitly marked UIKit; equivalents can have different introduction dates. New overloads/styles are not covered by a type's original minimum. Everything in the baseline column is available at the recommended 18 target.

| Family / API and baseline | Native platform counterpart | Obligation / 26–27 boundary |
| --- | --- | --- |
| Critical alert: [`alert(_:isPresented:actions:message:)`](https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)) **16** for linked overload; UIKit [`UIAlertController`](https://developer.apple.com/documentation/uikit/uialertcontroller) **8** | `.alert` | Critical final decision; native Cancel/destructive roles, no custom material. Alert text-field behavior is 16+ SwiftUI; UIKit alert-only input. |
| Routine choice: [`confirmationDialog`](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)) **16** for linked overload | `.actionSheet`, source-anchored popover | Native adaptive choice, not compulsory bottom geometry. Other title/data overloads have different minima; do not infer all dialogs started in 16. |
| Command menus: [`Menu`](https://developer.apple.com/documentation/swiftui/menu) **14**, `contextMenu` | UIMenu/UIAction, UIContextMenuInteraction | Native selected/disabled/destructive semantics; visible alternate entry for long press. 27 iPad menu-bar icon policy differs, below. |
| Navigation: [`NavigationStack`](https://developer.apple.com/documentation/swiftui/navigationstack) **16** | UINavigationController/UINavigationBar | Native Back/history/gesture, large/inline titles; restored state and safe areas, no custom bar background. |
| Toolbar: `toolbar`/ToolbarItem; [`ToolbarSpacer`](https://developer.apple.com/documentation/swiftui/toolbarspacer) **26** enhancement | UIToolbar/UIBarButtonItem | Native task grouping; ordinary existing toolbar composition on 18. [`toolbarMinimizationBehavior(_:for:)`](https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:)) is **27**, optional. |
| Search: [`searchable`](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:)-18a8f) **15** | UISearchController/UISearchBar | Scoped query, Cancel, native focus/keyboard positioning; don't pin a custom search capsule to a mockup coordinate. 27 center-placement scopes change, below. |
| Five root destinations: [`TabView`](https://developer.apple.com/documentation/swiftui/tabview) **13**, [`Tab`](https://developer.apple.com/documentation/swiftui/tab) **18** | UITabBarController/UITabBar | Preserve Today/Closet/Planner/Agent/Profile identities and restoration; Home is only an explicitly legacy/internal artifact alias. Native glass on 26+. [`tabBarMinimizeBehavior`](https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)) / [`tabViewBottomAccessory`](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(content:)) **26**, not baseline necessities. Icon-only caveat below. |
| Actions: [`Button`](https://developer.apple.com/documentation/swiftui/button) **13**, [`borderedProminent`](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/borderedprominent) **15** | UIButton/UIButton.Configuration | Native role, disabled/pending state and ≥44-point hit bounds. Preserve flat solid content primary/plain secondary policy; [`glassProminent`](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle/glassprominent) **26** only for justified glass roles. |
| Binary preference: [`Toggle`](https://developer.apple.com/documentation/swiftui/toggle) **13** | UISwitch | Native switch in labelled row; don't replace a job or navigation action with a switch. Native interaction optics may be glass without an added modifier. |
| One-choice / segments: [`Picker`](https://developer.apple.com/documentation/swiftui/picker) **13**, [`SegmentedPickerStyle`](https://developer.apple.com/documentation/swiftui/segmentedpickerstyle) **13** | UIPickerView/UISegmentedControl, native checked menu/list | Native iOS single-choice checkmark rows instead of forcing a macOS radio style. [`TabsPickerStyle`](https://developer.apple.com/documentation/swiftui/tabspickerstyle) **27** can improve content-tab semantics; not a new sixth root. |
| Multiple choice / packing | List selection or native Buttons in selectable rows | UITableView/UICollectionView selection | iOS has no universal SwiftUI checkbox/radio renderer for this product. Use native selection/checked traits; app supplies domain draft semantics. Square checkbox drawings don't authorize a custom control where native row selection suffices. |
| Date/calendar: [`DatePicker`](https://developer.apple.com/documentation/swiftui/datepicker) **13**, [`GraphicalDatePickerStyle`](https://developer.apple.com/documentation/swiftui/graphicaldatepickerstyle) **14**, [`MultiDatePicker`](https://developer.apple.com/documentation/swiftui/multidatepicker) **16** | UIDatePicker; [`UICalendarView`](https://developer.apple.com/documentation/uikit/uicalendarview) **16** | Explicit calendar/locale/timezone and date-only domain intent. Localized/relative display via Foundation date formatting; don't make device-zone formatting change saved planning day. Custom week/agenda content still needed. |
| Grouped forms: [`Form`](https://developer.apple.com/documentation/swiftui/form) **13**, [`List`](https://developer.apple.com/documentation/swiftui/list) **13** | Grouped UITableView / collection lists | Opaque semantic content sections; labels, selection/accessories, no glass card per row. |
| Scrolling: [`ScrollView`](https://developer.apple.com/documentation/swiftui/scrollview) **13** | UIScrollView | Native safe areas/scroll-edge behavior; final content stays reachable under chrome/keyboard. Custom garment/agenda content remains custom. |
| Editor sheet: [`sheet`](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)) **13**, [`presentationDetents`](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)) **16** | UISheetPresentationController **15** | Fit content/keyboard/Dynamic Type; system chrome and opacity transition. [`interactiveDismissDisabled`](https://developer.apple.com/documentation/swiftui/view/interactivedismissdisabled(_:)) **15** prevents loss but is not a discard-attempt callback; use presentation delegate where an attempt must be handled. |
| Inspector/popover: [`popover`](https://developer.apple.com/documentation/swiftui/view/popover(ispresented:attachmentanchor:arrowedge:content:)) **13** | UIPopoverPresentationController | Source anchoring; adaptive compact sheet; don't force desktop geometry. |
| Focused Agent/task: [`fullScreenCover`](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)) **14** | Modal full-screen UIViewController | Native navigation/dismissal; restore originating tab/focus/draft. Agent as a tab-triggered action remains a product tab-model exception, not HIG certification. |
| Progress: [`ProgressView`](https://developer.apple.com/documentation/swiftui/progressview) **14** | UIActivityIndicatorView/UIProgressView | Indeterminate vs genuinely measured progress; retain label/draft and block duplicate commits. |
| Short/multiline input: [`TextField`](https://developer.apple.com/documentation/swiftui/textfield) **13**, [`axis` initializer](https://developer.apple.com/documentation/swiftui/textfield/init(_:text:axis:)) **16**, SecureField | UITextField **2** | Native selection/content type/autofill/validation/keyboard; opaque shell, not glass. [`TextInputBorderShape`](https://developer.apple.com/documentation/swiftui/textinputbordershape) **27** optional, not an instruction to add borders to AQD fields. |
| Long-form editor: [`TextEditor`](https://developer.apple.com/documentation/swiftui/texteditor) **14**, [`FocusState`](https://developer.apple.com/documentation/swiftui/focusstate) **15** | UITextView **2**, first responder | Bounded composer growth, draft retention; focus once deliberately, no keyboard restart loop. |
| Keyboard/accessory/edit menu: [`safeAreaInset`](https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)) **15** | [`inputAccessoryView`](https://developer.apple.com/documentation/uikit/uiresponder/inputaccessoryview) **3.2**, UIInputView **7**, [`UIEditMenuInteraction`](https://developer.apple.com/documentation/uikit/uieditmenuinteraction) **16** | OS keyboard/editing UI. Optional custom accessory uses supported views; adding glass does not authorize painting keyboard chrome or covering safe areas. |
| Selected Photos: [`PhotosPicker`](https://developer.apple.com/documentation/photosui/photospicker) **16** | PHPickerViewController **14** | Load/copy selected authorized media; cancel/failed load preserves draft. Native picker, not fake library permission UI. |
| Camera: [`UIImagePickerController`](https://developer.apple.com/documentation/uikit/uiimagepickercontroller) **2** | System camera presentation via UIKit bridge | Availability/permission/denial/interruption; native default camera. AVFoundation custom capture isn't required merely for glass. |
| Files import/export: [`fileImporter`](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:)) / [`fileExporter`](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttype:defaultfilename:oncompletion:)) **14** | UIDocumentPickerViewController | Security-scoped access where needed, ready archive, explicit destination, validated staged restore; 27 document API changes do not require rewriting the archive workflow. |
| System share: [`ShareLink`](https://developer.apple.com/documentation/swiftui/sharelink) **16** | [`UIActivityViewController`](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller) **6** | Share prepared authorized file/URL; cancellation isn't saving/publishing; iPad anchor. |
| Unavailable/empty: [`ContentUnavailableView`](https://developer.apple.com/documentation/swiftui/contentunavailableview) **17** | UIContentUnavailableConfiguration | Honest empty/offline/denied/model-unavailable distinction and manual recovery; native primitive can contain product-specific text/actions. |
| Optional tip: [`TipKit.Tip`](https://developer.apple.com/documentation/tipkit/tip) **17** | TipUIPopoverViewController/TipUIView | Optional contextual hints, not replacement for existing tour/task contract. Full product walkthroughs stay phase-owned. |
| Appearance/type/accessibility: [`ColorScheme`](https://developer.apple.com/documentation/swiftui/colorscheme), [`Font`](https://developer.apple.com/documentation/swiftui/font), [`accessibilityReduceTransparency`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducetransparency), [`accessibilityReduceMotion`](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion), [`colorSchemeContrast`](https://developer.apple.com/documentation/swiftui/environmentvalues/colorschemecontrast) **13** | UIColor semantic colors, UIFont text styles/UIFontMetrics, UIAccessibility | System/Light/Dark preference, semantic type, scalable symbols, contrast/motion/opaque fallbacks and VoiceOver names/traits/focus. No fixed OS material colors or SF font substitution in production. |
| Custom functional material: [`Material`](https://developer.apple.com/documentation/swiftui/material) **15**; [`glassEffect`](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) / [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) **26** | [`UIVisualEffectView`](https://developer.apple.com/documentation/uikit/uivisualeffectview) **8**, [`UIGlassEffect`](https://developer.apple.com/documentation/uikit/uiglasseffect) **26** | Only justified custom chrome; guard 26 effects and preserve 18 native/opaque fallback. Never wrap native alerts/action sheets/menus. |

V2 sign-in uses the official [SignInWithAppleButton](https://developer.apple.com/documentation/authenticationservices/signinwithapplebutton), not a hand-drawn Apple logo button; it is not part of V1's manual gate. Permission prompts remain OS-owned. SF Symbols and system typography are platform resources subject to Apple's terms, not artwork to redraw as a fake native UI.

### Native five-tab/icon-only constraint

[Tab bars HIG](https://developer.apple.com/design/human-interface-guidelines/tab-bars) explicitly says **“Include tab labels to help with navigation.”** Its platform-specific guidance must not be mixed across iOS and visionOS. SwiftUI [`labelsVisibility`](https://developer.apple.com/documentation/swiftui/view/labelsvisibility(_:)) **18+** applies to labelled content such as Toggle/Picker; it is **not documented as tab-caption suppression**. Hiding a tab with `defaultVisibility` hides the destination, not just its caption.

UIKit [`UITabBarItem.init(title:image:tag:)`](https://developer.apple.com/documentation/uikit/uitabbaritem/init(title:image:tag:)) expressly permits `nil` title to omit that element. This is a public native route to test for AQD's icon-only requirement, but **not** proof of preferred HIG behavior, identical SwiftUI support, five equal fixed widths on all platforms or unchanged 27 geometry. Provide explicit accessibility labels/selected traits; test before selecting a bridge. Do not use private subview manipulation or offscreen title offsets. If native current behavior cannot meet the icon-only brief robustly, return that conflict to the owner rather than silently replace the native bar with a custom glass imitation.

### Verified product-relevant 27 changes

[27 notes](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes), SwiftUI/UIKit sections, identify:

- **TabsPickerStyle** (173211711): like segmented selection, but VoiceOver reads it as tabs. 27-only enhancement with ordinary segmented Picker on 18/26.
- **TextInputBorderShape** and `.bordered` field style (173362083): existing square/rounded-border styles are soft deprecated. Don't add this to preserve old fixed field geometry; adopt only where appropriate and guarded.
- **TabView visible-selection enforcement** (164516837): apps built with SDK 27 may crash if selection is a hidden/unavailable tab. Keep the Agent destination visible and preserve valid selection during full-screen launch/return.
- **Selectable Text** now has interactive system selection under SDK 27 (79770704): review Agent Markdown copy/selection and gesture conflicts; don't intercept its native gestures accidentally.
- **Menu images**: iPadOS 27 menu bar/macOS context menu image visibility changes (170480710/170479084), not a claim that every iPhone popup loses its symbols. Use supported semantic image policy; don't hard-code the Paper symbol lane universally.
- **Search scopes** (173860616): SDK-27 UIKit center search placement puts scope controls inline with the field; validate localized labels/keyboard width.
- **Presentation environment reset** (167448274): control sizing/button style environment effects in sheet/popover content need rechecking with SDK 27.
- **Toolbar/navigation minimization renames** (177954148/177953926); don't treat old 26 convenience names as permanent new APIs.
- **Files** introduce new async document protocols/export overloads and deprecations; archive import/export can retain a supported native document interface. Do not assume every new 27 overload back-deploys because an older `fileExporter` did.
- **App lifecycle**: SDK-27 UIKit notes require scene lifecycle and launch-screen configuration. Future implementation must check these build obligations; no app migration is performed here.

The fetched 27 release notes do **not** establish a separate new alert material specification. Their mention of alert/confirmationDialog back-deployment (179388848) is API availability, not new visual geometry. The verified route to “iOS 27 design” is native 27 controls/current official kit and subsequent runtime checking, not copying a 26 still and changing its label.

## 5. Minimum OS rationale

| Dependency | Verified Apple API minimum | Impact |
| --- | --- | --- |
| NavigationStack, PhotosPicker, ShareLink, detents | **16** | Does not require 26/27 deployment. |
| [WeatherService](https://developer.apple.com/documentation/weatherkit/weatherservice) | **16** | Optional weather; entitlement/network independent of AI readiness. |
| [SwiftData ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer), if adopted | **17** | Architectural proposal, not reason to rewrite an existing suitable store. |
| ContentUnavailableView / TipKit | **17** | Baseline UI fits 18; TipKit remains optional. |
| [VNGenerateForegroundInstanceMaskRequest](https://developer.apple.com/documentation/vision/vngenerateforegroundinstancemaskrequest) | **17** | Objective-C Vision API; optional local cleanup still needs device/performance evidence. |
| [GenerateForegroundInstanceMaskRequest](https://developer.apple.com/documentation/vision/generateforegroundinstancemaskrequest) | **18** | New Swift Vision API fits chosen 18 target. Availability isn't a guarantee of good garment masks. |
| New SwiftUI Tab API | **18** | Fits current root-navigation architecture; older TabView itself is 13+. |
| [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel) | **26**, plus runtime eligibility/readiness | Optional Agent/model capability. Must not raise complete manual core to 26; availability checks/reason-specific fallback required. |
| Custom Liquid Glass APIs | **26** | Optional custom chrome; native older rendering at 18. |
| TabsPickerStyle / TextInputBorderShape / new minimization API | **27** | Guarded enhancements only. |

**Choose 18**, not 26 just for glass. A 16 target is conceivable only after changing selected 17/18 dependencies and proving alternate persistence, unavailable-state and Vision paths; that is not this task's decision. A 17 target could use the older Vision API and tab construction, but would depart from the current 18 planning default with extra verification burden. 18 is a justified bounded recommendation, not an absolute SwiftUI requirement. SDK 27 can build an 18-deployment app; `#available`/compatible fallback is required wherever newer APIs are referenced.

## 6. Proposed Foundations section: “Transparency · Native iOS”

**Proposal only; no canvas edits.** Keep existing primitive identities where usable (Foundations `4GB-0`, alert `FJ2-1`, action-sheet `ZGG-0`). Six reusable reference-board types, not six new full app screens:

| Board type / small specimen sketch | Specification / source obligation |
| --- | --- |
| **1 — Transparent chrome**: cropped opaque sample content → native navigation/toolbar, search and five-tab strip | Annotate SDK/OS, native API, source anchor, functional layer, safe-area behavior and icon-only caveat. Compare 18 native vs 26-origin glass vs verified 27 resource when available; no fake optical painting. |
| **2 — Opaque content**: neutral grouped rows → labelled field → selected/check row → solid/plain actions | Preserve current semantic surfaces, image grounds, Dynamic Type and Increase Contrast. Explicit “no custom glass” boundary prevents the transparency section from changing the whole app. |
| **3 — Native centered alert**: generic cropped host → short critical title/impact → Cancel + destructive action | Bind to `.alert`, risk policy, roles and no-write cancel. Native material/ordering/keyboard wins; sample is structure, not certified dimensions. Typed gate stays an adjacent task note, not a custom interactive scene behind the alert. |
| **4 — Native action-sheet family**: trigger + generic host → related choices → supported cancellation | Show source-anchored 26/27 behavior and older bottom grammar separately with accurate labels; annotate iPad popover and native absence of visible Cancel. A bottom specimen is not a forced 27 placement contract. |
| **5 — Native controls/open states**: menu + switch + segmented/value choice + date + sheet/popover samples | Small catalog aligned to section 4; selected/disabled/destructive/loading/focus/invalid states, native API/minimum, return/no-write semantics. Photos/camera/Files/share/keyboard illustrated only with official or later actual OS captures, not fabricated system UI. |
| **6 — System accessibility states**: same small chrome/control/decision strip in dark, reduced transparency, increased contrast, larger text and reduced motion | Semantic contrast/focus/traits and opaque custom-shell fallback; use state annotations for motion/VoiceOver, not invented screenshots proving behavior. No full phone accessibility journey cloned into Foundations. |

All six include **API · minimum OS · build SDK · OS provenance · static vs runtime status**. Reference dimensions illustrate hierarchy only. Product confirmations, source scenes, tour, garment records and flow screenshots remain V1/V2-owned. No copyrighted kit assets bundled/relicensed without checking Apple's resource terms; no hand-drawn SF/OS glass presented as genuine native certification.

### Visual provenance available for later design work

- **Current 27 visual source:** Apple [Design Resources](https://developer.apple.com/design/resources/) → [official 27 Figma kit](https://www.figma.com/community/file/1651309003795292092/ios-and-ipados-27). Listing is verified; import/inspect actual dialog components later under authorization. No kit-content certification here.
- **26 native mechanics and visual demonstrations:** [WWDC25 UIKit video](https://developer.apple.com/videos/play/wwdc2025/284/) Presentations, and [SwiftUI video](https://developer.apple.com/videos/play/wwdc2025/323/) Sheets/dialogs/toolbars. Their transcripts were fetched; videos supply first-party demonstrations, not AQD runtime screenshots. Label any extracted still as **WWDC25 / iOS 26 demonstration**, with timestamp, not “iOS 27 native pass.” No stills were extracted here.
- **HIG alert structure:** [Alerts DocC JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/alerts.json) identifies `alert-ios.png`, alt “An illustration of an alert in the middle of the screen on iPhone,” and light/dark variants. It does not date that illustration as iOS 27. Direct documented relative image paths returned 404 when resolved against developer.apple.com; don't import a missing image or fabricate its replacement.
- **HIG routine-choice structure:** [Action sheets JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/action-sheets.json) identifies `action-sheet-iphone-mail-delete-action.png` showing Mail draft choices. Same direct-image retrieval limitation; use the live HIG/resource UI later. Its stylized intro thumbnail is not a current-release runtime screenshot.

**No claim that existing Paper middle/bottom dialogs are genuine 27 controls.** Native API behavior and verified current visual resources are the handoff; exact 27 alert/action-sheet pixel comparison remains outstanding.

## 7. Outstanding native acceptance

No native/UI tests were run. Before implementation is complete, verify a signed SDK-27 build with deployment 18 on:

- iOS **18**, **26**, **27**; compact/large iPhone, landscape/keyboard and iPad regular width for presentation adaptation (iPhone remains initial product target).
- System/Light/Dark, largest accessibility Dynamic Type, VoiceOver/Switch Control, RTL and long translations; Reduce Transparency, Increase Contrast and Reduce Motion separately and together.
- Centered alert, source-anchored/older action-sheet presentations, implicit/explicit cancellation, actual title/action order, disabled destructive gate, outside tap, interruption and focus return. Critical loss never commits by dismissal.
- Native five-tab labels/icon-only feasibility, selected traits/valid selection, preserved stacks, Agent launch/return and final-content safe-area access. Record any HIG exception explicitly.
- Sheet detents/full-height opacity, popover anchors, dirty-dismiss attempts, camera/Photos/Files/share cancellation/failure and security-scoped files; one presentation owner at a time.
- Input/autofill/keyboard/edit menu, initial focus, native interactive text selection, input accessory/composer growth and no obscured Save/Send.
- Material legibility over light/dark/photographic/moving content; opaque content unchanged; custom-shell 18 fallback; no duplicate glass. Physical-device Instruments check before claiming smoothness.
- Optional weather, model and Vision capability unavailable/failed paths with manual core still usable; compile/check every selected 26/27 API guard against the actual SDK.

Historical research-run boundary: primary publication/API research completed; that run did not verify kit inspection, exact 27 visual certification, app baseline, device behavior or performance. Subsequent kit inspection/import supersedes only the kit-inspection limitation; current AQD runtime/device/performance remains unverified. Only this research file is written; unrelated WeatherKit/canvas changes are preserved.
