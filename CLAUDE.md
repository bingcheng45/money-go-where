# MoneyGoWhere — Claude Code Project Context

## Project Overview

MoneyGoWhere is a native SwiftUI iOS app for recurring cashflow tracking with a chat-first workflow and calendar-led dashboard. Single-user, local-first, with protocols abstracting RevenueCat, CloudKit, and Sign in with Apple.

- Product source of truth: `docs/PRD.md`
- Execution tracker: `docs/TODO.md`
- Figma: https://www.figma.com/design/oe1CYpI3eK1OxGmj93eC5m/MoneyGoWhere

## Architecture

```
MoneyGoWhere/
├── App/          # Entry point, app lifecycle
├── Domain/       # Models, protocols, business logic (pure Swift, no UIKit/SwiftUI)
├── Services/     # Protocol implementations (local JSON, mock cloud, mock RevenueCat)
├── Views/        # SwiftUI views organized by feature tab
```

Key domain entities: `UserProfile`, `RecurringItem`, `OccurrenceProjection`, `ChatThread`, `ExtractionDraft`, `FinanceMemory`, `CatalogEntry`.

## Swift Conventions

- Swift 6 strict concurrency — all new code must compile clean with `SWIFT_STRICT_CONCURRENCY=complete`
- Prefer `let` over `var`; `struct` over `class` unless reference semantics are required
- `@MainActor` on all View models; actors for shared mutable state
- Typed throws where error type is known at call site
- Follow Apple API Design Guidelines — clarity at point of use, omit needless words
- No force-unwrap (`!`) in production code; use `guard let` / `if let` / `throw`

## Testing

- Framework: Swift Testing (`import Testing`, `@Test`, `#expect`)
- Tests live in `MoneyGoWhereTests/`; one test file per service/engine
- Each test creates fresh instances — no shared mutable state
- Run: `xcodebuild test -scheme MoneyGoWhere -destination 'platform=iOS Simulator,name=iPhone 16'`
- See skill `swift-protocol-di-testing` for mock patterns with protocol injection

## Build

```bash
# Regenerate project file if needed
ruby scripts/generate_xcodeproj.rb

# Build
xcodebuild build -scheme MoneyGoWhere -destination 'platform=iOS Simulator,name=iPhone 16'

# Test
xcodebuild test -scheme MoneyGoWhere -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Workflow Guidelines

### Before implementing anything
1. Read `docs/PRD.md` to confirm scope — do not implement out-of-scope features (bank sync, voice, multi-user)
2. Check `docs/TODO.md` for current phase and open tasks
3. Run a build to confirm baseline is green before making changes

### Planning
- Use `plan` mode (`/plan`) for any change touching 3+ files
- Break work into phases that each complete within ~50% context window
- Keep PRs small — one feature per PR, squash merge

### Context management
- Run `/compact` when context reaches ~50% to avoid degraded output
- Use `/rewind` (Esc Esc) to undo off-track execution before it cascades

### Code review
- After writing code, use the `code-review` skill or `/oh-my-claudecode:ask` for a review pass
- Never self-approve in the same context pass that wrote the code

## Out of Scope (v1)

Do not implement: bank sync, household collaboration, voice input, image receipts, fully unrestricted LLM financial advice, deep card management.

## Protocols — Do Not Concrete-ify

These are intentionally behind protocols with local placeholders. Do not wire real SDKs unless explicitly asked:
- `CloudSyncService` — no real CloudKit calls
- `AccountService` — no real Sign in with Apple
- `SubscriptionService` — no real RevenueCat SDK

## Security

- No API keys, tokens, or secrets in source files — use `.env` or Xcode build settings
- No hardcoded FX rates in production paths — use the service layer
- The `keys/` directory is git-ignored; never commit `.p8` files

## OMC Agent Routing

- Multi-file changes or refactors → delegate to `executor` agent
- Architecture decisions → `architect` agent
- New feature planning → `planner` agent or `/oh-my-claudecode:plan`
- Deep Swift/SwiftUI pattern questions → `swift-concurrency-6-2` or `swiftui-patterns` skills
- Test setup → `swift-protocol-di-testing` skill or `tdd` skill
