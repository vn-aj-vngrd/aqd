# S3 nonzero display precision correction

[Codex finding](https://github.com/vn-aj-vngrd/aqd/pull/33#discussion_r4284964778) reproduced20 assertions across tiny positive finite measurements, including conversion underflow. Decimal formatting now falls back to nonzero scientific text when ten decimal places would display zero. The smallest converted value stays positive. Canonical centimeters remain untouched; no arbitrary minimum height was added.

Core35/native96 pass, zero failures/skips. The extended physical height journey passes1/1, including literal0.00000000001cm, nonzero ft/in, enabled units, restart/exact canonical return, S6 whole-foot boundary and the existing normal-height/custom-picker/saved-Settings journey. Release builds; tooling57 and agent docs pass. Independent Standards/Spec rechecks found no actionable issue.

[Original inspected image](tiny-positive-height.png) shows the nonzero field and enabled unit picker. Long scientific text uses native unfocused truncation; complete-value assertions and switch-back establish its actual magnitude. [Receipt](receipt.json) retains exact source/product/image hashes and results. No ordinary-data reset, private capture publication or local simulator.

Earlier [feature](../README.md) and [S6](../s6/README.md) results retain their actual source identities. Unaffected screens and behavior are reused; final-head hosted CI and Codex remain separate required gates.
