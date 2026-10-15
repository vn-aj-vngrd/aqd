# Native splash rendering

`EntryRenderingTests/testNativeLaunchWordmarkMatchesPaperInLightAndDark` instantiates the compiled `LaunchScreen.storyboard`, mounts it in a real UIWindow on the physical iPhone and verifies the44pt centered wordmark and text containment. Both original, full-viewport attachments were inspected: [light](light.png), [dark](dark.png). No image was altered.

The source is the issue21 S2/S3 working tree on `eec38f0`, tested with Xcode27.0/27A266a on physical iPhone17ProMax, iOS27.0.1. `build/issue-21/screens-native-final.xcresult` reports95 native tests passed, zero failures/skips; all33 Core tests also passed. This proves compiled launch artwork in both appearances. It does not measure system launch timing or impose a delay. The app uses the same opening surface while loading actual local state.

A later Ready illustration-only correction selects the approved sand linen trousers. Launch, Core, persistence and native test inputs remain unchanged; the final UI proof compiles that correction separately. [Issue plan](../../../issue-21.md) owns final source/commit receipts and sequence proof. Publication remains pending.
