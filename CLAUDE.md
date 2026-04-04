# AnyLanguageModel (Techopolis Fork)

## Fork Relationship

- **Origin:** `https://github.com/Techopolis/AnyLanguageModel.git`
- **Upstream:** `https://github.com/mattt/AnyLanguageModel.git`
- **Consumer:** Perspective Intelligence app (`/Packages/PerspectiveLLM/` references this via local path)

## Fork-Specific Files

These files exist only in our fork and should never conflict with upstream:

- `Sources/AnyLanguageModel/DownloadableLanguageModel.swift` — `DownloadableLanguageModel` protocol + `MLXModelDownloadManager`
- `Sources/AnyLanguageModel/Models/MLXLanguageModel.swift` — contains the download manager extension at the end of file (after upstream's `JSONValue.toSendable()`)
- `scripts/validate-merge.sh` — post-merge validation
- `scripts/check-upstream.sh` — upstream divergence tracking

## Upstream Sync Procedure

1. Check divergence: `./scripts/check-upstream.sh`
2. Prefer **rebase** over merge when possible: `git rebase upstream/main`
   - Rebase resolves conflicts per-commit (smaller, easier to reason about)
   - Use merge only when rebase would rewrite published/shared history
3. Validate after sync: `./scripts/validate-merge.sh`
4. Rebuild Perspective Intelligence to verify consumer compatibility

## Common Merge Pitfalls

After merging upstream, watch for these residual fork artifacts:

- **Duplicate type declarations** — Our fork previously defined `GPUMemoryConfiguration`, `GPUMemoryManager`, and `SessionCacheEntry` at the module level. Upstream defines them inside `MLXLanguageModel`. After merging, only the nested (upstream) versions should exist.
- **Old cache API** — Our fork used `hashTokenPrefix`, `prefillTokenHash`, `resolveCache(for:...)`. Upstream uses `prefixTokens`, `cacheConfigSignature`, `resolveCache(session:...)`. The fork versions are dead code after merge.
- **Scope-less GPU calls** — Our fork's `markActive()` / `markIdle()` take no args. Upstream's take `GPUMemoryConfiguration` / `scope: UUID`. If you see parameterless calls, they're from the old fork.

The `validate-merge.sh` script checks for all of these automatically.

## Build

```bash
swift build                              # SPM build (macOS)
swift build --traits MLX                 # with MLX trait
```
