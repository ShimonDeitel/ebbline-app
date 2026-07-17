# Ebbline — Freelance Cash Flow

## Concept
A live "safe-to-spend-today" number for freelancers and gig workers with irregular
income. Unlike a budgeting app that projects a fixed monthly plan, Ebbline only
counts money that has actually arrived — income the user has manually logged as
received — against bills that are due, so the number on screen is always true,
never aspirational.

## Problem
Freelance and gig income doesn't land on a schedule. Traditional budget apps
assume a steady monthly paycheck and quietly overstate what's safe to spend
before the next invoice clears. Freelancers end up either underspending out of
anxiety or overspending because the app's "monthly budget" said they were fine.

## Evidence
Direct pattern match to the brief: freelancers/gig workers manage cash flow in
spreadsheets or by mental math ("did that client actually pay me yet?") because
every mainstream personal-finance app (Mint, YNAB, Copilot) is built around
recurring paychecks and bank-linked balances, not manually-confirmed, irregular
receipts.

## Free tier
- Track one income stream (one distinct income source name) + unlimited bills,
  entered manually.
- See the safe-to-spend number: a simple ledger — income actually received
  minus bills already due — clamped at zero.
- The draggable float-line timeline is visible and playable as a teaser of the
  bill-aware recalculation, gated behind Pro for the live recalculated number.

## Pro — $4.99/month (auto-renewable subscription, com.shimondeitel.ebbline.pro.monthly)
- Multiple income streams (unlimited distinct sources).
- AI shortfall forecaster: plain-English warning citing the specific date and
  amount of a projected shortfall, generated from recent income + upcoming
  bills.
- Bill-aware recalculation: the safe-to-spend number reserves for bills due
  before the next expected payment, not just bills already past due — this is
  what powers the live float-line drag simulation.

## Quirky feature — the float line
A draggable marker on a horizontal timeline representing "when does the next
expected payment actually land." Dragging it further out simulates "what if
this payment arrives late" — and the safe-to-spend number recalculates live,
continuously, *while dragging*, before the user releases their finger. It
turns the anxious mental math freelancers already do ("if that check is late,
am I still okay?") into a physical, interactive gesture.

## Animation hook — the tide gauge
Every time income or a bill is logged, the safe-to-spend figure doesn't just
update a label — a ribbon of liquid teal visibly rises or recedes across a
vertical tide-gauge meter. The fill's top edge is a real wave (a custom
`Shape`, not a flat rectangle), animated with `withAnimation` over ~0.8s, with
a continuous idle ripple driven by `TimelineView`, and a soft radial ripple
pulse at the fill line whenever the value changes.

## AI feature (Pro only, text)
POSTs recent income events and known upcoming bills (dates + amounts) to
`https://apps-ai-proxy.s0533495227.workers.dev/text` and asks the model for a
specific plain-English shortfall warning — citing the exact date and amount —
if the safe-to-spend trajectory goes negative before the next expected income.
No shortfall detected -> a reassuring plain-English confirmation instead.

## Design direction
- Palette: aqua-to-teal gradient (deep teal `#0B4F5C` to bright aqua
  `#2FD3C7`, foam highlight `#BFF3EA`), with a coral `#FF7A59` reserved
  strictly for shortfall/warning states.
- Glassy translucent panels: `.ultraThinMaterial` with a teal tint overlay.
- Every divider and progress element is a soft curved wave (`WaveShape`,
  `WaveDivider`) — never a straight `Rectangle`/`Divider`.
- Numerals are bold, `.monospacedDigit()`, ticker-tape style, for the
  safe-to-spend figure and every dollar amount.

## Monetization
Auto-renewable monthly subscription, StoreKit 2, product id
`com.shimondeitel.ebbline.pro.monthly`, $4.99/month. Entitlement derived live
from `Transaction.currentEntitlements` — never persisted as a trusted flag.
