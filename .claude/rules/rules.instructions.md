---
description: remember these rules when implementing the new meal selector UI
paths:
. - "src/**/*.ts"
---

<!-- Tip: Use /create-instructions in chat to generate content with agent assistance -->
RULE 1:
DO NOT rewrite backend/business logic unless absolutely required.

RULE 2:
UI must adapt to the backend — not vice versa.

RULE 3:
DO NOT break existing provider flows.

RULE 4:
DO NOT remove persistence integrations.

RULE 5:
DO NOT change MealSelectorService scoring logic.

RULE 6:
Preserve:
- hydration system
- fasting system
- gamification system
- notification system

RULE 7:
Every phase must remain production-safe.

RULE 8:
Use existing:
- Provider architecture
- ThemeProvider
- GoogleFonts.outfit
- flutter_animate
- existing design language

RULE 9:
Every new UI component must support:
- dark mode
- small devices
- animation
- responsive layouts

RULE 10:
DO NOT implement all phases at once.
STOP after each phase.