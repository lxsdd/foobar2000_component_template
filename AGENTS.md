# Repository rules

## GitHub-first migration (2026-09-30)

GitHub is canonical for source history and fresh-runner qualification. The migration does not authorize new product behavior or open a research/UI/hardware gate. Preserve all pre-existing safety contracts. Never upload keys, credentials, personal media, SDK caches, or generated build output. Candidate artifacts are bound to the exact commit and SHA-256, retained for 90 days. Runtime acceptance must use those exact bytes. No release is authorized by migration; a future promotion must reuse the accepted candidate without rebuilding and must not overwrite tags/assets.
