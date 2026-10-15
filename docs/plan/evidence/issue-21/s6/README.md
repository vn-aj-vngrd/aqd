# S3 height conversion review correction

[Codex finding](https://github.com/vn-aj-vngrd/aqd/pull/33#discussion_r4284764022) reproduced five failing public-seam assertions:182.87999999999cm formatted5ft12in, became invalid and could not switch back. Display now carries rounded12in into6ft0in while preserving canonical cm. Codable restoration, switchability and exact canonical value pass.

Core34, native96 and the focused physical height/custom-picker/saved-Settings journey1/1 pass with zero failures/skips. Final unsigned Release builds. [Receipt](receipt.json) records source hashes, results and original images. [Boundary](rounded-height.png) shows6ft0in with enabled units; [Review](review.png) shows the subsequent normal height/custom/comfort/colors journey still works with body use Off. The case also proves draft restart, switching back and saved Settings reopening. No ordinary data reset or local simulator.

Earlier [feature evidence](../README.md) keeps its own source/result identity. Entry/tour/receipt/confirmation and unrelated flow inputs remain unchanged; the new correction refresh covers affected formatting/validation and the normal height journey. Full current-head hosted CI and Codex review remain required after this commit.
