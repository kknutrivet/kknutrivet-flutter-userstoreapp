# Customer Flutter app: UX, UI and web alignment review

Date: 25 October 2026
App: /Users/sarojpanigrahy/saroj/kknutrivet-flutter app
Web reference: /Users/sarojpanigrahy/saroj/kknutrivet-webapp

## Assessment

The foundation is useful: shared colours, reusable cards/buttons, Riverpod state, persistent navigation branches, product-image containment, loading components and extensive widget tests. The missing premium feel is primarily an information-hierarchy and consistency problem. Compact web layouts are often replicated literally instead of adapting the same brand and business behaviour to a touch-first app.

This review inventories 135 Dart files and 39 screen files, examines shared components, navigation and critical shopping/care flows, and compares local web source. It is a source review plus existing automated tests, not a visual acceptance run of all authenticated screens. Recommendations below are distinguished from confirmed code defects. No application implementation was changed in this pass. The directory is not currently a Git checkout; establish version control or a recoverable baseline before a broad redesign.

## Confirmed findings

### P1: Care-chat state is not aligned with the backend

Evidence: lib/providers/consultation_service.dart: fetchChatMessages returns only a list. lib/features/consultations/screens/consultation_detail_screen.dart: an eight-second timer refreshes messages only; the composer is rendered regardless of completed/read-only status. The local web messages route returns canMessage, hasMore, followUpRequested, videoCallEligible and videoCallAvailable.

Consequences: access and payment/readiness information is discarded; a completed case still presents a send action that the server can reject; historical messages have no paging controls; assignment/completion can stay stale until a full refresh. This looks like an unreliable product even when messages are stored correctly.

Required: a typed chat-page response, server-driven composer/video state, history pagination, lifecycle-aware polling, completed/follow-up state and pending-payment reconciliation. Validate prescription and video payments separately. Current UI routes several payment actions through the same booking-level callback; do not claim parity without testing the individual server contracts.

### P1: Prescription-to-shopping fallback is broken

Evidence: consultation_detail_screen.dart passes `/shop` when a prescription item has no product slug. app_router.dart declares `/products`, not `/shop`.

Required: valid catalogue fallback and a deliberate prescription shopping journey. Avoid sending users to a generic store when a prescription can supply a selected medicine list.

### P2: Best-seller navigation loses sorting intent

Evidence: home_product_rails.dart builds `/products?sort=popularity`; app_router.dart and ProductListScreen accept animal/category/search/disease, but no initial sort.

Required: parse the sort parameter, initialize the catalogue filter and preserve it through navigation.

### P2: Compact cards sacrifice legibility to fit fixed geometry

Evidence: compact_product_card.dart reduces catalogue titles to 11px on tight cards, badges to 8.5px, variant labels to 10px and crossed-out prices to 9–9.5px. It uses roughly 28–31px control height in tight layouts. Across lib, 162 explicit fontSize declarations fall in the 8–10.x range; this count includes secondary labels and is not 162 independent defects.

Required: use minimum readable sizes and allow card height to grow. Target names 14–15sp, supporting pack information 12–13sp, price 16–18sp. Keep interactive targets at least 48dp even if the visual button is smaller. Retain complete product-name access on the detail page.

### P2: Shared design tokens are underused and have drifted

Evidence: AppSpacing has seven references and AppTypography three references across lib, including definitions/delegation. Shared AppButton/AppCard exist, but many screens manually choose text sizes, corners and spacing. AppCard defaults to radius 16 while AppRadius.card is 14. AppButton's small variant allows 36dp height despite its comment promising 48dp targets.

Web `--color-bg` is #F3F6F5; Flutter background is #F8FAF8 and its parity test asserts that old value. Web default font tokens are system sans and an editorial serif; Flutter uses Plus Jakarta Sans for both body and the helper named `serif`. These may be intentional design choices, but the comments claiming 100% parity are inaccurate.

Required: decide one explicit shared brand specification, with documented mobile adaptations. Test the agreed specification rather than restating old constants. Standardize primary/secondary/quiet buttons, card surfaces, page gutters, section spacing and heading roles.

### P2: Font delivery needs a deterministic strategy

Evidence: theme sets fontFamily to PlusJakartaSans; typography helpers request GoogleFonts.plusJakartaSans; pubspec has no bundled font family declaration.

Risk: default TextStyle and helper-rendered text may depend on different font-loading paths, especially on cold/offline launch. This is a risk to verify, not a measured runtime failure.

Required: bundle the chosen licensed font files, use consistent theme registration and validate first launch offline. Alternatively use a deliberate native system-font strategy throughout.

### P2: Checkout repeats progress information

Evidence: CheckoutStepHeader renders CheckoutBreadcrumb and then the same Cart → Delivery → Confirmation progression again as text.

Required: one progress indicator, one primary action, explicit delivery/payment sections and a stable payable total. Do not change payment confirmation semantics for cosmetic simplification.

## Design recommendations

### Home hierarchy

HomeScreen renders animal rails interleaved with prescription, combos, best sellers, spotlight, concerns, trust, care-reach, reviews, seasonal promotion, articles, care-space, benefits, brands, help and a mobile footer. That is a long promotional landing page rather than a focused returning-customer dashboard.

Recommended opening sequence:
1. Location/delivery context and search.
2. Animal selection, retained across relevant discovery journeys.
3. One primary hero or care message.
4. Relevant products and one clear care entry point.
5. Continue shopping / recent order / active consultation when available.

Keep articles, trust content and secondary promotions lower down or behind discovery links. Preserve useful web content without making every section equally prominent. Do not remove sections without checking business priorities.

### Navigation and persistent chrome

Keep the shared Home / Shop / Consult / Health / Account structure. StatefulShellRoute already preserves branches. Review the combined space consumed by raised Consult, the floating cart bar and its 24px bottom gap, plus page-specific floating assistants. Use one contextual floating action per screen; cart should not dominate a care conversation. Respect safe areas, keyboard and reduced-motion settings. Animation should provide feedback, not compete with the task.

### Product system

Retain contained product images and a consistent image frame. The existing two-layer blurred backdrop should be profiled on a real lower-end Android device before changing it for performance; no frame-time claim is made here. Standardize card anatomy: image → name → pack → price → action. Use variants of one component contract rather than divergent hand-built cards.

Product detail should prioritize identity, animal suitability, pack/variant, price, availability, delivery estimate and Add to cart. Put longer descriptions, dosing references, FAQs and recommendations in progressively disclosed sections. Do not hide prescription requirements or change medical content.

### Visual system

Use quiet neutral surfaces, one primary green, a restrained warm accent and consistent semantic status colours. Use 16–20dp page gutters, a small spacing scale and two principal surface levels. Avoid arbitrary shadows/gradients, oversized decorative borders or shrinking text as a layout fix. Use shared skeleton/empty/error states with an explicit recovery action and no raw technical exception strings.

## Page-by-page target and acceptance checklist

These rows specify what each page should satisfy; they are not claims that every listed risk was reproduced.

| Screen | Review / target |
|---|---|
| splash | Short, deterministic initialization; offline and failed-auth recovery; no unnecessary delay. |
| onboarding | Skip/continue clear; preserve deep-link intent after onboarding. |
| login | One dominant sign-in action; readable OTP and validation; keyboard-safe layout; return to original task. |
| forgot password | Clear submitted/success/error states; consistent form styling. |
| main shell | Preserve tab state; stable labels; avoid stacked floating controls and excess bottom spacing. |
| home | Reduce equal-weight promotional sections; prioritize search, animal context and returning-user tasks. |
| product list | Readable two-column cards, filter count, persistent sorting, meaningful empty/reset state. |
| product detail | Clear variant/price/availability hierarchy, stable CTA and prescription requirement. |
| combo detail | Match product-detail structure; clear contents, quantities, bundle price and add behaviour. |
| search | Useful recent/suggested terms, loading/no-results distinction, no lost query on return. |
| wishlist | Same product cards and add/variant behaviour as catalogue. |
| cart | Clear quantity/variant edits, availability, removal undo where supported, transparent totals. |
| checkout | One progress indicator, keyboard-safe address forms, visible payable amount and payment recovery. |
| Cashfree checkout | Loading, cancel/back, error and pending reconciliation; never infer paid from browser closure alone. |
| addresses | Selected address clear; understandable serviceability; consistent edit/delete affordances. |
| address form | Inline validation, postal lookup feedback, keyboard-safe save; retain input after errors. |
| orders | Status hierarchy, useful empty state and continuity to details/tracking. |
| order detail | Clear timeline, courier/tracking, items/payment and next permitted action; no internal codes in customer copy. |
| consultations home | Existing active/latest case is obvious; New concern and Past consultations are distinct. |
| book consultation | Legacy slot route remains reachable; label it clearly or retire it if business flow is now chat-first. |
| consultation detail | Fix server-state/history/payment parity described above before cosmetic release. |
| prescriptions | Explain uploaded versus issued prescriptions, review status, unlock and medicine ordering. |
| Ask Dr Paw | Distinguish AI advice from human consultation; preserve conversation and clear escalation. |
| vet insights | Consistent content cards, empty state and return navigation. |
| diseases / health | Searchable health catalogue; consistent animal context and readable tiles. |
| disease detail | Scannable article hierarchy and clear next actions to products/care; preserve source content. |
| pet care | Reduce competing promotional cards; useful animal-specific tasks. |
| pets | Profile list and add action; empty state explains the benefit. |
| pet detail | Health/profile information hierarchy; clear edit and care links. |
| pet form | Field validation, units, date picker, keyboard-safe save and retained draft. |
| profile | Group purchases, pet care and support; reduce the feeling of an undifferentiated tools menu. |
| referral | Clear balance/reward eligibility, share state and history; no unsupported reward promises. |
| calculator | Units and assumptions visible, input validation, results readable at large text. |
| scan | Explain permission and purpose before camera access; recovery when permission is denied. |
| blog list | Consistent image ratios and title hierarchy; meaningful loading/empty/error states. |
| blog detail | Readable measure/line spacing, accessible links, predictable sharing/back. |
| help | Contact hierarchy, reliable handoff and concise support choices. |
| pincode check | Clear checking/serviceable/unavailable/error distinction; retain pincode context. |
| static information pages | Match current web policy content and readable typography; verify content versions separately. |

## Suggested implementation sequence

1. Correct care-chat metadata/history and broken shopping/sort navigation.
2. Establish the agreed web/mobile token contract and bundled typography; correct shared touch targets.
3. Refine product cards, catalogue, product detail, cart and checkout as one purchase journey.
4. Simplify home and persistent navigation without losing web functionality.
5. Apply the same components to consultation, account, orders, pets and content pages.
6. Capture reference screenshots and run acceptance tests at 320/360/390dp, large text, keyboard open, offline, slow network, guest and signed-in states.

Release acceptance should cover customer → admin → doctor handoffs and payment/dispatch state changes, not just isolated widgets. Web parity means matching product data, prices, eligibility, status, permissions and business outcomes; native layout and navigation can differ deliberately.

## Validation performed

- flutter analyze --no-pub: no issues found.
- flutter test --no-pub: 120 tests passed.
- Existing tests cover numerous card, route, home, cart and checkout behaviours. A few exercise enlarged text. No golden-image suite was found in the searched tests.
- Passing tests do not establish visual polish, live payment success, device performance or full authenticated journey parity.
- No live payments, customer messages, shipping bookings or production writes were made.

## Implementation follow-up

Implemented locally after review:

- Reworked compact product cards across catalogue, home rails, related products, health and wishlist surfaces. Names, packs, price and action have a clearer hierarchy; prescription badges and multi-pack selection remain. Shared grid height grows with text scale. Very tight externally imposed heights scroll card details rather than shrink text.
- Shared small buttons now provide 48dp height; cards use the common radius token. Default app background matches the current web token. Shared heading/body helpers use native system fonts to avoid runtime font-fetch dependence. This is a deliberate native-mobile adaptation, not a claim of identical serif typography.
- Secondary home content is progressively disclosed; care chats no longer compete with the floating cart bar. Checkout uses one progress indicator.
- Catalogue routes preserve sort parameters, prescription shopping uses a valid catalogue route, and the old unsubstantiated Best Sellers claim is replaced by New arrivals backed by newest-first ordering. The server does not provide a popularity ranking.
- Typed chat pages retain messaging permissions, completion/follow-up, paging and video eligibility. Read-only conversations retain history and offer follow-up requests. Older messages can be loaded; foreground refresh updates booking and chat state.
- Prescription unlock requests include the exact prescription-message ID. Video payments explicitly request VIDEO. Verification includes the merchant order and prescription/video context, and is attempted after closing the gateway as well as a normal return. No access is unlocked solely on WebView return.
- Regression tests cover these API contracts, read-only history and small-screen components. Existing pack-selection tests were updated to the intentionally larger card fixture; the background-token assertion now matches the web source.

Validation: 131 tests passed and flutter analyze reported no issues. The Android debug build targets https://test.kknutrivet.in. This does not constitute live payment/video acceptance or complete visual acceptance of all 39 screens on physical devices. No live customer messages or charges were made. The local widget screenshot harness uses Flutter test fonts and is not a production-design screenshot.

A pre-edit source backup is saved at /tmp/kknutrivet-customer-before-ux.tgz. The app folder remains outside Git; no commits, deployment or app-store publication were performed. The earlier page-by-page acceptance checklist still applies for physical-device and authenticated end-to-end testing.
