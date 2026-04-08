# MoneyGoWhere — Branding & Design System

> Reference: `references/duolingo/` (27 screens)
>
> Design direction: copy Duolingo's energy, hierarchy, and component language — swap the subject matter from language learning to personal finance. Same dark-first aesthetic, same bold rounded feel, same gamification patterns.

---

## 1. Colour Palette

### Core Tokens

| Token | Hex | Usage |
|---|---|---|
| `brand-green` | `#58CC02` | Primary CTA buttons, active states, progress bars, wordmark accent |
| `brand-green-dark` | `#46A302` | Button pressed state, green shadow/depth |
| `bg-base` | `#1A1A1F` | Screen background (neutral dark charcoal, matches previous_backup.png) |
| `bg-surface` | `#252528` | Cards, list rows, input fields |
| `bg-surface-raised` | `#2E2E33` | Elevated cards, modal backgrounds |
| `accent-blue` | `#1CB0F6` | Selected row border, interactive highlights, links, checkmarks |
| `accent-orange` | `#FF9600` | Streak counters, warnings, overdue indicators |
| `accent-purple` | `#7B5CF5` | Premium/paywall gradient start |
| `accent-purple-deep` | `#4B2D9F` | Premium/paywall gradient end |
| `text-primary` | `#FFFFFF` | All primary body and heading text |
| `text-secondary` | `#AFAFAF` | Subtitles, helper text, inactive labels |
| `text-green` | `#58CC02` | Highlighted values, positive amounts, selected text |
| `text-orange` | `#FF9600` | Streak numbers, overdue amounts |
| `separator` | `#2B3447` | Row dividers, subtle borders |
| `destructive` | `#FF4B4B` | Delete actions, negative balance |

### Gradients

```
Premium background:   linear-gradient(180deg, #4B2D9F 0%, #1B1B3A 100%)
Premium badge glow:   linear-gradient(90deg, #58CC02, #A3E635)   /* neon green pill */
Paywall hero:         radial-gradient(ellipse, #7B5CF5 0%, #131C2E 70%)
```

### Semantic Colour Mapping (Finance Context)

| Duolingo concept | MoneyGoWhere equivalent | Colour |
|---|---|---|
| Streak flame | Savings streak / on-track month | `accent-orange` |
| XP / points | Net cashflow surplus | `brand-green` |
| Hearts lost | Budget overspend | `destructive` |
| Super premium | MoneyGoWhere Pro | `accent-purple` → gradient |
| Progress bar | Month budget consumed | `brand-green` on `bg-surface` |

---

## 2. Typography

Duolingo uses a custom rounded, heavy sans-serif. Mirror this with:

- **Primary font**: SF Pro Rounded (iOS system font rounded variant) — activate via `.fontDesign(.rounded)` in SwiftUI
- **Fallback**: SF Pro Display for large display sizes

### Type Scale

| Role | Size | Weight | Case | Colour |
|---|---|---|---|---|
| `hero-title` | 32–40pt | Black (900) | Title | `text-primary` |
| `screen-title` | 22–24pt | Bold (700) | Title | `text-primary` |
| `section-header` | 13pt | Semibold (600) | UPPERCASE | `text-secondary` |
| `body` | 17pt | Regular | Sentence | `text-primary` |
| `body-bold` | 17pt | Bold | Sentence | `text-primary` |
| `caption` | 13pt | Regular | Sentence | `text-secondary` |
| `button-label` | 15–17pt | ExtraBold (800) | UPPERCASE | `text-primary` or `bg-base` |
| `amount-large` | 36–48pt | Black (900) | — | `text-green` or `text-primary` |
| `amount-small` | 17pt | Bold | — | `text-green` or `destructive` |

### Key Rules

- **Wordmark**: lowercase "moneygowhere" in `brand-green`, rounded weight
- **Highlight inline values** by swapping their colour to `text-green` or `text-orange` while keeping surrounding text in `text-primary` (Duolingo pattern: "That's **25 words** in your first week!")
- **Button labels are always UPPERCASE** and extra-bold — no exceptions
- **Never use a system default font weight** for any visible heading or CTA

---

## 3. Iconography & Imagery

### Mascot

Duolingo's Duo owl provides personality at every step. MoneyGoWhere should have a mascot or expressive mark — a coin, wallet, or simplified character — that:

- Appears on splash, onboarding steps, empty states, and celebration moments
- Changes expression/pose to match context (curious, excited, celebrating, reminding)
- Uses a speech bubble pattern for tip/nudge copy (see duolingo3–13)

Until a full mascot is designed, use SF Symbols with `brand-green` tinting and a consistent rounded container style as a placeholder.

### App Icon

- Background: `brand-green` (#58CC02), full bleed
- Foreground: white simplified mark (coin with arrow, or wallet icon)
- Shape: rounded square (iOS standard)
- Reference: duolingo1 — pure green, centred, nothing else

### SF Symbols usage

All icons use `.fontDesign(.rounded)` and are tinted:
- Active / selected: `brand-green` or `accent-blue`
- Inactive: `text-secondary`
- Destructive: `destructive`
- Premium: `accent-purple`

---

## 4. Component Library

### 4.1 Primary CTA Button

**Reference**: Every screen — green full-width button at the bottom

```
Background:  brand-green (#58CC02)
Bottom shadow: brand-green-dark (#46A302), offset 0 4px
Corner radius: 16pt
Height: 52pt
Label: UPPERCASE, ExtraBold, 17pt, text-primary
Full width (horizontal padding 16pt from edges)
```

States:
- Default: `brand-green` fill
- Pressed: `brand-green-dark`, scale 0.97
- Disabled: `brand-green` at 40% opacity

### 4.2 Secondary / Ghost Button

**Reference**: duolingo2 "I ALREADY HAVE AN ACCOUNT", duolingo14 "NOT NOW"

```
Background:  transparent
Border:      1.5pt separator (#2B3447) — or no border for text-only links
Corner radius: 16pt
Height: 52pt
Label: UPPERCASE, ExtraBold, 17pt, text-secondary (or accent-blue for links)
```

### 4.3 List Selection Row

**Reference**: duolingo5, 7, 8, 9, 11 — the core onboarding and quiz rows

```
Background:     bg-surface (#1F2937)
Corner radius:  12pt
Height:         56pt
Padding:        16pt horizontal
Border:         none by default, 2pt accent-blue when selected
Leading icon:   emoji or SF Symbol in 28pt rounded container
Trailing:       nothing (default) or secondary label (right-aligned, text-secondary)

Selected state:
  - Border: 2pt accent-blue
  - Label colour: accent-blue (text changes colour, matching Duolingo)
```

### 4.4 Progress Bar

**Reference**: Top of all onboarding screens (duolingo5–18)

```
Track:          bg-surface-raised, height 8pt, fully rounded
Fill:           brand-green, animated width
Corner radius:  4pt (pill)
Placement:      below navigation bar, full width with 16pt inset
```

For month budget progress in dashboard — same style, replace green with a `destructive` fill when >90% consumed.

### 4.5 Mascot Chat / Tip Bubble

**Reference**: duolingo3, 4, 7, 8, 10, 12, 13, 17, 18 — Duo + speech bubble

```
Layout:    HStack — avatar (40pt rounded square) + speech bubble
Bubble bg: bg-surface-raised (#2B3447)
Bubble corner radius: 16pt, with tail pointing left toward avatar
Text:      body (17pt) regular, text-primary
Bold inline: highlight key numbers/words in text-green
```

Apply to: onboarding steps, empty states, first-run hints, contextual tips in chat.

### 4.6 Card / Surface Container

```
Background:     bg-surface (#1F2937)
Corner radius:  16pt
Padding:        16pt
Shadow:         none (flat dark UI — Duolingo avoids drop shadows on dark bg)
Separator:      1pt separator between stacked rows inside card
```

### 4.7 Input Field

**Reference**: duolingo21–24 (name, email, age, password fields)

```
Background:   bg-surface (#252528)
Corner radius: 12pt
Height:        52pt (padding: 14pt vertical, 16pt horizontal)
Border:        none default; 2pt accent-blue when focused; 2pt brand-green when valid
Trailing icon: brand-green checkmark (SF: checkmark.circle.fill) on valid input
Text:          body 17pt regular rounded, text-primary (white)
Placeholder:   white @ 45% opacity (Color.white.opacity(0.45)) on dark surfaces
Tap target:    TextField uses frame(maxWidth: .infinity) + contentShape(Rectangle())
               so the full padded row activates focus, not just the text
```

> **Dark-theme note:** Dark inputs use semi-transparent white instead of `text-secondary` (#AFAFAF) for legibility on `bg-surface` (#252528). Use `text-secondary` for placeholders only on lighter surfaces if introduced in future.

### 4.7a Dropdown / Menu Field

Use SwiftUI `Menu` (not `Picker(.menu)`) so the entire surface is tappable.

```
Background:    bg-surface (#252528)
Corner radius: 12pt
Padding:       14pt vertical, 16pt horizontal
Label text:    brand-green, 17pt regular rounded (shows current selection)
Chevron icon:  SF: chevron.up.chevron.down, brand-green, 13pt medium
Tap target:    full row — Menu label fills maxWidth so any tap opens the dropdown
```

### 4.7b Draft Review Card

Displayed in Chat when the assistant has extracted a recurring item for confirmation.

```
Container:     bg-surface, corner radius 18pt, padding 18pt
Header text:   "Ready to save"  → brand-green, 15pt semibold rounded
               "Waiting on more detail" → white, same weight
Row label:     white, 14pt medium rounded  (Title / Amount / Cadence / Next due / Type)
Row value:     text-secondary (#AFAFAF), 14pt regular rounded, trailing-aligned
Confirm CTA:   borderedProminent, brand-green tint — disabled until readyForConfirmation
Edit CTA:      bordered, text-secondary tint
```

### 4.8 Streak / Gamification Row

**Reference**: duolingo19 — streak screen with day dots

```
Streak number: amount-large, accent-orange
Label:         "day streak" — body, text-secondary
Week dots:     7 circles, 28pt, bg-surface; completed = brand-green with white checkmark
Flame icon:    SF: flame.fill, accent-orange
```

Apply to: monthly check-in summary, savings goals, on-time payment streaks.

### 4.9 Badge / Pill Label

**Reference**: duolingo18 "RECOMMENDED", duolingo25/27 "MOST POPULAR" / "SUPER"

```
Small badge:
  Background: accent-blue
  Text: UPPERCASE, 11pt, ExtraBold, text-primary
  Corner radius: 6pt
  Padding: 4pt horizontal, 2pt vertical

Premium badge:
  Background: linear-gradient(brand-green, #A3E635)
  Text: "PRO", UPPERCASE, ExtraBold, text-primary (or bg-base for contrast)
```

### 4.10 Paywall / Premium Screen

**Reference**: duolingo25, 26, 27

```
Background:       Premium gradient (see Gradients above)
Mascot:           expressive premium variant, centered
Headline:         screen-title, text-primary, centred
Key stat accent:  inline text-green or accent-orange
Feature table:    bg-surface rows, check SF symbol (brand-green) vs dash (text-secondary)
Primary CTA:      white button (bg: #FFFFFF, text: bg-base) — reversal of normal pattern
Secondary CTA:    text-only link, text-secondary, UPPERCASE
Plan selector:    card rows with MOST POPULAR pill badge, selected = accent-blue border
```

### 4.11 Navigation Bar

```
Background:    bg-base (transparent / blurred on scroll)
Title:         screen-title, text-primary
Back button:   chevron.left SF symbol, text-primary, no container
No visible border/separator by default
```

### 4.12 Tab Bar

```
Background:    bg-surface (#1F2937) with hairline top separator
Active icon:   brand-green, filled SF symbol
Active label:  brand-green, 10pt semibold
Inactive:      text-secondary, outlined SF symbol
Height:        83pt (includes safe area)
```

---

## 5. Motion & Interaction

Duolingo uses micro-animations pervasively — button bounces, mascot reactions, progress fills, celebration bursts.

- **Button tap**: scale(0.97) + haptic, spring back 0.15s
- **Row selection**: border colour animates in 0.15s ease
- **Progress bar fill**: animated over 0.4s ease-out on screen appear
- **Celebration / completion**: confetti or particle burst using `TimelineView` + `Canvas`
- **Mascot expression change**: crossfade 0.2s between poses
- **Screen transitions**: slide from right (push), slide down (modal dismiss)
- **Reduced motion**: all animations collapse to instant opacity crossfades when `accessibilityReduceMotion` is enabled
- **Onboarding back button**: top-left of screen beside the progress bar — not below the CTA. Visible from step 1 onwards. Uses `chevron.left` SF Symbol, `text-secondary` colour, 28×28pt tap target. Sets `goingForward = false` before animating `stepIndex -= 1`.
- **Onboarding page transition**: `.asymmetric` slide — advancing slides new step in from trailing edge, removes old step to leading edge; going back reverses directions. Duration 0.3s `easeInOut`. Implemented via `.id(stepIndex)` on the step container so SwiftUI replaces the view tree and fires `.transition(...)`.
- **Onboarding intro fade-in**: Step 0 fades in from opacity 0 → 1 over 0.5s `easeIn` on first `.onAppear`. Re-triggers when navigating back to step 0, giving a soft re-entry feel.

---

## 6. Voice & Copy Tone

Duolingo's copy is:
- Short, direct, warm
- Uses the mascot's first person ("I'll remind you…", "Here's what you can achieve")
- Celebrates small wins enthusiastically
- Never condescending about failure

MoneyGoWhere equivalent:
- Chat assistant speaks first-person, warm and encouraging ("You're on track this month!")
- Empty states use mascot speech-bubble copy, not system-style placeholder text
- CTA labels are action-forward, not passive ("ADD ITEM" not "Add New Item")
- Numbers are celebrated inline ("That saves you **$42** this month")
- Avoid finance-industry coldness — no "insufficient funds", use "You're a bit short this month"

---

## 7. Dark Mode First

All screens are dark-first (matching Duolingo's dark UI). Light mode is not a v1 target.

If light mode is added later, invert the bg tokens only — green, blue, and orange brand colours remain the same.

---

## 8. Reference Image Index

| File | Screen | Key patterns shown |
|---|---|---|
| duolingo1 | Splash | Full-bleed brand green, mascot centred, wordmark |
| duolingo2 | Welcome / landing | Dark bg, green CTA + ghost secondary button |
| duolingo3–4 | Mascot intro | Mascot + speech bubble pattern |
| duolingo5 | List selection | Row selection with icon, selected = blue border |
| duolingo7–9 | Question screens | List rows, progress bar, avatar in corner |
| duolingo11 | Goal selection | Selected row styling, "I'M COMMITTED" CTA |
| duolingo14 | Widget promo | "ADD WIDGET" primary + "NOT NOW" text-link |
| duolingo17 | Achievement list | Icon + title + subtitle rows, no selection |
| duolingo18 | Start options | "RECOMMENDED" badge, two-option card rows |
| duolingo19 | Streak screen | Streak number, orange flame, week dot row |
| duolingo21 | Age input | Input field, green CTA, social sign-in rows |
| duolingo22–24 | Form fields | Focused/valid input states |
| duolingo25 | Paywall table | Premium gradient bg, FREE vs SUPER feature table |
| duolingo26 | Trial screen | Purple gradient, trial reminder pattern |
| duolingo27 | Plan picker | MOST POPULAR badge, plan selector cards, white CTA |
