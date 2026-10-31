# Direction contract — Timi HTML demo

Scope: an interactive design proposal for the existing iPhone app, requested by the user. Operate mode. This is not an approved replacement for the SwiftUI design system. Do not modify Swift files or the root DESIGN_NOTES.md.

The user's explicitly pinned direction is Apple HIG / professional iOS. This overrides unrelated visual-world challengers from concept-seed (reference seed:991cd291b1f791b5). Code-led build. Prototype-first: a concrete, reviewable HTML result before asking the user to choose a direction.

Product: Vietnamese personal finance, VND, four top-level destinations, accounts, savings goals, transfers, loans, budget, reports, mock assistant. Demonstration records are synthetic and disclosed outside the phone, in Settings, and inside the assistant. Data remains in memory.

First viewport: iOS large title and quiet greeting, net worth and six-month context on the page itself, grouped month income/expense/budget; recent transactions below. Four destinations in the tab bar. Add is a toolbar action. No promotional card on Overview. Local Settings contains appearance exploration.

Visual signature: white inset data groups on a cool neutral background; open net-worth area; jade only on interactive controls and chart emphasis; aligned monetary columns; regular body, medium row titles, semibold values, bold large title. Muted spending rows, signed positive income; red reserved for errors/over-budget/deletion. Thin consistent SVG icons in this web prototype; use SF Symbols in native implementation.

Alternative accents (blue / graphite) change only tint, keeping the information hierarchy constant. Dark is an optional demonstration, not a change to the app's current light-only requirement.

Targets: actual browser viewport, desktop 1280×900, iPhone 390×844, narrow phone 320×740. Primary controls 44px or larger; text and icons maintain contrast; sheet has labeled Cancel/Save, focus trap and Escape; Reduce Motion supported. HTML cannot certify native HIG conformance, safe-area behavior on hardware, VoiceOver or Dynamic Type. These require a SwiftUI implementation and device verification.

Sources checked 2026-10-30:
- https://developer.apple.com/design/human-interface-guidelines/typography
- https://developer.apple.com/design/human-interface-guidelines/layout
- https://developer.apple.com/design/human-interface-guidelines/color
- https://developer.apple.com/design/human-interface-guidelines/materials
- https://developer.apple.com/design/human-interface-guidelines/tab-bars
- https://developer.apple.com/design/human-interface-guidelines/accessibility

The Apple Markdown versions were read directly after the web reader could not render text/markdown. Current-app visual evidence: /tmp/timi-current-20261030.png (Simulator, scrolled Overview). Current type/color/layout tokens also read in source.

Detector run once on HTML/CSS/JS. Findings: reduced opacity on presentation-side nav indices, muted presentation notes, and 11px captions. Increased nav index opacity and presentation-note contrast. Eleven-pixel labels remain only for compact chart/tab/status metadata consistent with the iOS concept; ordinary row titles use 17px. No decorative textures, image claims or external fonts.
