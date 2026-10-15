# Issue21 S1 physical proof

Four focused acceptance journeys passed on the physical iPhone17ProMax, iOS27.0.1/24A446, with zero failures/skips. [Receipt](receipt.json) records exact selected cases, source hashes, actual environment, unchanged full-viewport screenshots and their inspection. Publication remains pending the issue21 PR.

- [Mixed review](review-mixed.png): explicit selected answers and body-use Off, separate docked Save.
- [All-declined review](review-all-declined.png): six explicit refusals are valid; body-use remains Off.
- [Confirmed save failure](confirmed-save-failure.png): visible retained-review warning and same-operation Retry.
- [Unknown acknowledgment](unknown-save.png): mutation blocked; Check save reconciles the same operation. The test also passes exact receipt recovery after relaunch.

The real tests additionally assert Profile/Settings source return, review editing, draft restart, no-write dismissal, discard preserving prior saved preferences, and saved-answer relaunch. These images alone do not establish those writes/returns. Advanced body inputs, onboarding and tour are later slices; broad E2E remains #30. The isolated synthetic cases contain no ordinary closet or Photos data. Full original results and inputs are retained at the local proof directory named in the receipt; these are not remote artifact links.
