# Agent grounding and evaluation research

October 17, 2026. Implementation research for the owner-authorized local Agent refinement.

Apple documents a4096-token on-device session window shared by instructions, input and output. Use compact facts and relevant bounded retrieval, not a database dump or ever-growing hidden transcript. Preserve conversation instructions or explicitly request a new chat when the budget is exhausted. Character limits are conservative guards, not exact token counts.

- [Context window guidance](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [Foundation Models generation](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)
- [Evaluation guidance](https://developer.apple.com/documentation/foundationmodels/evaluating-prompts-to-measure-performance-and-improve-model-responses)
- [Tool calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling)

Use deterministic domain queries for totals, availability and recorded wear; retrieve useful saved text across collections with clear provenance and omissions. Imported names, notes, prior generated text and feedback comments are data, never authority to execute actions. Saved plans are not wear. An archive/history mention does not make a piece available for a new outfit. Body-purpose consent and Weather consent/freshness remain independent. Photo pixel interpretation is outside the current text-only provider.

Evaluation must distinguish deterministic pipeline tests, fixture response checks and actual on-device generated responses. Define expected facts, exclusions, budget/permission behavior and failure taxonomy before measuring. A code-only score does not establish model quality, and user ratings do not train the system model. Keep test data synthetic; never silently collect a user's wardrobe/chat for diagnostics. Future reporting uses a versioned, explicitly reviewed payload; no endpoint is configured or contacted in this increment.
