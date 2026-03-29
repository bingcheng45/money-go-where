# MoneyGoWhere

MoneyGoWhere is a native SwiftUI iOS prototype for recurring cashflow tracking with a chat-first workflow and a calendar-led dashboard.

## Source Of Truth

- Product source of truth: `docs/PRD.md`
- Execution and progress tracker: `docs/TODO.md`

Future implementation work should reference the PRD first, then update the todo list as progress changes.

## What is implemented

- Multi-step onboarding with profile, consent, first recurring item, preview, and paywall
- Chat-based recurring income and expense capture with deterministic extraction and confirmation
- Persisted chat history with a sidebar
- Dashboard with month summary, calendar projections, item management, and insights
- Multi-currency support with reference FX conversion for rollups
- Local reminder scheduling hooks
- Mock subscription service shaped for RevenueCat integration
- Cloud sync and account services defined behind protocols with local placeholder implementations

## Project notes

- The repo started empty, so this implementation is a greenfield SwiftUI app with a generated Xcode project.
- Real backend sync, RevenueCat SDK wiring, and Sign in with Apple account flows are intentionally abstracted behind protocols because no production credentials or backend contract were present.
- The app persists locally to JSON in Application Support and is ready to be swapped to a remote-backed repository.

## Build

1. Run `ruby scripts/generate_xcodeproj.rb` if the project file needs to be regenerated.
2. Open `MoneyGoWhere.xcodeproj` in Xcode or use `xcodebuild`.

