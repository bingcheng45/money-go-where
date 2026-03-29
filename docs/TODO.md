# MoneyGoWhere Execution Todo

This file translates `docs/PRD.md` into an implementation checklist. Update it as work progresses. If scope changes, update the PRD first, then reflect the change here.

Status legend:
- `DONE`: implemented in the current repo
- `NEXT`: highest-priority next work
- `LATER`: planned but not implemented yet
- `BLOCKED`: cannot be completed until an external dependency or decision exists

## 1. Product Foundation

- `DONE` Create native SwiftUI iOS project structure and Xcode project generator.
- `DONE` Define core entities from the PRD: profile, recurring item, projections, chat thread, extraction draft, memory, catalog, aggregate stats, entitlements.
- `DONE` Persist app state locally as JSON so product flows work end to end.
- `NEXT` Add app-level settings screen to expose profile defaults, consent state, and subscription state.
- `LATER` Add schema migration strategy for persisted local data.

## 2. Onboarding And Monetization

- `DONE` Implement onboarding flow for value prop, currency/locale, payment-method label, first recurring item, preview, and paywall.
- `DONE` Implement mock subscription offerings with 7-day trial and monthly/yearly plans.
- `DONE` Enforce read-only mode after premium access expires in the current app model.
- `NEXT` Replace mock subscription service with real RevenueCat SDK integration.
- `NEXT` Implement proper entitlement refresh, restore, and eligibility-driven paywall copy from RevenueCat.
- `BLOCKED` Final yearly plan price is still TBD in the PRD.

## 3. Chat Tab

- `DONE` Implement chat screen shell aligned to the current Figma direction.
- `DONE` Persist chat threads and sidebar navigation.
- `DONE` Build deterministic parser/extractor for recurring finance input.
- `DONE` Require review and confirmation before saving extracted items.
- `DONE` Preserve structured finance records even when chat threads are deleted.
- `NEXT` Improve multi-turn extraction so follow-up answers merge more intelligently into pending drafts.
- `NEXT` Add more robust natural-language date parsing and cadence handling.
- `NEXT` Add finance memory usage beyond simple defaults and last-item context.
- `LATER` Add safe summarization layer if it can be kept compliant with the PRD constraints.

## 4. Dashboard

- `DONE` Implement month summary cards, month navigation, date selection, item list, and insights section.
- `DONE` Implement recurring calendar projection engine.
- `DONE` Implement manual add/edit sheet, item pause, and item delete.
- `DONE` Implement per-item reminder toggle fields in the editor model.
- `NEXT` Improve calendar cell design to better match a polished iOS production UI.
- `NEXT` Add overdue/upcoming visual states and stronger empty states.
- `NEXT` Add item detail presentation separate from the editor for better review flow.
- `LATER` Add a dedicated settings/dashboard management surface for notification defaults and profile defaults.

## 5. Catalog, Insights, And Aggregate Learning

- `DONE` Seed catalog defaults for popular subscription entries and salary.
- `DONE` Implement autocomplete-driven manual entry suggestions.
- `DONE` Implement rule-based insights for duplicates, category concentration, heavy spend days, and aggregate popularity.
- `NEXT` Expand seeded catalog coverage and normalize aliases/pricing defaults.
- `NEXT` Split internal catalog data from aggregate opt-in signals more clearly in storage and service boundaries.
- `LATER` Replace local aggregate placeholders with real anonymized backend-fed aggregate defaults.

## 6. Currency, Notifications, And System Services

- `DONE` Support per-item original currency plus converted home-currency rollups.
- `DONE` Add reference FX conversion service with rounded outputs.
- `DONE` Add local reminder scheduling abstraction and notification authorization handling.
- `NEXT` Replace placeholder FX rates with a real reference-rate service and update cadence.
- `NEXT` Make reminder scheduling update recurrence-aware after each fired notification.

## 7. Backend, Account, And Sync

- `DONE` Define placeholder protocols for account bootstrapping and cloud sync.
- `NEXT` Implement Sign in with Apple and account bootstrap flow.
- `NEXT` Add remote persistence for profile, recurring items, finance memory, and chat threads.
- `NEXT` Add sync conflict strategy where structured records remain source of truth.
- `LATER` Prepare schema boundaries for future household support without enabling it in v1.

## 8. Design And Figma Follow-Through

- `DONE` Use the current Figma file as reference for the chat shell and sidebar direction.
- `NEXT` Design and implement the missing dashboard screens that are not yet present in Figma.
- `NEXT` Design and implement settings, paywall polish, and item detail flows not present in Figma.
- `LATER` Reconcile the current implementation against any future Figma updates once dashboard designs exist.

## 9. Quality And Verification

- `DONE` Add core unit test files for assistant parsing, projection engine, insights, and currency conversion.
- `DONE` Typecheck app sources directly against the iPhone Simulator SDK with `swiftc`.
- `DONE` Run a lightweight runtime harness for parser, FX conversion, and insights logic.
- `NEXT` Fix local Xcode environment so `xcodebuild` can run cleanly.
- `BLOCKED` `xcodebuild` is currently broken on this machine because Xcode cannot load `IDESimulatorFoundation` and suggests `xcodebuild -runFirstLaunch`.
- `NEXT` Run the full XCTest suite once `xcodebuild` is repaired.

## Current Priority Order

1. Repair local Xcode tooling so the real iOS build and tests can run.
2. Replace mock monetization with RevenueCat.
3. Implement account-backed sync and Sign in with Apple.
4. Strengthen the chat extraction and finance-memory flow.
5. Polish dashboard UI and add the missing non-Figma screens.
